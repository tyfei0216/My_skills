[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot

if ($env:CODEX_HOME) {
    $skillsRoot = Join-Path $env:CODEX_HOME "skills"
} else {
    $skillsRoot = Join-Path $env:USERPROFILE ".codex\skills"
}

New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null

$skills = Get-ChildItem -LiteralPath $repoRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md")
}

if (-not $skills) {
    Write-Host "No top-level skill directories were found in $repoRoot"
    exit 0
}

foreach ($skill in $skills) {
    $destination = Join-Path $skillsRoot $skill.Name

    if ((Test-Path -LiteralPath $destination) -and -not $Force) {
        Write-Warning "Skipping $($skill.Name): destination already exists. Use -Force to update it."
        continue
    }

    if ($PSCmdlet.ShouldProcess($destination, "Copy skill $($skill.Name)")) {
        if (Test-Path -LiteralPath $destination) {
            Get-ChildItem -LiteralPath $skill.FullName -Force | Copy-Item `
                -Destination $destination -Recurse -Force
        } else {
            Copy-Item -LiteralPath $skill.FullName -Destination $destination -Recurse
        }

        Write-Host "Installed $($skill.Name) to $destination"
    }
}
