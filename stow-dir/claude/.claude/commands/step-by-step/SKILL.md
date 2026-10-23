---
name: step-by-step
description: Copilot workflow where Claude does the scaffolding and the user stays in the loop by completing the important parts themselves. Interviews the user grill-me style, writes an Obsidian-compatible PRD (task table plus dependency tree) to prd/REPO/TASK-NAME/ one level above the repo, splits tasks between Claude and the user, writes walkthroughs with graduated hints that carry over across Claude instances, then works test-first in stages: for each task the user owns, Claude builds only what that task needs, writes failing tests that define done, and stops so the user can implement it, then reviews against the tests and moves to the next stage. Use whenever the user types /step-by-step, says "keep me in the loop", "copilot mode", "you scaffold, I'll build", "walk me through it", "I want to stay hands-on", "resume my task", or "where did we leave off", or hands over a sizeable build and says they want to follow along or understand it, even if they never name the skill. Options - grill, own, hints, stop, level, list, resume. Not for quick one-off requests where the user just wants it done.
---

# Step-by-Step

A copilot workflow. Claude does the scaffolding; the user does the parts that matter. The point is that the user can follow what is happening and stays the author of the important decisions, instead of watching Claude sprint to the end.

## Why this skill exists

Claude is fast, and speed makes it hard to follow along. The user loses the thread, stops understanding the code, and stops being the person who made the key calls. Everything below serves three goals:

1. **Pace.** Claude works one step at a time. It prepares exactly one user-owned task, stops, and waits. It never scaffolds ahead of the user.
2. **Feedback.** Tests are the definition of done. Claude writes real, failing tests before the user starts, so the user gets feedback by running them, without Claude in the loop. Claude's review adds the qualitative judgment tests cannot.
3. **Continuity.** All state lives in plain markdown files, so a fresh Claude instance (or the user after a week away) can resume without re-deriving context. Nothing important lives only in the chat.

Keep these goals in mind when a situation isn't covered here. If a choice would speed Claude up at the cost of the user's understanding, take the slower path.

## Where everything lives

- `repo_root`: `git rev-parse --show-toplevel` (fall back to the nearest ancestor containing `.git`, then the current directory).
- `repo`: the basename of `repo_root`.
- `prd_root`: **the directory named `prd` exactly one level above `repo_root`**, i.e. `<parent of repo_root>/prd/`. Create it if missing. The first time you create it, tell the user once: it sits outside the repo so the repo's git does not track it, and `prd/` is meant to be opened as an Obsidian vault.
- `task_dir`: `prd_root/<repo>/<task-name>/`. Create it for a new task. `<task-name>` is a short kebab-case slug (2 to 4 words) generated from the user's goal. If it already exists, ask whether to resume it or pick a new name.

To resolve these paths deterministically, run `scripts/list_tasks.py --paths`; it also reports whether `prd_root` exists yet, so you know whether to give the one-time note about it.

Files inside `task_dir`:

| File | Purpose |
|---|---|
| `prd-<prd-name>.md` | The single source of truth: problem, solution, task table with owners, dependency tree, status, and the rest of the PRD. |
| `NN-<slug>.md` | Walkthrough for task NN with no prerequisites. |
| `NN.MM-<slug>.md` | Walkthrough for task NN that depends on task MM. Several prerequisites chain on: `05.02.03-<slug>.md`. |

Numbers are zero-padded so files sort correctly, and ordered so prerequisites get lower numbers where possible. There is no separate task-list file. The filename lists direct prerequisites only; if a task has more than three, it is probably too big, so split it. The full dependency graph lives in the PRD.

## Scripts

Deterministic helpers live in `scripts/`, next to this file. Run them as `python3 <skill-dir>/scripts/<name>.py`. They use only the Python 3.12 standard library, so they work wherever Python does, and each prints plain text (or JSON with `--json`). **Run a script when you can. If you cannot run code, follow the manual procedure in the matching section instead.** Usage, flags, and exit codes are in `references/scripts.md`.

| Script | Use it for |
|---|---|
| `list_tasks.py` | Resolving paths (`--paths`), `list` and `list all`, and choosing a task to resume (`--resume`) |
| `new_task.py` | Creating `task_dir` with the PRD and walkthrough skeletons (`--spec`), and creating any missing skeletons later (`--sync`) |
| `validate_task.py` | Checking that a task folder is well formed, after writing the PRD and after writing walkthroughs |
| `check_drift.py` | The drift check, on every resume and after any PRD change |
| `rename_task_file.py` | Renaming a walkthrough when its dependencies change, and rewriting every wikilink to it |

