#!/usr/bin/env python3
"""List step-by-step tasks, resolve paths, and pick a task to resume.

Usage:
    python3 list_tasks.py                  tasks for the current repo
    python3 list_tasks.py --all            tasks for every repo under prd/
    python3 list_tasks.py --unfinished     only tasks that are not done or dropped
    python3 list_tasks.py --paths          print repo_root, repo, prd_root and whether prd/ exists
    python3 list_tasks.py --resume [NAME]  decide which task to resume
    Add --json for machine-readable output.

Exit codes: 0 ok (for --resume: exactly one task resolved), 1 (for --resume: none
or ambiguous), 2 usage error.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # keep the skill folder free of __pycache__

from _common import (
    EXIT_FINDINGS, EXIT_OK, FINISHED, PRD_FILE_RE, add_path_args, emit_json,
    load_task_dir, next_up, pad, resolve_paths, setup_output,
)


def summarize(task_dir: Path, prd_root: Path) -> dict:
    td = load_task_dir(task_dir, prd_root)
    info = {
        "repo": task_dir.parent.name,
        "task": task_dir.name,
        "path": str(task_dir),
        "status": None,
        "done": 0,
        "total": 0,
        "next": None,
        "next_task": None,
        "next_walkthrough": None,
        "resume_here": None,
        "problem": td.prd_problem,
    }
    prd = td.prd
    if prd is None:
        return info
    info["status"] = str(prd.fm.get("status", "unknown"))
    tasks = prd.tasks
    info["total"] = len(tasks)
    info["done"] = sum(1 for t in tasks if t.status in FINISHED)
    if prd.table_issues:
        info["problem"] = "; ".join(prd.table_issues)

    nxt = next_up(tasks)
    if nxt is not None:
        info["next_task"] = nxt.id
        text = f"{pad(nxt.id)} {nxt.name} (you)"
        walk = next((w for w in td.walkthroughs_for(nxt.id)), None)
        if walk is not None:
            info["next_walkthrough"] = str(walk.path)
            info["resume_here"] = walk.resume
            if walk.steps:
                unchecked = [s for s in walk.steps if not s.checked]
                if unchecked:
                    step = unchecked[0]
                    number = step.num if step.num is not None else walk.steps.index(step) + 1
                    text += f", step {number} of {len(walk.steps)}"
                else:
                    text += ", all steps checked (review and mark done)"
        else:
            text += ", no walkthrough (see the PRD row and the TODO(you) stub)"
        info["next"] = text
    else:
        pending = [t for t in tasks if t.owner == "claude" and t.status not in FINISHED]
        if pending:
            info["next"] = "claude pass pending: " + ", ".join(pad(t.id) for t in sorted(pending, key=lambda t: t.id))
        elif tasks:
            info["next"] = "complete"
        else:
            info["next"] = "no tasks yet"
    return info


def scan(prd_root: Path, repo: str | None) -> list[dict]:
    results = []
    if not prd_root.is_dir():
        return results
    repos = [prd_root / repo] if repo else sorted(p for p in prd_root.iterdir() if p.is_dir() and not p.name.startswith("."))
    for repo_dir in repos:
        if not repo_dir.is_dir():
            continue
        for task_dir in sorted(p for p in repo_dir.iterdir() if p.is_dir() and not p.name.startswith(".")):
            if any(PRD_FILE_RE.match(f.name) for f in task_dir.iterdir() if f.is_file()):
                results.append(summarize(task_dir, prd_root))
    return results


def is_unfinished(info: dict) -> bool:
    return info["status"] in {"planning", "in-progress"} or (info["status"] is None and info["problem"] is not None)


def render_table(rows: list[dict], show_repo: bool) -> str:
    if not rows:
        return "No tasks found."
    lines = []
    width = max(len((f"{r['repo']}/" if show_repo else "") + r["task"]) for r in rows)
    for r in rows:
        name = (f"{r['repo']}/" if show_repo else "") + r["task"]
        if r["status"] is None:
            lines.append(f"{name.ljust(width)}  unreadable PRD: {r['problem']}")
            continue
        progress = f"{r['done']}/{r['total']} done"
        lines.append(f"{name.ljust(width)}  {r['status'].ljust(11)}  {progress.ljust(11)}  next: {r['next']}")
    return "\n".join(lines)


def match_name(rows: list[dict], name: str) -> list[dict]:
    exact = [r for r in rows if r["task"] == name]
    if exact:
        return exact
    prefix = [r for r in rows if r["task"].startswith(name)]
    if prefix:
        return prefix
    return [r for r in rows if name in r["task"]]


def main(argv=None) -> int:
    setup_output()
    ap = argparse.ArgumentParser(description="List step-by-step tasks and decide which to resume.")
    add_path_args(ap)
    ap.add_argument("--all", action="store_true", help="include every repo under prd/")
    ap.add_argument("--unfinished", action="store_true", help="hide tasks that are done or dropped")
    ap.add_argument("--paths", action="store_true", help="print resolved paths and exit")
    ap.add_argument("--resume", nargs="?", const="", metavar="NAME", help="resolve which task to resume")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    args = ap.parse_args(argv)

    paths = resolve_paths(args)

    if args.paths:
        data = {
            "repo_root": str(paths.repo_root),
            "repo": paths.repo,
            "prd_root": str(paths.prd_root),
            "prd_root_exists": paths.prd_root.is_dir(),
            "repo_dir": str(paths.prd_root / paths.repo),
            "repo_dir_exists": (paths.prd_root / paths.repo).is_dir(),
        }
        if args.json:
            emit_json(data)
        else:
            for key, value in data.items():
                print(f"{key}: {value}")
        return EXIT_OK

    if args.resume is not None:
        rows = [r for r in scan(paths.prd_root, paths.repo) if is_unfinished(r)]
        if args.resume:
            matches = match_name(rows, args.resume)
            if not matches:
                everything = match_name(scan(paths.prd_root, paths.repo), args.resume)
                outcome = {"resolved": False, "reason": "finished" if everything else "not-found", "candidates": everything or rows}
            elif len(matches) > 1:
                outcome = {"resolved": False, "reason": "ambiguous", "candidates": matches}
            else:
                outcome = {"resolved": True, "task": matches[0]}
        elif len(rows) == 1:
            outcome = {"resolved": True, "task": rows[0]}
        elif not rows:
            outcome = {"resolved": False, "reason": "no-unfinished-tasks", "candidates": []}
        else:
            outcome = {"resolved": False, "reason": "ambiguous", "candidates": rows}

        if args.json:
            emit_json(outcome)
        elif outcome["resolved"]:
            t = outcome["task"]
            print(f"RESOLVED {t['repo']}/{t['task']}")
            print(f"path: {t['path']}")
            print(f"next: {t['next']}")
            if t["next_walkthrough"]:
                print(f"walkthrough: {t['next_walkthrough']}")
            if t["resume_here"]:
                print("resume here: " + t["resume_here"].replace("\n", " "))
        else:
            print(f"NOT RESOLVED ({outcome['reason']})")
            if outcome["candidates"]:
                print(render_table(outcome["candidates"], show_repo=False))
                print("Ask the user which task to resume.")
            else:
                print("Offer to start a new task.")
        return EXIT_OK if outcome["resolved"] else EXIT_FINDINGS

    rows = scan(paths.prd_root, None if args.all else paths.repo)
    if args.unfinished:
        rows = [r for r in rows if r["status"] not in {"done", "dropped"}]
    if args.json:
        emit_json({"prd_root": str(paths.prd_root), "tasks": rows})
    else:
        print(render_table(rows, show_repo=args.all))
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
