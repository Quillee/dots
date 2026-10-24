#!/usr/bin/env python3
"""Create a task folder: the PRD skeleton and walkthrough skeletons.

The script handles structure (paths, numbering, filenames, links, front matter,
the task table, the Mermaid tree, the Next up callout). Claude fills in the
prose. Placeholders read '_(to be written)_' and validate_task.py warns until
they are gone.

Create mode (from an approved task list):
    python3 new_task.py --name rate-limiter --spec tasks.json [--title "Rate limiter"]
                        [--prd-name NAME] [--set own=more hints=none ...]
                        [--prd-only] [--force] [--dry-run] [--date YYYY-MM-DD] [--json]

Sync mode (create any walkthrough the PRD links but that does not exist yet):
    python3 new_task.py --sync TASK_DIR_OR_NAME [--dry-run] [--json]

Spec file (JSON):
    {
      "title": "Rate limiter",
      "settings": {"own": "core"},
      "tasks": [
        {"id": 1, "name": "Project wiring", "owner": "claude", "depends_on": [],
         "walkthrough": false, "notes": "Config and CI hooks only"},
        {"id": 2, "name": "Interfaces", "owner": "claude", "depends_on": [1]},
        {"id": 3, "name": "Token store", "owner": "you", "depends_on": [2]}
      ]
    }
    'walkthrough' defaults to true for owner 'you' and false for 'claude'.

Existing walkthroughs are never overwritten. The PRD is overwritten only with --force.

Exit codes: 0 created, 2 usage error or refused.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

sys.dont_write_bytecode = True  # keep the skill folder free of __pycache__

from _common import (
    EXIT_OK, OWNERS, PLACEHOLDER, SETTINGS_ALLOWED, SETTINGS_DEFAULTS, SLUG_RE,
    TASK_STATUS, WALKTHROUGH_RE, Task, add_path_args, die, emit_json, find_cycle,
    load_task_dir, locate_task, next_focus, pad, resolve_paths, setup_output,
    slugify, walk_stem, write_text, dependents,
)

BAD_NAME_CHARS = re.compile(r"[|\[\]#^\n\r]")


def yaml_str(value: str) -> str:
    if re.fullmatch(r"[A-Za-z0-9 _().,/'-]+", value) and value.strip() == value:
        return value
    return json.dumps(value, ensure_ascii=False)


def link(prefix: str, stem: str, alias: str, table: bool = False) -> str:
    return f"[[{prefix}/{stem}{chr(92) + '|' if table else '|'}{alias}]]"


def prd_link(prefix: str, prd_stem: str, alias: str, table: bool = False) -> str:
    return f"[[{prefix}/{prd_stem}#Tasks{chr(92) + '|' if table else '|'}{alias}]]"


def alias_for(task: Task) -> str:
    return f"{pad(task.id)} {task.name}"


def task_link(prefix, prd_stem, task: Task, stems: dict, table: bool = False) -> str:
    stem = stems.get(task.id)
    if stem:
        return link(prefix, stem, alias_for(task), table)
    return prd_link(prefix, prd_stem, alias_for(task), table)


# --------------------------------------------------------------------------
# Building the PRD
# --------------------------------------------------------------------------

def build_prd(repo, task_name, prd_name, title, settings, tasks, stems, today) -> str:
    prefix = f"{repo}/{task_name}"
    prd_stem = f"prd-{prd_name}"
    by_id = {t.id: t for t in tasks}
    lines = [
        "---", "type: prd", f"repo: {repo}", f"task: {task_name}", f"prd: {prd_name}",
        "status: planning", f"created: {today}", f"updated: {today}", "settings:",
    ]
    lines += [f"  {key}: {settings[key]}" for key in SETTINGS_DEFAULTS]
    lines += ["tags:", "  - prd", "  - step-by-step", "---", "", f"# {title}", ""]

    nxt, eligible = next_focus(tasks)
    lines.append("> [!info] Next up")
    if nxt is None:
        lines.append("> Nothing for you yet.")
    else:
        step = ", step 1" if stems.get(nxt.id) else ""
        lead = "" if eligible else "After Claude's scaffolding: "
        lines.append(f"> {lead}{task_link(prefix, prd_stem, nxt, stems)}{step}. Owner: you.")
    lines += ["", "## Tasks", "",
              "| # | Task | Owner | Depends on | Status | Walkthrough | Notes |",
              "|---|------|-------|------------|--------|-------------|-------|"]
    for t in sorted(tasks, key=lambda t: t.id):
        deps = ", ".join(pad(d) for d in t.depends) if t.depends else "none"
        walk = link(prefix, stems[t.id], alias_for(t), table=True) if stems.get(t.id) else "n/a"
        lines.append(f"| {pad(t.id)} | {t.name} | {t.owner} | {deps} | {t.status} | {walk} | {t.notes} |")
    lines += ["", "### Dependency tree", "", "```mermaid", "graph TD"]
    for t in sorted(tasks, key=lambda t: t.id):
        label = f"{pad(t.id)} {t.name} ({t.owner})".replace('"', "'")
        lines.append(f'  T{pad(t.id)}["{label}"]')
    for t in sorted(tasks, key=lambda t: t.id):
        for d in sorted(t.depends):
            lines.append(f"  T{pad(d)} --> T{pad(t.id)}")
    lines += ["```", ""]
    for heading, hint in [
        ("Problem Statement", "The problem the user is facing, from the user's perspective."),
        ("Solution", "The solution, from the user's perspective."),
        ("User Stories", "A long, numbered list: As an <actor>, I want <feature>, so that <benefit>."),
        ("Implementation Decisions", "Modules, interfaces, architecture, schema, API contracts. No file paths or code snippets."),
        ("Testing Decisions", "What makes a good test here, the agreed seams, modules tested, prior art."),
        ("Assumptions and Open Questions", "Assumptions made and any PRD-level open questions."),
        ("Out of Scope", "What this PRD deliberately does not cover."),
        ("Further Notes", "Anything else worth recording."),
    ]:
        lines += [f"## {heading}", "", PLACEHOLDER + f" <!-- {hint} -->", ""]
    summary = ", ".join(f"{k}={settings[k]}" for k in SETTINGS_DEFAULTS)
    lines += ["## Change Log", "", f"- {today}: Created. Settings: {summary}.", ""]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Building a walkthrough skeleton
# --------------------------------------------------------------------------

def build_walkthrough(repo, task_name, prd_name, task: Task, tasks, stems, settings, today) -> str:
    prefix = f"{repo}/{task_name}"
    prd_stem = f"prd-{prd_name}"
    by_id = {t.id: t for t in tasks}
    yours = task.owner == "you"
    hints = settings.get("hints", "graduated")

    def link_list(ids):
        return [f'  - "{task_link(prefix, prd_stem, by_id[i], stems)}"' for i in ids if i in by_id]

    dep_lines = link_list(sorted(task.depends))
    block_lines = link_list(dependents(tasks, task.id))
    lines = [
        "---", "type: walkthrough", f"repo: {repo}", f"task: {task_name}", f"id: {task.id}",
        f"name: {yaml_str(task.name)}", f"owner: {task.owner}", f"status: {task.status}",
    ]
    lines += ["depends_on:"] + dep_lines if dep_lines else ["depends_on: []"]
    lines += ["blocks:"] + block_lines if block_lines else ["blocks: []"]
    lines += [f'up: "[[{prefix}/{prd_stem}|PRD]]"', "tags:", "  - walkthrough", f"  - owner/{task.owner}", "---", "",
              f"# {pad(task.id)} {task.name}", "",
              "> [!info] Resume here", "> Step 1. Nothing started yet.", ""]
    if yours:
        lines += ["## Why this is yours", "", PLACEHOLDER, ""]
    lines += ["## Context", "", PLACEHOLDER, "", "## Contract", "", PLACEHOLDER, ""]
    if yours:
        lines += ["## Tests", "", PLACEHOLDER, ""]
    lines += ["## Steps", "", f"- [ ] 1. {PLACEHOLDER} *Done when:* {PLACEHOLDER}", ""]
    if yours and hints in {"graduated", "full"}:
        lines += ["## Hints", "", "### Step 1", "",
                  "> [!hint]- Hint 1: nudge", f"> {PLACEHOLDER}", "",
                  "> [!hint]- Hint 2: pointer", f"> {PLACEHOLDER}", "",
                  "> [!hint]- Hint 3: worked example", f"> {PLACEHOLDER}", ""]
    if yours and hints == "full":
        lines += ["## Reference solution", "", "> [!success]- Reference solution", f"> {PLACEHOLDER}", ""]
    lines += ["## Open questions", "", "_None yet._", "",
              "## Done when", "", PLACEHOLDER, "",
              "## Log", "", f"- {today}: Created from PRD.", ""]
    return "\n".join(lines)


# --------------------------------------------------------------------------
# Spec handling
# --------------------------------------------------------------------------

def load_tasks(spec: dict) -> tuple[list[Task], dict]:
    raw_tasks = spec.get("tasks", [])
    if not isinstance(raw_tasks, list):
        die("spec 'tasks' must be a list")
    tasks: list[Task] = []
    wants: dict = {}
    seen: set = set()
    for index, raw in enumerate(raw_tasks, 1):
        if not isinstance(raw, dict):
            die(f"task #{index} must be an object")
        tid = raw.get("id")
        if not isinstance(tid, int) or tid < 1:
            die(f"task #{index}: 'id' must be a positive integer")
        if tid in seen:
            die(f"duplicate task id {tid}")
        seen.add(tid)
        name = str(raw.get("name", "")).strip()
        if not name:
            die(f"task {tid}: 'name' is required")
        if BAD_NAME_CHARS.search(name):
            die(f"task {tid}: name may not contain | [ ] # ^ or line breaks")
        owner = str(raw.get("owner", "")).lower()
        if owner not in OWNERS:
            die(f"task {tid}: 'owner' must be 'you' or 'claude'")
        status = str(raw.get("status", "not-started")).lower()
        if status not in TASK_STATUS:
            die(f"task {tid}: status '{status}' is not one of {sorted(TASK_STATUS)}")
        deps = raw.get("depends_on", [])
        if not isinstance(deps, list) or not all(isinstance(d, int) for d in deps):
            die(f"task {tid}: 'depends_on' must be a list of task numbers")
        notes = str(raw.get("notes", "")).replace("|", "/").replace("\n", " ").strip()
        wants[tid] = bool(raw.get("walkthrough", owner == "you"))
        tasks.append(Task(id=tid, name=name, owner=owner, depends=sorted(set(deps)), status=status,
                          walkthrough_target=None, walkthrough_alias=None, notes=notes))
    known = {t.id for t in tasks}
    for t in tasks:
        for d in t.depends:
            if d == t.id:
                die(f"task {t.id} cannot depend on itself")
            if d not in known:
                die(f"task {t.id} depends on unknown task {d}")
    cycle = find_cycle(tasks)
    if cycle:
        die("dependency cycle: " + " -> ".join(pad(i) for i in cycle))
    return tasks, wants


def merge_settings(spec_settings, overrides) -> dict:
    settings = dict(SETTINGS_DEFAULTS)
    for source in (spec_settings or {}, overrides):
        for key, value in source.items():
            if key not in SETTINGS_ALLOWED:
                die(f"unknown setting '{key}' (expected one of {sorted(SETTINGS_ALLOWED)})")
            if value not in SETTINGS_ALLOWED[key]:
                die(f"setting {key}={value} is invalid (expected one of {sorted(SETTINGS_ALLOWED[key])})")
            settings[key] = value
    return settings


def parse_overrides(pairs) -> dict:
    result = {}
    for pair in pairs or []:
        if "=" not in pair:
            die(f"--set takes key=value pairs, got '{pair}'")
        key, value = pair.split("=", 1)
        result[key.strip()] = value.strip()
    return result


# --------------------------------------------------------------------------
# Modes
# --------------------------------------------------------------------------

def create_mode(args) -> int:
    if not args.name:
        die("--name is required (a short kebab-case task name), or use --sync")
    name = args.name
    if not SLUG_RE.match(name):
        suggestion = slugify(name)
        die(f"task name '{name}' must be lowercase kebab-case; try '{suggestion}'")
    prd_name = args.prd_name or name
    if not SLUG_RE.match(prd_name):
        die(f"prd name '{prd_name}' must be lowercase kebab-case")

    spec: dict = {}
    if args.spec:
        try:
            spec = json.loads(Path(args.spec).read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            die(f"cannot read spec: {exc}")
    tasks, wants = load_tasks(spec)
    settings = merge_settings(spec.get("settings"), parse_overrides(args.set))
    title = args.title or spec.get("title") or name.replace("-", " ").capitalize()
    today = args.date or date.today().isoformat()

    paths = resolve_paths(args)
    task_dir = paths.prd_root / paths.repo / name
    prd_path = task_dir / f"prd-{prd_name}.md"
    existing_prds = sorted(task_dir.glob("prd-*.md")) if task_dir.is_dir() else []
    if existing_prds and not args.force:
        die(f"{task_dir} already has a PRD ({existing_prds[0].name}). Resume it, pick a new name, or pass --force to overwrite the PRD.")
    if existing_prds and existing_prds[0] != prd_path:
        die(f"a different PRD already exists here: {existing_prds[0].name}")

    stems = {}
    for t in tasks:
        stems[t.id] = walk_stem(t.id, t.depends, slugify(t.name)) if wants[t.id] else None
        if stems[t.id] and not WALKTHROUGH_RE.match(stems[t.id] + ".md"):
            die(f"task {t.id}: cannot make a valid filename from '{t.name}'")
    seen_stems: dict = {}
    for t in tasks:
        if stems[t.id]:
            seen_stems.setdefault(stems[t.id], []).append(t.id)

    planned = [("PRD", prd_path, build_prd(paths.repo, name, prd_name, title, settings, tasks, stems, today))]
    skipped = []
    if not args.prd_only:
        for t in sorted(tasks, key=lambda t: t.id):
            if not stems[t.id]:
                continue
            path = task_dir / (stems[t.id] + ".md")
            if path.exists():
                skipped.append(path)
                continue
            planned.append(("walkthrough", path, build_walkthrough(paths.repo, name, prd_name, t, tasks, stems, settings, today)))

    if not args.dry_run:
        for _kind, path, text in planned:
            write_text(path, text)

    report = {
        "dry_run": args.dry_run,
        "prd_root": str(paths.prd_root),
        "prd_root_existed": paths.prd_root.is_dir() if args.dry_run else None,
        "task_dir": str(task_dir),
        "vault_prefix": f"{paths.repo}/{name}",
        "settings": settings,
        "created": [str(p.relative_to(paths.prd_root).as_posix()) for _k, p, _t in planned],
        "skipped_existing": [str(p.relative_to(paths.prd_root).as_posix()) for p in skipped],
    }
    if args.json:
        emit_json(report)
    else:
        print(("Would create" if args.dry_run else "Created") + f" {task_dir}")
        for kind, path, _t in planned:
            print(f"  {kind}: {path.relative_to(paths.prd_root).as_posix()}")
        for path in skipped:
            print(f"  kept existing: {path.relative_to(paths.prd_root).as_posix()}")
        print("Next: fill in the placeholders, then run validate_task.py.")
    return EXIT_OK


def sync_mode(args) -> int:
    args.task = args.sync
    prd_root, task_dir = locate_task(args)
    td = load_task_dir(task_dir, prd_root)
    if td.prd is None:
        die(td.prd_problem or "PRD could not be read")
    prd = td.prd
    if prd.table_issues:
        die("fix the PRD task table first: " + "; ".join(prd.table_issues))
    repo, task_name = task_dir.parent.name, task_dir.name
    prd_name = prd.stem[len("prd-"):]
    settings = dict(SETTINGS_DEFAULTS)
    settings.update({k: v for k, v in prd.settings.items() if k in SETTINGS_ALLOWED})
    today = args.date or date.today().isoformat()

    stems = {}
    for t in prd.tasks:
        if t.walkthrough_target:
            stem = t.walkthrough_target.rsplit("/", 1)[-1]
            stems[t.id] = stem[:-3] if stem.endswith(".md") else stem
        else:
            stems[t.id] = None
    created, existing = [], []
    for t in sorted(prd.tasks, key=lambda t: t.id):
        stem = stems[t.id]
        if not stem:
            continue
        if not WALKTHROUGH_RE.match(stem + ".md"):
            die(f"task {pad(t.id)}: the PRD links '{stem}', which is not a valid NN[.MM]-slug name")
        path = task_dir / (stem + ".md")
        if path.exists():
            existing.append(path.name)
            continue
        if not args.dry_run:
            write_text(path, build_walkthrough(repo, task_name, prd_name, t, prd.tasks, stems, settings, today))
        created.append(path.name)

    if args.json:
        emit_json({"dry_run": args.dry_run, "task_dir": str(task_dir), "created": created, "already_present": existing})
    else:
        print(("Would create" if args.dry_run else "Created") + f" {len(created)} walkthrough skeleton(s) in {task_dir}")
        for n in created:
            print(f"  {n}")
        if existing:
            print(f"Left {len(existing)} existing walkthrough(s) untouched.")
        if not created:
            print("Nothing to do: every walkthrough the PRD links already exists.")
    return EXIT_OK


def main(argv=None) -> int:
    setup_output()
    ap = argparse.ArgumentParser(description="Create a step-by-step task folder (PRD and walkthrough skeletons).")
    ap.add_argument("--name", help="task name, kebab-case (create mode)")
    ap.add_argument("--prd-name", help="PRD name, kebab-case (default: the task name)")
    ap.add_argument("--title", help="human-readable PRD title")
    ap.add_argument("--spec", help="JSON file describing settings and tasks")
    ap.add_argument("--set", nargs="+", metavar="KEY=VALUE", help="override settings, e.g. own=more hints=none")
    ap.add_argument("--prd-only", action="store_true", help="write only the PRD; create walkthroughs later with --sync")
    ap.add_argument("--force", action="store_true", help="overwrite an existing PRD (never overwrites walkthroughs)")
    ap.add_argument("--sync", metavar="TASK", help="sync mode: create walkthroughs the PRD links but that are missing")
    ap.add_argument("--dry-run", action="store_true", help="show what would be created")
    ap.add_argument("--date", help="override today's date (YYYY-MM-DD)")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    add_path_args(ap)
    args = ap.parse_args(argv)
    if args.date and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", args.date):
        die("--date must be YYYY-MM-DD")
    return sync_mode(args) if args.sync else create_mode(args)


if __name__ == "__main__":
    sys.exit(main())