Scripts report facts; you still make the judgment calls. When one reports drift or a scope change, tell the user and wait for approval, exactly as described below.

## Options

Parse options from the invocation. Accept both `key=value` and plain words ("quick grill, I own more, no hints, stop after the plan, I'm new to this"). Anything that is not an option is the user's goal. Unspecified options take the default. Record the final settings in the PRD front matter and state them to the user in one line before starting.

| Option | Values | Default | Effect |
|---|---|---|---|
| `grill` | `full` / `quick` / `skip` | `full` | Depth of the interview before the PRD |
| `own` | `core` / `more` / `most` | `core` | How much lands on the user |
| `hints` | `none` / `graduated` / `full` | `graduated` | Hints in walkthroughs |
| `stop` | `prd` / `plan` / `scaffold` | `scaffold` | Where Claude pauses |
| `level` | `new` / `familiar` / `expert` | `familiar` | Step granularity and explanation depth |
| `list` | `list` or `list all` | n/a | Show tasks for this repo, or for every repo |
| `resume` | optional task name | n/a | Pick up an existing task |

Read `references/options.md` for precise definitions of every value and how to parse natural-language phrasings.

## Routing

1. `list`: scan `prd_root/<repo>/*/prd-*.md` (all repos with `list all`), read the front matter and task table, and print one line per task: name, status, next step. Then stop. Run `scripts/list_tasks.py` (add `--all` for `list all`) to do this.
2. `resume`, "where did we leave off", or similar: go to **Resume**.
3. A build goal: start a new task at **Phase 1**.
4. Nothing but the bare command: if unfinished tasks exist for this repo, show them and ask which to resume; otherwise ask what the user wants to build.

## Workflow for a new task

### Phase 1: Grill

Follow the grill-me discipline: interview relentlessly, **one question at a time**, walk the decision tree in dependency order, and give a recommended answer with every question. If the codebase can answer a question, explore it instead of asking.

Beyond the usual design questions, make sure the grill settles: the goal and what "done" looks like, constraints, where the user wants to learn versus just get it done (this calibrates `own`), and the test seams.

- `grill=full`: exhaust the tree.
- `grill=quick`: 3 to 6 questions, only on branches where a wrong guess would be expensive. Record everything else as explicit assumptions in the PRD.
- `grill=skip`: the user brought a spec or has already decided. Read it, explore the codebase, ask only about true blockers, and record remaining gaps as assumptions and open questions in the PRD.

### Phase 2: PRD

Synthesize; do not re-interview. Explore the repo, use its domain vocabulary, respect any ADRs in the area. Sketch the seams where the work will be tested (prefer existing seams, use the highest seam possible), find the command that runs the tests for each area, and check the seams with the user in one short question. Record the seams and commands under Testing Decisions; the stages depend on them. Then write `prd-<prd-name>.md` from `references/prd-template.md`, following `references/obsidian-conventions.md`.

The PRD must contain the task table (ID, name, owner, dependencies, status, walkthrough link, notes) and a Mermaid dependency tree. Keep Implementation Decisions free of file paths and code snippets, which go stale quickly.

To get the structure right every time, write the task list to a small JSON spec and run `scripts/new_task.py --name <task-name> --spec <spec.json> --prd-only`. It creates `task_dir`, the PRD front matter, the task table, the Mermaid tree, and the Next up callout, so you only write the prose sections (replace every `_(to be written)_` placeholder). Manual fallback: write the PRD from `references/prd-template.md`. When the PRD is complete, run `scripts/validate_task.py <task_dir> --prd-only` (the walkthrough files do not exist yet).

If this is the first PRD for this repo, mention once that `prd/` is not tracked by the repo's git.

`stop=prd`: after Phase 3 is approved, brief the user and stop.

### Phase 3: Split approval

Propose the owner of every task and show the table. Apply the ownership rule for the current `own` setting (see `references/options.md`). The user can flip any owner. Do not proceed until they approve. Update the PRD with the approved split.

The core test: if a wrong choice would teach the user something, or they would need to explain it in a code review, it is theirs. Boilerplate, setup, wiring, interface definitions, and mechanical code are Claude's.

### Phase 4: Walkthroughs

