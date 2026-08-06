# Codex Skills

This repository keeps personal Codex skills synchronized across machines. Each
top-level directory containing a `SKILL.md` file is treated as one installable
skill.

Managed skills:

| Skill | Source | Purpose |
| --- | --- | --- |
| `initialize-project-folder` | Local | Standard Python project repository scaffolding |
| `nature-figure` | `Yuan1z0825/nature-skills` | Nature-style publication figures |
| `scientific-visualization` | `davila7/claude-code-templates` | Python publication plots and export guidance |
| `jupyter-notebook` | `openai/skills` | Reproducible notebook creation and maintenance |
| `project-session-management` | `jezweb/claude-skills` (`v1-final`) | Persistent `SESSION.md` handoffs and checkpoints |
| `drawio-skill` | `Agents365-ai/drawio-skill` | Editable pipeline and architecture illustrations |

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

## Update upstream skills

The tracked sources and paths live in `skill-sources.json`. Refresh all managed
upstream skills with:

```powershell
.\update-upstream-skills.ps1
```

Refresh only selected skills with:

```powershell
.\update-upstream-skills.ps1 -Name nature-figure,drawio-skill
```

The updater refuses to overwrite uncommitted changes inside a managed skill.
Use `-Force` only when those local edits should be discarded, then review the
result with `git diff` before committing.

GitHub Actions checks upstream every Monday and opens or updates a pull request
when files change. In the GitHub repository settings, allow Actions to create
pull requests under **Actions > General > Workflow permissions**.

`project-session-management` is pinned to the author's archived `v1-final` tag
because it is no longer present on the repository's current `main` branch.

## Everyday workflow

1. Add or edit a top-level skill directory in this repository.
2. Validate the skill with its `quick_validate.py` script when one is present.
3. Commit and push the changes.
4. On another machine, pull and run `sync-skills.ps1 -Force`.

Do not commit credentials, API keys, `.env` files, or machine-specific data.
