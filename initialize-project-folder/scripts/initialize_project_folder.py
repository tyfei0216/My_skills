#!/usr/bin/env python3
"""Initialize a repeatable Python project folder without deleting user files."""

from __future__ import annotations

import argparse
import shutil
import subprocess
from datetime import date
from pathlib import Path


DIRECTORIES = (
    "src/utils",
    "src/models",
    "log",
    "notebook",
    "working",
    "script",
    "figure",
)

EMPTY_FILES = (
    "src/__init__.py",
    "src/utils/__init__.py",
    "src/models/__init__.py",
    "notebook/.gitkeep",
    "working/.gitkeep",
    "script/.gitkeep",
    "figure/.gitkeep",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create the standard Python project structure and initialize Git."
    )
    parser.add_argument("project_directory", help="Directory to initialize.")
    parser.add_argument(
        "--project-name",
        help="Display name written to log/SESSION.md; defaults to the folder name.",
    )
    parser.add_argument(
        "--no-git",
        action="store_true",
        help="Create the folder structure without initializing Git.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Replace files managed by this initializer; never deletes other files.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the planned operations without changing the filesystem.",
    )
    return parser.parse_args()


def report(action: str, path: Path) -> None:
    print(f"{action:<8} {path}")


def ensure_directory(path: Path, dry_run: bool) -> None:
    if path.exists():
        if not path.is_dir():
            raise RuntimeError(f"Expected a directory but found a file: {path}")
        report("exists", path)
        return
    report("create", path)
    if not dry_run:
        path.mkdir(parents=True, exist_ok=True)


def write_file(path: Path, content: str, force: bool, dry_run: bool) -> None:
    if path.exists() and not force:
        report("skip", path)
        return
    report("replace" if path.exists() else "create", path)
    if not dry_run:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")


def initialize_git(project_root: Path, dry_run: bool) -> None:
    git_directory = project_root / ".git"
    if git_directory.exists():
        report("exists", git_directory)
        return
    report("git-init", project_root)
    if dry_run:
        return

    try:
        subprocess.run(
            ["git", "init", "-b", "main"],
            cwd=project_root,
            check=True,
            text=True,
        )
    except subprocess.CalledProcessError:
        subprocess.run(["git", "init"], cwd=project_root, check=True, text=True)
        subprocess.run(
            ["git", "branch", "-M", "main"],
            cwd=project_root,
            check=True,
            text=True,
        )


def main() -> int:
    args = parse_args()
    project_root = Path(args.project_directory).expanduser().resolve()
    skill_root = Path(__file__).resolve().parent.parent
    assets_root = skill_root / "assets"

    if project_root.exists() and not project_root.is_dir():
        raise RuntimeError(f"Project path is not a directory: {project_root}")
    if not args.no_git and not args.dry_run and shutil.which("git") is None:
        raise RuntimeError("Git is required. Install Git or rerun with --no-git.")

    ensure_directory(project_root, args.dry_run)
    for relative_path in DIRECTORIES:
        ensure_directory(project_root / relative_path, args.dry_run)

    for relative_path in EMPTY_FILES:
        write_file(project_root / relative_path, "", args.force, args.dry_run)

    gitignore = (assets_root / "gitignore.template").read_text(encoding="utf-8")
    write_file(project_root / ".gitignore", gitignore, args.force, args.dry_run)

    project_name = args.project_name or project_root.name
    session_template = (assets_root / "SESSION.md.template").read_text(
        encoding="utf-8"
    )
    session_content = session_template.replace("{{PROJECT_NAME}}", project_name)
    session_content = session_content.replace("{{CREATED_AT}}", date.today().isoformat())
    write_file(
        project_root / "log" / "SESSION.md",
        session_content,
        args.force,
        args.dry_run,
    )

    if not args.no_git:
        initialize_git(project_root, args.dry_run)

    print("Initialization complete." if not args.dry_run else "Dry run complete.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
