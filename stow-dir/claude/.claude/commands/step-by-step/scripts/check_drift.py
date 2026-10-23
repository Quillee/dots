#!/usr/bin/env python3
"""Drift check: does the PRD still agree with the walkthrough files?

The PRD is the source of truth. This script compares it against every
walkthrough in a task directory and reports each mismatch. It only reads files.

Usage:
    python3 check_drift.py TASK_DIR_OR_NAME [--json]

Exit codes: 0 no drift (warnings allowed), 1 drift found, 2 usage error.
"""
from __future__ import annotations

import argparse
import sys

sys.dont_write_bytecode = True  # keep the skill folder free of __pycache__

from _common import (
    EXIT_FINDINGS, EXIT_OK, FINISHED, Findings, add_path_args, dependents,
    emit_json, link_id, link_ids, load_task_dir, locate_task, next_focus, pad,
    resolve_link, setup_output, wikilinks,
)


def check(td) -> Findings:
    f = Findings()
    prd = td.prd
    if prd is None:
        f.error("prd", td.prd_problem or "PRD could not be read")
        return f

    tasks = {t.id: t for t in prd.tasks}
    by_id: dict = {}
    for w in td.walkthroughs:
        by_id.setdefault(w.file_id, []).append(w)

    for tid, files in by_id.items():
        if len(files) > 1:
            f.error("existence", "more than one walkthrough file: " + ", ".join(x.path.name for x in files), tid)

    # PRD-level problems that make comparison unreliable.
    for issue in prd.table_issues:
        f.error("prd", issue)
    ids_seen: set = set()
    for t in prd.tasks:
        if t.id in ids_seen:
            f.error("prd", "duplicate task number in the PRD table", t.id)
        ids_seen.add(t.id)

    for t in prd.tasks:
        files = by_id.get(t.id, [])
        w = files[0] if files else None

        # Existence and link target
        if t.walkthrough_target:
            if w is None:
                f.error("existence", f"PRD links a walkthrough ({t.walkthrough_target}) but no file exists", t.id)
            else:
                stem = t.walkthrough_target.rsplit("/", 1)[-1]
                stem = stem[:-3] if stem.endswith(".md") else stem
                if stem != w.stem:
                    f.error("stale-link", f"PRD links '{stem}' but the file is '{w.stem}'", t.id)
        elif w is not None:
            f.error("existence", f"PRD says no walkthrough, but {w.path.name} exists", t.id)

        if w is None:
            continue

        # Identity
        fm_id = w.fm.get("id")
        if fm_id != w.file_id:
            f.error("identity", f"front matter id is {fm_id!r}, filename says {w.file_id}", t.id)
        fm_name = str(w.fm.get("name", "")).strip()
        if fm_name.lower() != t.name.strip().lower():
            f.error("identity", f"name is '{fm_name}' in the walkthrough, '{t.name}' in the PRD", t.id)

        # Owner and status
        if str(w.fm.get("owner", "")).lower() != t.owner:
            f.error("owner", f"owner is '{w.fm.get('owner')}' in the walkthrough, '{t.owner}' in the PRD", t.id)
        if str(w.fm.get("status", "")).lower() != t.status:
            f.error("status", f"status is '{w.fm.get('status')}' in the walkthrough, '{t.status}' in the PRD", t.id)

        # Dependencies: PRD vs filename chain vs front matter
        prd_deps = set(t.depends)
        if set(w.file_deps) != prd_deps:
            f.error("dependencies", f"filename lists {_fmt(w.file_deps)}, PRD lists {_fmt(prd_deps)}", t.id)
        fm_deps = {i for i in link_ids(w.fm.get("depends_on", [])) if i is not None}
        if fm_deps != prd_deps:
            f.error("dependencies", f"depends_on lists {_fmt(fm_deps)}, PRD lists {_fmt(prd_deps)}", t.id)
        fm_blocks = {i for i in link_ids(w.fm.get("blocks", [])) if i is not None}
        expected_blocks = set(dependents(prd.tasks, t.id))
        if fm_blocks != expected_blocks:
            f.error("dependencies", f"blocks lists {_fmt(fm_blocks)}, PRD implies {_fmt(expected_blocks)}", t.id)

        # Progress
        checked = sum(1 for s in w.steps if s.checked)
        total = len(w.steps)
        if t.status == "done" and total and checked < total:
            f.error("progress", f"PRD says done but {total - checked} of {total} steps are unchecked", t.id)
        if t.status == "not-started" and checked:
            f.error(
                "progress-ahead",
                f"PRD says not-started but {checked} of {total} steps are checked. Work may have been done "
                "without updating the PRD: ask the user which side is right before changing anything",
                t.id,
            )
        if t.status == "in-progress" and total and checked == total:
            f.warn("progress", "all steps are checked but the PRD still says in-progress", t.id)

        # Location sanity
        if str(w.fm.get("repo", "")) not in {"", td.dir.parent.name}:
            f.warn("location", f"front matter repo '{w.fm.get('repo')}' differs from folder '{td.dir.parent.name}'", t.id)

    # Walkthroughs the PRD does not know about
    for wid, files in by_id.items():
        if wid not in tasks:
            f.error("existence", f"{files[0].path.name} has no matching task in the PRD", wid)

    # Every wikilink in the PRD and walkthroughs must resolve
    for source, text in [(prd.path.name, prd.text)] + [(w.path.name, w.text) for w in td.walkthroughs]:
        for target, _alias in wikilinks(text):
            if not resolve_link(target, td.prd_root):
                owner_id = next((w.file_id for w in td.walkthroughs if w.path.name == source), None)
                f.error("link", f"{source}: wikilink does not resolve: [[{target}]]", owner_id)

    # Next up callout
    expected, _eligible = next_focus(prd.tasks)
    if expected is None:
        if prd.next_up_link:
            f.warn("next-up", "the 'Next up' callout names a task but no user-owned task is left")
    elif prd.next_up_link is None:
        f.warn("next-up", f"no 'Next up' callout; expected task {pad(expected.id)}")
    else:
        named = link_id(*prd.next_up_link)
        if named != expected.id:
            f.warn("next-up", f"'Next up' names task {named}, expected task {pad(expected.id)}")

    # Overall PRD status
    live = [t for t in prd.tasks if t.status not in FINISHED]
    prd_status = str(prd.fm.get("status", ""))
    if prd.tasks and not live and prd_status != "done":
        f.warn("prd-status", f"every task is finished but the PRD status is '{prd_status}'")
    if live and prd_status == "done":
        f.warn("prd-status", "the PRD status is 'done' but some tasks are unfinished")
    return f


def _fmt(values) -> str:
    items = sorted(values)
    return "[" + ", ".join(pad(i) for i in items) + "]" if items else "none"


def main(argv=None) -> int:
    setup_output()
    ap = argparse.ArgumentParser(description="Check that the PRD and walkthroughs agree (the PRD wins).")
    ap.add_argument("task", help="task directory path, or a task name under prd/<repo>/")
    add_path_args(ap)
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    args = ap.parse_args(argv)

    prd_root, task_dir = locate_task(args)
    td = load_task_dir(task_dir, prd_root)
    findings = check(td)

    if args.json:
        emit_json({"task_dir": str(task_dir), **findings.to_dict()})
    else:
        title = f"Drift check: {td.prefix}"
        print(findings.render(title, "DRIFT", "No drift: the PRD and walkthroughs agree."))
        if findings.errors:
            print("\nThe PRD wins. Summarize this for the user, propose regeneration, and wait for approval.")
    return EXIT_FINDINGS if findings.errors else EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
