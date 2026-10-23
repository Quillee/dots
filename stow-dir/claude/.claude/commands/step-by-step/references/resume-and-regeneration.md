# Resume, drift check, and regeneration

This is what makes the workflow survive across Claude instances. A fresh instance has no memory of the earlier chat, so everything it needs must be recoverable from the files in `task_dir`.

## Contents
- Resume procedure
- Drift check
- Regeneration
- Scope changes
- Changing an owner or dropping a task
- Re-orientation format

## Resume procedure

1. **Locate `task_dir`.** Resolve `repo_root`, `repo`, and `prd_root` as in SKILL.md. List `prd_root/<repo>/*/prd-*.md`.
   - Name given: go to that task.
   - Exactly one unfinished task (PRD `status` is `planning` or `in-progress`): go to it.
   - Several: list them, one line each (name, status, next step), and ask which.
   - None: say so, and offer to start a new task.
2. **Read the PRD.** Front matter (settings, status), the task table, the dependency tree, and the "Next up" callout. Honor the recorded settings; do not fall back to defaults.
3. **Run the drift check** (below). If drift exists, report it and propose regeneration before continuing.
4. **Pick the starting point.** The first unfinished user-owned task whose prerequisites are done, in ID order. If a Claude task is unblocked by finished user work, offer the short follow-up pass first.
5. **Open that walkthrough** and read its "Resume here" callout, its Tests section, and the checkbox state.
   - Tests section empty or missing: the stage was never scaffolded. Run Phase 5 for that task before anything else (re-check the walkthrough against the code first).
   - All steps checked: the user is done. Run Phase 7 (close the stage).
   - Otherwise: the stage is scaffolded and in progress. Continue from "Resume here".
6. **Re-orient the user** in 3 to 4 lines (format below). Do not re-scan the whole codebase; read only what the walkthrough's Context and Contract point to.

## Drift check

Compare the PRD against the walkthrough files in `task_dir`. `scripts/check_drift.py` implements every check below; run it when you can, and follow this list by hand when you cannot. Check:

- **Existence:** every task the PRD marks as having a walkthrough has a file; every walkthrough file corresponds to a PRD task.
- **Identity:** each file's `id` and `name` match the PRD row.
- **Dependencies:** the PRD's "Depends on", the filename's numeric chain, and the `depends_on` front matter agree. The `blocks` lists are the inverse.
- **Owner and status:** each file's `owner` and `status` match the PRD row.
- **Progress consistency:** a task marked `done` has no unchecked steps; a task marked `not-started` has no checked steps.
- **Links:** every wikilink in the PRD table and walkthrough front matter resolves to an existing file.

Any mismatch is drift. **The PRD wins.** Summarize the differences in a short list, say which walkthroughs would change, and wait for the user's go-ahead before regenerating.

If a walkthrough shows work the PRD does not reflect (for example, checked steps under `not-started`), do not discard it. Ask the user which side is right, since the user may have progressed without telling Claude. Then fix the PRD (with approval) or the walkthrough accordingly.

## Regeneration

Regeneration rebuilds a walkthrough from the PRD without losing the user's work.

1. Read the current walkthrough fully before touching it.
2. Tell the user what will change, in plain terms: steps added, removed, or reworded; contract changes; renamed or re-linked files. Wait for approval.
3. Build the new walkthrough from the PRD row and `walkthrough-template.md` (use a subagent per file when available; otherwise inline).
4. **Carry over:**
   - Checked steps stay checked where the step still exists. Match by meaning, not just by number.
   - All open questions are carried over, with resolved ones still marked resolved and their answers intact.
   - The Log section, with a new line recording the regeneration and why.
   - Any hints the user or a previous instance added, unless the PRD change invalidates them.
5. **Flag, never silently drop.** If a checked step or an answered question no longer fits after the change, keep it in a `> [!warning] Invalidated by PRD change` callout with an explanation, and let the user decide.
6. Update the "Resume here" callout to the first unchecked step.
7. If filenames changed because dependencies changed, rename the file and update every wikilink (see `obsidian-conventions.md`, Renames).
8. Re-run the drift check to confirm everything agrees, and note the regeneration in the PRD Change Log.

## Scope changes

If the user's answer to an open question, or any new decision, changes scope (tasks added or removed, owners flipped, dependencies altered, user stories changed):

1. Describe the proposed PRD edit in plain terms.
2. Wait for approval.
3. Edit the PRD (task table, Mermaid tree, relevant sections), bump `updated`, and add a Change Log line.
4. Run the drift check and regenerate the affected walkthroughs.

Never edit the PRD's plan on your own initiative. Status columns and the "Next up" callout are the only things Claude updates without asking, because they just record what happened.

## Changing an owner or dropping a task

- **Owner flipped to you:** the task now needs hints and a "Why this is yours" section. Create or regenerate its walkthrough, and replace Claude's finished work with a stub only if the user wants to redo it.
- **Owner flipped to claude:** keep the walkthrough only if it is still painful to resume cold; drop the hints. Claude does the work in a follow-up pass.
- **Dropped:** set the status to `dropped` in the PRD and the walkthrough. Keep the file for history. Check that no other task depends on it; if one does, raise it with the user.

## Re-orientation format

Three to four lines, plain, no recap of the whole project:

```
Picking up "<task-name>" in <repo>. Done so far: <one line>.
Next is 03 Token store (yours), step 2 of 5: <what that step is>. Tests: <N red, M green> via `<command>`.
<Anything that changed or needs attention: an open question, a blocked task, drift.>
Ready when you are. Say "hint" if you want one.
```

If the user has been away, add one line on what may have changed in the repo since the last update, but only if you checked.
