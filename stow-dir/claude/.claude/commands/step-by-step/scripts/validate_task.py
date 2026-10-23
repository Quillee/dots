#!/usr/bin/env python3
"""Validate that a task folder is well formed.

Checks structure and conventions (front matter, task table, Mermaid tree,
dependency graph, wikilink syntax, folded hints, step format). It does not
judge content quality, and it does not compare the PRD to walkthroughs; use
check_drift.py for that.

Usage:
    python3 validate_task.py TASK_DIR_OR_NAME [--prd-only] [--strict] [--check-stubs]
                             [--repo-root PATH] [--json]

--prd-only validates just the PRD and does not require the walkthrough files it
links to (use it before the walkthroughs exist).

Exit codes: 0 valid (warnings allowed unless --strict), 1 problems found, 2 usage error.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # keep the skill folder free of __pycache__

from _common import (
    DATE_RE, EXIT_FINDINGS, EXIT_OK, OWNERS, PLACEHOLDER, PRD_STATUS, SETTINGS_ALLOWED,
    TASK_STATUS, Findings, add_path_args, emit_json, find_cycle, get_section,
    link_id, link_ids, load_task_dir, locate_task, pad, resolve_link, resolve_paths,
    setup_output, wikilinks, read_text,
)

PRD_REQUIRED = ["type", "repo", "task", "prd", "status", "created", "updated", "settings", "tags"]
WALK_REQUIRED = ["type", "repo", "task", "id", "name", "owner", "status", "depends_on", "blocks", "up", "tags"]
PRD_SECTIONS = [
    "Tasks", "Problem Statement", "Solution", "User Stories", "Implementation Decisions",
    "Testing Decisions", "Out of Scope", "Change Log",
]


def validate_prd(td, f: Findings, prd_only: bool = False) -> None:
    prd = td.prd
    for issue in prd.fm_issues:
        f.error("front-matter", f"{prd.path.name}: {issue}")
    for key in PRD_REQUIRED:
        if key not in prd.fm:
            f.error("front-matter", f"{prd.path.name}: missing '{key}'")
    if prd.fm.get("type") not in (None, "prd"):
        f.error("front-matter", f"{prd.path.name}: type must be 'prd'")
    if prd.fm.get("status") not in (None, *PRD_STATUS):
        f.error("front-matter", f"{prd.path.name}: status '{prd.fm.get('status')}' is not one of {sorted(PRD_STATUS)}")
    for key in ("created", "updated"):
        if key in prd.fm and not DATE_RE.match(str(prd.fm[key])):
            f.error("front-matter", f"{prd.path.name}: {key} must be YYYY-MM-DD")
    if "tags" in prd.fm and not isinstance(prd.fm["tags"], list):
        f.error("front-matter", f"{prd.path.name}: tags must be a list")
    if prd.fm.get("prd") not in (None, prd.stem[len("prd-"):]):
        f.warn("front-matter", f"'prd' is '{prd.fm.get('prd')}' but the file is {prd.path.name}")
    if prd.fm.get("task") not in (None, td.dir.name):
        f.warn("front-matter", f"'task' is '{prd.fm.get('task')}' but the folder is {td.dir.name}")
    if prd.fm.get("repo") not in (None, td.dir.parent.name):
        f.warn("front-matter", f"'repo' is '{prd.fm.get('repo')}' but the folder is {td.dir.parent.name}")
    settings = prd.settings
    if "settings" in prd.fm and not isinstance(prd.fm["settings"], dict):
        f.error("front-matter", "settings must be a mapping")
    for key, allowed in SETTINGS_ALLOWED.items():
        if key not in settings:
            f.warn("settings", f"settings.{key} is not recorded")
        elif settings[key] not in allowed:
            f.error("settings", f"settings.{key} is '{settings[key]}', expected one of {sorted(allowed)}")

    # Task table
    for issue in prd.table_issues:
        f.error("task-table", issue)
    tasks = prd.tasks
    ids = [t.id for t in tasks]
    for dup in sorted({i for i in ids if ids.count(i) > 1}):
        f.error("task-table", "duplicate task number", dup)
    known = set(ids)
    for t in tasks:
        if t.owner not in OWNERS:
            f.error("task-table", f"owner '{t.owner}' must be 'you' or 'claude'", t.id)
        if t.status not in TASK_STATUS:
            f.error("task-table", f"status '{t.status}' is not one of {sorted(TASK_STATUS)}", t.id)
        if not t.name:
            f.error("task-table", "task name is empty", t.id)
        for d in t.depends:
            if d == t.id:
                f.error("dependencies", "a task cannot depend on itself", t.id)
            elif d not in known:
                f.error("dependencies", f"depends on unknown task {pad(d)}", t.id)
            elif d > t.id:
                f.warn("dependencies", f"depends on {pad(d)}, which has a higher number (prerequisites should come first)", t.id)
        if len(t.depends) > 3:
            f.warn("dependencies", "more than three prerequisites; consider splitting this task", t.id)
        if t.status == "blocked" and not t.notes.strip():
            f.warn("task-table", "blocked, but Notes does not say why", t.id)
        if t.walkthrough_target and not prd_only and not resolve_link(t.walkthrough_target, td.prd_root):
            f.error("link", f"walkthrough link does not resolve: [[{t.walkthrough_target}]]", t.id)
        if t.walkthrough_alias and link_id(t.walkthrough_target or "", t.walkthrough_alias) not in (None, t.id):
            f.error("link", "walkthrough alias number does not match the task number", t.id)
    cycle = find_cycle(tasks)
    if cycle:
        f.error("dependencies", "dependency cycle: " + " -> ".join(pad(i) for i in cycle))

    # Mermaid tree
    if prd.mermaid is None:
        f.error("mermaid", "no ```mermaid dependency tree found")
    else:
        nodes, edges = prd.mermaid["nodes"], prd.mermaid["edges"]
        for t in tasks:
            if t.id not in nodes:
                f.error("mermaid", "task is missing from the dependency tree", t.id)
            else:
                label = nodes[t.id]
                if label is not None and not re.match(rf"^0*{t.id}\b", label):
                    f.warn("mermaid", f"node label '{label}' should start with the task number", t.id)
        for stray in sorted(set(nodes) - known):
            f.error("mermaid", f"node T{pad(stray)} is not a task in the table")
        expected = {(d, t.id) for t in tasks for d in t.depends if d in known}
        for a, b in sorted(expected - edges):
            f.error("mermaid", f"missing edge {pad(a)} --> {pad(b)}")
        for a, b in sorted(edges - expected):
            f.error("mermaid", f"edge {pad(a)} --> {pad(b)} is not in the task table")

    # Sections and placeholders
    for heading in PRD_SECTIONS:
        if get_section(prd.body, heading) is None:
            f.warn("sections", f"missing section '## {heading}'")
    if prd.next_up_link is None and "Next up" not in prd.body:
        f.warn("sections", "missing the 'Next up' callout")
    left = prd.text.count(PLACEHOLDER)
    if left:
        f.warn("placeholder", f"{left} unfinished placeholder(s) '{PLACEHOLDER}' in the PRD")
    validate_links_syntax(prd.path.name, prd.text, f)


def validate_links_syntax(name: str, text: str, f: Findings) -> None:
    for target, _alias in wikilinks(text):
        if target.endswith(".md"):
            f.warn("link", f"{name}: wikilink should omit the .md extension: [[{target}]]")
        if "/" not in target:
            f.warn("link", f"{name}: wikilink is not path-qualified from the vault root: [[{target}]]")


def validate_walkthroughs(td, f: Findings) -> None:
    prd = td.prd
    tasks = {t.id: t for t in prd.tasks}
    settings = prd.settings
    hints_mode = settings.get("hints", "graduated")

    for p in td.stray:
        f.error("filename", f"{p.name} does not match NN[.MM]-slug.md or prd-<name>.md")

    for w in td.walkthroughs:
        label = w.file_id
        for issue in w.fm_issues:
            f.error("front-matter", f"{w.path.name}: {issue}", label)
        for key in WALK_REQUIRED:
            if key not in w.fm:
                f.error("front-matter", f"{w.path.name}: missing '{key}'", label)
        if w.fm.get("type") not in (None, "walkthrough"):
            f.error("front-matter", "type must be 'walkthrough'", label)
        if w.fm.get("owner") not in (None, *OWNERS):
            f.error("front-matter", f"owner '{w.fm.get('owner')}' must be 'you' or 'claude'", label)
        if w.fm.get("status") not in (None, *TASK_STATUS):
            f.error("front-matter", f"status '{w.fm.get('status')}' is not one of {sorted(TASK_STATUS)}", label)
        if w.fm.get("id") not in (None, w.file_id):
            f.error("front-matter", f"id {w.fm.get('id')} does not match the filename number {w.file_id}", label)
        for key in ("depends_on", "blocks", "tags"):
            if key in w.fm and not isinstance(w.fm[key], list):
                f.error("front-matter", f"{key} must be a list", label)
        for key in ("depends_on", "blocks"):
            for tid in link_ids(w.fm.get(key, [])):
                if tid is None:
                    f.error("front-matter", f"{key} has a link without a task number (alias should be 'NN Name')", label)
        up = w.fm.get("up")
        if isinstance(up, str):
            links = wikilinks(up)
            if not links:
                f.error("front-matter", "up must be a wikilink to the PRD", label)
            elif not links[0][0].rsplit("/", 1)[-1].startswith("prd-"):
                f.error("front-matter", "up must point at the PRD", label)

        if w.file_id not in tasks:
            f.error("filename", "no task with this number in the PRD", label)
        for d in w.file_deps:
            if d == w.file_id:
                f.error("filename", "filename lists the task as its own prerequisite", label)
            elif d not in tasks:
                f.error("filename", f"filename lists unknown prerequisite {pad(d)}", label)

        if w.resume is None:
            f.error("structure", "missing the 'Resume here' callout", label)
        if not w.steps_section:
            f.error("structure", "missing the '## Steps' section", label)
        elif not w.steps:
            f.error("structure", "'## Steps' has no checkbox steps", label)
        task_row = tasks.get(w.file_id)
        if task_row is not None and task_row.owner == "you" and get_section(w.body, "Tests") is None:
            f.warn("structure", "missing the '## Tests' section (the tests that define done and the command to run them)", label)
        for step in w.steps:
            if "done when" not in step.text.lower():
                f.warn("steps", f"step {step.num or '?'} has no 'Done when'", label)

        # Hints: always folded
        for marker in re.findall(r"^\s*>\s*\[!hint\]([+-]?)", w.body, re.M):
            if marker != "-":
                f.error("hints", "a hint callout is not folded (use [!hint]-)", label)
                break
        if re.search(r"^\s*>\s*\[!success\](?!-)\s*Reference solution", w.body, re.M | re.I):
            f.error("hints", "the reference solution callout is not folded (use [!success]-)", label)
        hint_count = len(re.findall(r"^\s*>\s*\[!hint\]", w.body, re.M))
        is_yours = str(w.fm.get("owner")) == "you"
        if hints_mode == "none" and hint_count:
            f.warn("hints", "settings say hints=none but hint callouts are present", label)
        if is_yours and hints_mode in {"graduated", "full"} and hint_count == 0:
            f.warn("hints", f"settings say hints={hints_mode} but there are no hint callouts", label)
        if is_yours and hints_mode == "full" and not re.search(r"\[!success\]-?\s*Reference solution", w.body, re.I):
            f.warn("hints", "settings say hints=full but there is no reference solution", label)

        left = w.text.count(PLACEHOLDER)
        if left:
            f.warn("placeholder", f"{left} unfinished placeholder(s) '{PLACEHOLDER}'", label)
        validate_links_syntax(w.path.name, w.text, f)
        for target, _alias in wikilinks(w.text):
            if not resolve_link(target, td.prd_root):
                f.error("link", f"wikilink does not resolve: [[{target}]]", label)

        # Pipes in table-like lines inside walkthroughs are fine; only the PRD table matters.


def check_stubs(td, repo_root: Path, f: Findings) -> None:
    """Warn when an unfinished user-owned task has no TODO(you) NN marker in the repo."""
    skip_dirs = {".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build", ".next", "target"}
    found: set = set()
    pattern = re.compile(r"TODO\(you\)\s*(\d+)")
    for path in repo_root.rglob("*"):
        if any(part in skip_dirs for part in path.parts) or not path.is_file():
            continue
        try:
            if path.stat().st_size > 1_000_000:
                continue
            for m in pattern.finditer(read_text(path)):
                found.add(int(m.group(1)))
        except (OSError, UnicodeDecodeError):
            continue
    for t in td.prd.tasks:
        if t.owner == "you" and t.status in {"not-started", "in-progress"} and t.id not in found:
            f.warn("stubs", f"no 'TODO(you) {pad(t.id)}' marker found in {repo_root.name}", t.id)


def main(argv=None) -> int:
    setup_output()
    ap = argparse.ArgumentParser(description="Validate the structure and conventions of a step-by-step task folder.")
    ap.add_argument("task", help="task directory path, or a task name under prd/<repo>/")
    add_path_args(ap)
    ap.add_argument("--prd-only", action="store_true", help="validate only the PRD; walkthrough files need not exist yet")
    ap.add_argument("--strict", action="store_true", help="treat warnings as errors")
    ap.add_argument("--check-stubs", action="store_true", help="also look for TODO(you) NN markers in the repo")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    args = ap.parse_args(argv)

    prd_root, task_dir = locate_task(args)
    td = load_task_dir(task_dir, prd_root)
    f = Findings()
    if td.prd is None:
        f.error("prd", td.prd_problem or "PRD could not be read")
    else:
        validate_prd(td, f, prd_only=args.prd_only)
        if not args.prd_only:
            validate_walkthroughs(td, f)
        if args.check_stubs:
            check_stubs(td, resolve_paths(args).repo_root, f)

    failed = bool(f.errors) or (args.strict and bool(f.warnings))
    if args.json:
        data = f.to_dict()
        data["ok"] = not failed
        emit_json({"task_dir": str(task_dir), **data})
    else:
        print(f.render(f"Validate: {td.prefix}", "ERRORS", "Valid: no problems found."))
        if failed:
            print("\nFix every error before moving on.")
    return EXIT_FINDINGS if failed else EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
