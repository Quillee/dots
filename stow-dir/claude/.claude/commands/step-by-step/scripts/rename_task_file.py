#!/usr/bin/env python3
"""Rename a walkthrough so its filename matches the PRD, and fix every wikilink to it.

Obsidian only updates links when a file is renamed inside the app, so this does
it explicitly. By default the new dependency chain comes from the PRD (the
source of truth); --depends and --slug override it.

Usage:
    python3 rename_task_file.py TASK_DIR_OR_NAME --id 4
    python3 rename_task_file.py TASK_DIR_OR_NAME --id 4 --depends 2 3
    python3 rename_task_file.py TASK_DIR_OR_NAME --id 4 --depends none --slug api-wiring
    Add --dry-run to preview, --vault to rewrite links across all of prd/, --json for machine output.

Exit codes: 0 done or already correct, 2 usage error or refused (for example,
the target filename already exists).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # keep the skill folder free of __pycache__

from _common import (
    EXIT_OK, SLUG_RE, WIKILINK_PARTS_RE, add_path_args, die, emit_json, load_task_dir,
    locate_task, pad, read_text, setup_output, walk_stem, write_text,
)


def rewrite_links(text: str, old_targets: set, new_target: str) -> tuple[str, int]:
    count = 0

    def repl(match):
        nonlocal count
        target = match.group(1).strip()
        if target not in old_targets:
            return match.group(0)
        count += 1
        return "[[" + new_target + (match.group(2) or "") + (match.group(3) or "") + "]]"

    return WIKILINK_PARTS_RE.sub(repl, text), count


def parse_depends(values, task_id: int) -> list[int]:
    if values == ["none"]:
        return []
    deps: list[int] = []
    for v in values:
        if not v.isdigit():
            die(f"--depends takes task numbers or 'none', got '{v}'")
        n = int(v)
        if n == task_id:
            die("a task cannot depend on itself")
        if n not in deps:
            deps.append(n)
    return deps


def main(argv=None) -> int:
    setup_output()
    ap = argparse.ArgumentParser(description="Rename a walkthrough to match its dependencies and rewrite wikilinks.")
    ap.add_argument("task", help="task directory path, or a task name under prd/<repo>/")
    ap.add_argument("--id", type=int, required=True, help="task number of the walkthrough to rename")
    ap.add_argument("--depends", nargs="+", metavar="N", help="new prerequisite numbers, or 'none' (default: from the PRD)")
    ap.add_argument("--slug", help="new slug (default: keep the current one)")
    ap.add_argument("--vault", action="store_true", help="rewrite links in every file under prd/, not only this task folder")
    ap.add_argument("--dry-run", action="store_true", help="show what would change without changing anything")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    add_path_args(ap)
    args = ap.parse_args(argv)

    prd_root, task_dir = locate_task(args)
    td = load_task_dir(task_dir, prd_root)
    files = td.walkthroughs_for(args.id)
    if not files:
        die(f"no walkthrough file for task {pad(args.id)} in {task_dir}")
    if len(files) > 1:
        die(f"more than one walkthrough for task {pad(args.id)}: " + ", ".join(f.path.name for f in files))
    walk = files[0]

    if args.depends is not None:
        deps = parse_depends(args.depends, args.id)
    else:
        if td.prd is None:
            die(f"cannot read dependencies from the PRD ({td.prd_problem}); pass --depends")
        task = next((t for t in td.prd.tasks if t.id == args.id), None)
        if task is None:
            die(f"task {pad(args.id)} is not in the PRD; pass --depends")
        deps = list(task.depends)
    known = {t.id for t in td.prd.tasks} if td.prd else None
    if known is not None:
        unknown = [d for d in deps if d not in known]
        if unknown:
            die("unknown prerequisite(s): " + ", ".join(pad(d) for d in unknown))

    slug = args.slug or walk.slug
    if not SLUG_RE.match(slug):
        die(f"slug '{slug}' must be lowercase kebab-case (a-z, 0-9, hyphens)")

    old_stem = walk.stem
    new_stem = walk_stem(args.id, deps, slug)
    if new_stem == old_stem:
        msg = f"Already correct: {walk.path.name}"
        emit_json({"changed": False, "file": walk.path.name}) if args.json else print(msg)
        return EXIT_OK

    new_path = walk.path.with_name(new_stem + ".md")
    if new_path.exists():
        die(f"target already exists: {new_path.name}")

    prefix = td.prefix
    old_targets = {f"{prefix}/{old_stem}", f"{prefix}/{old_stem}.md"}
    new_target = f"{prefix}/{new_stem}"

    scope = sorted(prd_root.rglob("*.md")) if args.vault else sorted(task_dir.glob("*.md"))
    plan = []
    for path in scope:
        text = read_text(path)
        updated, count = rewrite_links(text, old_targets, new_target)
        if count:
            plan.append((path, updated, count))

    report = {
        "changed": not args.dry_run,
        "dry_run": args.dry_run,
        "old": walk.path.name,
        "new": new_path.name,
        "links_updated": [
            {"file": str(p.relative_to(prd_root).as_posix()), "count": c} for p, _t, c in plan
        ],
    }

    if not args.dry_run:
        for path, updated, _count in plan:
            write_text(path, updated)
        walk.path.rename(new_path)

    if args.json:
        emit_json(report)
    else:
        verb = "Would rename" if args.dry_run else "Renamed"
        print(f"{verb}: {walk.path.name} -> {new_path.name}")
        total = sum(c for _p, _t, c in plan)
        print(f"Wikilinks {'to update' if args.dry_run else 'updated'}: {total} in {len(plan)} file(s)")
        for p, _t, c in plan:
            print(f"  {p.relative_to(prd_root).as_posix()}: {c}")
        print("Next: run check_drift.py. The renamed file's depends_on and blocks front matter "
              "may need regenerating from the PRD.")
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