A task gets a walkthrough file if it would be painful to resume cold in a fresh chat: could a new Claude instance, or the user after a week away, pick it up without re-deriving context? When in doubt for a user-owned task, create one, because hints live in walkthroughs. Smaller tasks stay as a row in the PRD with context in the Notes column, plus a `TODO(you)` stub and its failing tests in the code.

First run `scripts/new_task.py --sync <task_dir>` to create a skeleton for every walkthrough the PRD links but that does not exist yet, with correct filenames, links, and front matter. Then fill them in. Writing good walkthroughs and hints takes real thought, so **use subagents**: one per walkthrough, in parallel. Give each: the PRD path, its task ID, the settings, `references/walkthrough-template.md`, `references/obsidian-conventions.md`, and where to look in the codebase. If subagents are unavailable, write them inline one at a time. The main thread then runs `scripts/validate_task.py <task_dir>` and fixes every error it reports. (Manual fallback: verify filenames match the dependency convention, front matter is complete, wikilinks resolve, the dependency graph has no cycles, and the PRD table links match the files that exist.)

What a good walkthrough has: small observable steps each with a "done when"; the stub contract the user's code must satisfy; a Tests section naming the tests that define done and the command that runs them; graduated hints (nudge, then pointer, then worked example, kept folded); open questions as callouts; and a "Resume here" marker at the top. Calibrate depth to `level`.

Walkthroughs for later tasks are provisional. Earlier stages change contracts, so each stage re-checks its walkthrough against the code before scaffolding (Phase 5, step 1).

`stop=plan`: brief the user and stop here.

### Phase 5: Scaffold the next stage

From here the work is a loop of **stages**. A stage prepares exactly one user-owned task, then stops. The aim is that each stage ends in a state the user can run, test, and commit on its own.

**Pick the target.** The first unfinished user-owned task, in ID order, whose user-owned prerequisites are done. Call it U. If none remains, skip to "When no user tasks remain" in Phase 7.

1. **Re-check U's walkthrough against the code as it is now.** If its Contract or steps no longer match (an earlier stage changed something), update the walkthrough and tell the user what changed. If the change alters scope, follow "Scope changes" instead.
2. **Build U's Claude-owned prerequisites, for real.** Working code, written test-first: write the tests, watch them fail, implement, watch them pass. Build only these. Claude-owned tasks that U does not need wait for the stage where they become a prerequisite, or run in the final stage. The user can ask for one earlier.
3. **Write the smallest stub for U.** Just enough surface (signatures, types, exports) for the tests to compile. Bodies fail loudly, in the language's idiom (`throw new NotImplementedException(...)`, `throw new Error(...)`, `raise NotImplementedError(...)`), with the marker:

   `TODO(you) 03: one-line description. See prd/<repo>/<task-name>/03-<slug>.md`

   A stub is never inert: no logging, no plausible return values, no pass-through. Do not wire the stub into the running app or any production path. Wiring is a Claude-owned task that runs after U is green, so an unfinished stub cannot affect anything.
4. **Write the tests that define U.** They are red until the user finishes. Rules:
   - Real assertions at the agreed seam, testing behavior, not implementation. Enough to define done, not exhaustive.
   - Never skipped, pending, or `todo`. A skipped test is silent; a red test is feedback.
   - Red for the right reason: failing on the stub's `TODO(you)` or on an assertion, not on a compile, import, or setup error.
   - Tests are Claude's by default, including those for user-owned tasks, unless the user says otherwise.
   - Judgment calls the walkthrough leaves open (its open questions) are not asserted. Test only what the contract fixes.
5. **Run them.** Confirm the new tests fail for the right reason, and run the surrounding suite for a baseline. Note any failures that predate this stage so they are not mistaken for the stage's.
6. **Update the files.** Fill the walkthrough's Tests section (the command, each red test, what it proves), set "Resume here" to step 1, tick Claude's steps, update statuses in the PRD and walkthrough front matter, and add a Log line.

Mark a task **blocked** only if it truly cannot proceed without the user's real implementation, and record why.

### Phase 6: Brief and stop

When the stage is scaffolded, give **one brief** and stop. Keep it short:

