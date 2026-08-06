---
name: initialize-project-folder
description: Initialize a structured Python project folder and Git repository with reusable source packages, session tracking, demonstration and working notebooks, scripts, and figure artifacts. Use when creating a new research, data-science, machine-learning, or Python repository; when asked to scaffold a project workspace; or when an existing empty or partial project needs the standard src, log, notebook, working, script, and figure layout.
---

# Initialize Project Folder

Create a consistent Python project workspace without overwriting unrelated project files.

## Workflow

1. Resolve the requested project directory. Use the current directory only when the user clearly requests it.
2. Inspect the directory before changing it. Preserve existing files and user changes.
3. Run the bundled initializer:

```powershell
python <skill-dir>/scripts/initialize_project_folder.py <project-directory>
```

4. Inspect the resulting tree and run `git status --short --branch` in the project.
5. Report the created and skipped files. Tell the user when Git was not initialized.

Use `--project-name "Display Name"` when the session title should differ from the folder name. Use `--dry-run` to preview changes, `--no-git` when the user explicitly does not want a Git repository, and `--force` only when the user explicitly authorizes replacement of this skill's managed template files.

## Project Layout

Create this structure:

```text
project/
|-- src/
|   |-- __init__.py
|   |-- utils/
|   |   `-- __init__.py
|   `-- models/
|       `-- __init__.py
|-- log/
|   `-- SESSION.md
|-- notebook/
|   `-- .gitkeep
|-- working/
|   `-- .gitkeep
|-- script/
|   `-- .gitkeep
|-- figure/
|   `-- .gitkeep
`-- .gitignore
```

Use each directory consistently:

- `src/`: reusable Python source code shared across the project.
- `src/utils/`: reusable utilities, data helpers, and common functions.
- `src/models/`: reusable model definitions and model-related code.
- `log/`: progress records and the session handoff file.
- `notebook/`: clean demonstration notebooks intended for other readers.
- `working/`: exploratory, testing, and temporary working notebooks.
- `script/`: reusable command-line or automation scripts.
- `figure/`: figure-drawing notebooks and generated figure files.

## Session Management

Initialize `log/SESSION.md` from `assets/SESSION.md.template`. Keep it compatible with a phase-based Implementation -> Verification -> Debugging workflow. Record a concrete next action and update the checkpoint after meaningful Git commits.

When the `project-session-management` skill is available, use it for subsequent session wrap-up and resume operations. Do not create a second session file elsewhere unless the user requests one.

## Safety

- Add missing structure to partial projects instead of requiring an empty directory.
- Never delete project files.
- Skip existing managed files by default.
- Treat `--force` as permission to replace only `.gitignore`, Python package markers, `.gitkeep` files, and `log/SESSION.md`.
- Do not install packages, create environments, or add framework-specific configuration unless separately requested.
- Do not create the first Git commit automatically.
