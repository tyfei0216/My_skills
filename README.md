# Codex Skills

This repository keeps personal Codex skills synchronized across machines. Each
top-level directory containing a `SKILL.md` file is treated as one installable
skill.

## Repository layout

```text
codex-skills/
|-- skill-creator/
|   `-- SKILL.md
|-- another-skill/
|   `-- SKILL.md
`-- sync-skills.ps1
```

## Set up another Windows machine

Clone this repository, then run:

```powershell
.\sync-skills.ps1
```

By default, skills are copied to `$env:CODEX_HOME\skills`. If `CODEX_HOME` is
not set, the script uses `$env:USERPROFILE\.codex\skills`.

Existing skill directories are skipped to protect local changes. To update
them from this repository, run:

```powershell
.\sync-skills.ps1 -Force
```

Restart Codex after adding or updating skills so they are discovered.

## Everyday workflow

1. Add or edit a top-level skill directory in this repository.
2. Validate the skill with its `quick_validate.py` script when one is present.
3. Commit and push the changes.
4. On another machine, pull and run `sync-skills.ps1 -Force`.

Do not commit credentials, API keys, `.env` files, or machine-specific data.