- what Claude built this stage (a line or two per task, linked)
- **where to start**: U, the walkthrough link, and the step number
- **the test command**, and which tests are red and why
- **suggested commit checkpoint**: what is committable now (for example: Claude's prerequisites plus the stub and red tests) and a suggested message. Whether to commit red tests is the user's call.
- the settings used

Then end the turn. Do not start U. Do not commit unless asked.

### Phase 7: Close the stage

When the user says they are done, asks for a review, or reports their tests are green:

1. **Run the stage's tests** and the surrounding suite. Report the result. If tests are red, point at the failing test and the relevant hint level. Do not fix the user's code unless asked. If a test itself is wrong (Claude owns the tests), fix it and say why.
2. **Review the qualitative side.** Tests cannot see: adherence to the walkthrough's contract and open-question decisions, naming and readability, error handling, security and performance concerns, edge cases the tests do not cover, and consistency with the surrounding code. Report findings as suggestions. The user decides what to act on.
3. **Close out.** Tick the steps, mark U `done` in the PRD and walkthrough, update "Next up", and add Log and Change Log lines.
4. **Suggest a commit checkpoint:** what changed, that the tests are green, and a suggested message.
5. **Start the next stage** (Phase 5). Claude-owned tasks that U's completion unblocked run in it only if they are prerequisites of the next target (for example, wiring that a later manual-verification task depends on); the rest wait for the final stage. Then brief and stop again.

**When no user tasks remain:** do the remaining Claude-owned tasks test-first, run the full suites, do a final qualitative review of the whole change, set the PRD `status: done`, and summarize.

## While the user works

- **The tests are the feedback loop.** The user can run them without Claude. Do not run them for the user unless asked.
- **Hints live in the walkthrough.** If the user is stuck, point to the next unopened hint level instead of improvising. If the hints were not enough, improve the walkthrough by adding a better hint, so the next instance benefits.
- **Write the user's solution only if they explicitly ask.** Then do it, and note in the walkthrough that you did.

## Resume

Run when the user says resume, or opens a fresh chat on an existing task. Read `references/resume-and-regeneration.md` for the full procedure. In short:

1. Locate `task_dir` (ask which one if several are unfinished). `scripts/list_tasks.py --resume [name]` resolves it.
2. Read the PRD.
3. **Drift check**: do the PRD and the walkthroughs still agree? If not, the PRD wins; propose regeneration and wait for approval. Run `scripts/check_drift.py <task_dir>` to do the check; it exits non-zero when drift exists.
4. Find the first unfinished user-owned task, open its walkthrough, and read its "Resume here" line and Tests section. If the Tests section is empty, its stage was never scaffolded: run Phase 5 for it before anything else. If all its steps are checked, run Phase 7.
5. Give a 3 to 4 line re-orientation: what the task is, what is done, what is next. Do not re-scan the whole codebase.

## Source of truth and regeneration

The PRD is the source of truth. If a walkthrough disagrees, regenerate the walkthrough from the PRD, preserving completed steps and open questions, flagging anything the change invalidates, and telling the user what will change before overwriting. If a user's answer to an open question changes scope, propose a PRD edit and wait for approval first. Details in `references/resume-and-regeneration.md`.

If a PRD change alters a task's dependencies, its filename must change too. `scripts/rename_task_file.py <task_dir> --id N` renames the walkthrough to match the PRD and rewrites every wikilink to it (use `--dry-run` first). The renamed file's own front matter still needs regenerating.

Task status values: `not-started`, `in-progress`, `blocked`, `done`, `dropped`. Task-level status lives in the PRD table; step-level progress lives in walkthrough checkboxes. Keep the two consistent.

## Obsidian compliance

All files are plain markdown that works in Obsidian with core features only: path-qualified wikilinks with aliases, YAML properties, Mermaid, checkbox steps, `[!question]` callouts for open questions, and folded `[!hint]-` callouts for hints. No Dataview or other plugin syntax. Read `references/obsidian-conventions.md` before writing any file.

## Things to avoid

- Racing ahead. Every stage ends at the brief, always. Never scaffold for a user task beyond the next one.
- Skipped, pending, or `todo` tests standing in for unfinished work. Tests are red, not hidden.
- Inert or pass-through stubs, and wiring a stub into anything that runs. Unfinished work fails loudly and is not reachable.
- Committing without being asked. Suggest checkpoints; the user commits.
- Taking a user-owned task because it looks easy. The user decides what is theirs.
- Letting the PRD and walkthroughs diverge silently.
- Leaving state only in the chat. If a future instance would need to know it, it goes in a file.
- Ceremony for small work. If the user just wants a quick thing done, do not run this workflow.
