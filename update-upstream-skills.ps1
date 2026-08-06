[CmdletBinding()]
param(
    [string[]]$Name,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$manifestPath = Join-Path $repoRoot "skill-sources.json"
$skillCreatorPath = Join-Path $repoRoot "skill-creator"
$validatorPath = Join-Path (Join-Path $skillCreatorPath "scripts") "quick_validate.py"
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$tempRoot = Join-Path $repoRoot (".upstream-tmp-" + [guid]::NewGuid().ToString("N"))
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Assert-LastCommand {
    param([string]$Action)

    if ($LASTEXITCODE -ne 0) {
        throw "$Action failed with exit code $LASTEXITCODE."
    }
}

function Remove-FrontmatterKeys {
    param(
        [string]$SkillDirectory,
        [object[]]$Keys
    )

    if (-not $Keys -or $Keys.Count -eq 0) {
        return
    }

    $skillFile = Join-Path $SkillDirectory "SKILL.md"
    $lines = [System.IO.File]::ReadAllLines($skillFile, $utf8NoBom)
    if ($lines.Count -lt 3 -or $lines[0] -ne "---") {
        throw "Cannot normalize frontmatter in $skillFile."
    }

    $frontmatterEnd = [Array]::IndexOf($lines, "---", 1)
    if ($frontmatterEnd -lt 0) {
        throw "Cannot find the closing frontmatter marker in $skillFile."
    }

    $filtered = for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        if ($index -gt 0 -and $index -lt $frontmatterEnd -and
            $line -match '^([A-Za-z0-9_-]+):' -and
            $Keys -contains $Matches[1]) {
            continue
        }
        $line
    }

    [System.IO.File]::WriteAllLines($skillFile, $filtered, $utf8NoBom)
}

function Expand-SkillArchive {
    param(
        [string]$ArchivePath,
        [string]$SkillPath,
        [string]$Destination
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)

    try {
        $normalizedSkillPath = $SkillPath.Trim('/')
        $pathMarker = "/$normalizedSkillPath/"
        $sampleEntry = $archive.Entries | Where-Object {
            $_.FullName.Contains($pathMarker)
        } | Select-Object -First 1

        if (-not $sampleEntry) {
            throw "Cannot find $SkillPath in the downloaded archive."
        }

        $rootLength = $sampleEntry.FullName.IndexOf('/') + 1
        $archivePrefix = $sampleEntry.FullName.Substring(0, $rootLength) +
            $normalizedSkillPath + "/"
        $destinationRoot = [System.IO.Path]::GetFullPath($Destination) +
            [System.IO.Path]::DirectorySeparatorChar
        New-Item -ItemType Directory -Path $Destination | Out-Null

        foreach ($entry in $archive.Entries) {
            if (-not $entry.FullName.StartsWith($archivePrefix,
                    [System.StringComparison]::Ordinal)) {
                continue
            }

            $relativePath = $entry.FullName.Substring($archivePrefix.Length)
            if (-not $relativePath) {
                continue
            }

            $localRelativePath = $relativePath.Replace('/',
                [System.IO.Path]::DirectorySeparatorChar)
            $targetPath = [System.IO.Path]::GetFullPath(
                (Join-Path $Destination $localRelativePath))
            if (-not $targetPath.StartsWith($destinationRoot,
                    [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Archive entry escapes the destination: $($entry.FullName)"
            }

            if ($entry.FullName.EndsWith('/')) {
                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
                continue
            }

            $parentPath = Split-Path -Parent $targetPath
            New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile(
                $entry, $targetPath, $true)
        }
    } finally {
        $archive.Dispose()
    }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git is required to update upstream skills."
}

$selectedSkills = @($manifest.skills | Where-Object {
    -not $Name -or $Name -contains $_.name
})

if ($Name) {
    $unknownNames = @($Name | Where-Object { $_ -notin $manifest.skills.name })
    if ($unknownNames.Count -gt 0) {
        throw "Unknown skill name(s): $($unknownNames -join ', ')"
    }
}

New-Item -ItemType Directory -Path $tempRoot | Out-Null

try {
    foreach ($skill in $selectedSkills) {
        $dirty = & git -C $repoRoot status --porcelain -- $skill.name
        Assert-LastCommand "Checking $($skill.name)"
        if ($dirty -and -not $Force) {
            throw "$($skill.name) has uncommitted changes. Commit them or rerun with -Force."
        }

        Write-Host "Updating $($skill.name) from $($skill.repository)@$($skill.ref)..."
        $archivePath = Join-Path $tempRoot ($skill.name + ".zip")
        $archiveUrl = "https://codeload.github.com/$($skill.repository)/zip/$($skill.ref)"
        Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath `
            -Headers @{ "User-Agent" = "codex-skill-updater" }
        $candidatePath = Join-Path $tempRoot ("candidate-" + $skill.name)
        Expand-SkillArchive -ArchivePath $archivePath -SkillPath $skill.path `
            -Destination $candidatePath
        if (-not (Test-Path -LiteralPath (Join-Path $candidatePath "SKILL.md"))) {
            throw "Upstream package $($skill.name) does not contain SKILL.md."
        }

        Remove-FrontmatterKeys -SkillDirectory $candidatePath `
            -Keys $skill.remove_frontmatter_keys

        if ((Test-Path -LiteralPath $validatorPath) -and
            (Get-Command python -ErrorAction SilentlyContinue)) {
            & python -X utf8 $validatorPath $candidatePath
            Assert-LastCommand "Validating $($skill.name)"
        }

        $destinationPath = Join-Path $repoRoot $skill.name
        $backupPath = Join-Path $tempRoot ("backup-" + $skill.name)

        if (Test-Path -LiteralPath $destinationPath) {
            Move-Item -LiteralPath $destinationPath -Destination $backupPath
        }

        try {
            Copy-Item -LiteralPath $candidatePath -Destination $destinationPath -Recurse
        } catch {
            if (Test-Path -LiteralPath $destinationPath) {
                Remove-Item -LiteralPath $destinationPath -Recurse -Force
            }
            if (Test-Path -LiteralPath $backupPath) {
                Move-Item -LiteralPath $backupPath -Destination $destinationPath
            }
            throw
        }

        if (Test-Path -LiteralPath $backupPath) {
            Remove-Item -LiteralPath $backupPath -Recurse -Force
        }

        Write-Host "Updated $($skill.name)."
    }
} finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

Write-Host "Review the changes with: git diff --stat"
