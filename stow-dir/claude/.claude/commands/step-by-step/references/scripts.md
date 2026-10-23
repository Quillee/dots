# Scripts reference

Five deterministic helpers in `scripts/` handle the parts of this skill that have exactly one correct answer: path resolution, filenames, link rewriting, and consistency checks. They exist so Claude does not re-derive these mechanics on every run.

**Run a script when you can. If you cannot run code, follow the manual procedure in SKILL.md and the other references.** The scripts report facts. Judgment calls (what to tell the user, whether to regenerate, what a scope change means) stay with Claude.

## Contents
- Requirements and conventions
- Which script, when
- list_tasks.py
- new_task.py
- validate_task.py
- check_drift.py
- rename_task_file.py
- Conventions the scripts rely on

## Requirements and conventions

- **Python 3.12, standard library only.** Nothing to install. The code avoids newer-only syntax, so it also runs on slightly older interpreters. Call it with `python3` (or `python` on Windows).
- **Run from anywhere.** Call scripts by path: `python3 <skill-dir>/scripts/<name>.py`. Scripts that need the repo find it with `git rev-parse --show-toplevel` from the current directory, falling back to the nearest ancestor containing `.git`.
- **Task argument.** Where a script takes `TASK`, pass either the task directory path or a bare task name (resolved under `prd/<repo>/`).
- **Common flags** on every script that locates paths: `--repo-root PATH`, `--prd-root PATH`, `--repo NAME`. `--json` prints machine-readable output.
- **Exit codes.** `0` ok, `1` findings (problems or drift; for `list_tasks.py --resume`, none or ambiguous), `2` usage error or refusal.
- **Never destructive by surprise.** `check_drift.py`, `validate_task.py`, and `list_tasks.py` only read. `new_task.py` never overwrites a walkthrough and overwrites a PRD only with `--force`. `rename_task_file.py` has `--dry-run`.

## Which script, when

| Moment | Script |
|---|---|
| Start of any run: where do things live? | `list_tasks.py --paths` |
| User says `list` or `list all` | `list_tasks.py [--all]` |
| User says `resume` or opens a fresh chat | `list_tasks.py --resume [name]`, then `check_drift.py` |
| Phase 2: PRD structure | `new_task.py --spec ... --prd-only`, then `validate_task.py --prd-only` |
| After Phase 3 (split approved, owners flipped in the PRD) | `new_task.py --sync` |
| Phase 4: walkthroughs written | `validate_task.py` |
| Any PRD change, and every resume | `check_drift.py` |
| A PRD change alters a task's dependencies | `rename_task_file.py`, then `check_drift.py` |

## list_tasks.py

```
python3 list_tasks.py                  tasks for the current repo
python3 list_tasks.py --all            tasks for every repo under prd/
python3 list_tasks.py --unfinished     hide done and dropped tasks
python3 list_tasks.py --paths          repo_root, repo, prd_root, and whether they exist
python3 list_tasks.py --resume [NAME]  decide which task to resume
```

- Listing prints one line per task: name, PRD status, `n/m done`, and the next step (for example `03 Token store (you), step 2 of 5`, `claude pass pending: 04`, or `complete`).
- The next user task is the first user-owned task that is unfinished, not blocked, and whose prerequisites are finished.
- `--paths` shows `prd_root_exists`. If it is false, `prd/` has not been created yet; give the one-time note about it being outside the repo when you first create it.
- `--resume` resolves to exactly one task (by name, by unique prefix or substring, or because only one unfinished task exists) and prints its path, next step, walkthrough, and "Resume here" text. Otherwise it prints the candidates and exits `1`: ask the user which one, or offer to start a new task.

## new_task.py

Creates structure. Claude supplies the content.

**Create mode**

```
python3 new_task.py --name rate-limiter --spec tasks.json [--title "Rate limiter"]
                    [--prd-name NAME] [--set own=more hints=none] [--prd-only]
                    [--force] [--dry-run] [--date YYYY-MM-DD] [--json]
```

Spec file:

```json
{
  "title": "Rate limiter",
  "settings": {"own": "core"},
  "tasks": [
    {"id": 1, "name": "Project wiring", "owner": "claude", "depends_on": [],
     "walkthrough": false, "notes": "Config and CI hooks only"},
    {"id": 2, "name": "Interfaces", "owner": "claude", "depends_on": [1], "walkthrough": true},
    {"id": 3, "name": "Token store", "owner": "you", "depends_on": [2]}
  ]
}
```

- `id` and `name` and `owner` are required. `depends_on` defaults to none. `status` defaults to `not-started`. `walkthrough` defaults to true for `you` and false for `claude`. Names may not contain `| [ ] # ^`.
- Settings start from the defaults, then the spec, then `--set`. Invalid values are refused.
- It writes `prd-<name>.md` (front matter with settings, the task table, a Mermaid tree with nodes first and edges after, the Next up callout, section headings with placeholders, and a change log line) and, unless `--prd-only`, a skeleton for each walkthrough.
- Dependency cycles, unknown prerequisites, and duplicate ids are refused before anything is written.
- Placeholders read `_(to be written)_`. `validate_task.py` warns until none are left.

**Sync mode**

```
python3 new_task.py --sync TASK [--dry-run] [--json]
```

Reads the PRD and creates a skeleton for every task whose Walkthrough cell links a file that does not exist yet. Use it after the split is approved: flip owners and add walkthrough links in the PRD table, then sync. Existing walkthroughs are untouched. Skeletons follow the settings in the PRD front matter (a user-owned task gets "Why this is yours" and hint callouts per `hints`).

## validate_task.py

```
python3 validate_task.py TASK [--prd-only] [--strict] [--check-stubs] [--repo-root PATH] [--json]
```

Checks structure and conventions, not content quality:

- PRD front matter keys, status values, dates, and recorded settings
- Task table shape, owners, statuses, unknown or self prerequisites, dependency cycles, and rows broken by an unescaped `|` in a wikilink
- The Mermaid tree matches the table (every task present, every edge matches a dependency)
- Required PRD sections, the Next up callout, leftover placeholders
- Walkthrough filenames, front matter, quoted wikilinks in YAML, links that resolve, `up` pointing at the PRD
- A "Resume here" callout, a `## Steps` section with checkbox steps, and a "Done when" on each step
- A `## Tests` section on every user-owned walkthrough (warning only). A missing or placeholder section means the task's stage has not been scaffolded yet
- Hint callouts are folded, and hints present or absent as `hints` requires
- `--check-stubs`: warns when an unfinished user-owned task has no `TODO(you) NN` marker anywhere in the repo

`--prd-only` validates just the PRD and does not require the linked walkthrough files to exist yet; use it right after writing the PRD, then run it again without the flag once walkthroughs are written. Errors fail the run. Warnings fail it only with `--strict`.

## check_drift.py

```
python3 check_drift.py TASK [--json]
```

Implements the drift check from `resume-and-regeneration.md`, with the PRD as the source of truth:

- every walkthrough the PRD links exists, and no unlisted walkthrough exists
- ids and names match
- owner and status match
- the PRD's "Depends on", the filename chain, `depends_on`, and `blocks` agree
- a `done` task has no unchecked steps; a `not-started` task has no checked steps (reported as `progress-ahead`: ask the user which side is right before changing anything)
- every wikilink resolves, and PRD links point at the files that actually exist
- warnings for a stale Next up callout and an inconsistent PRD status

Exit `1` means drift. Summarize it for the user, propose regeneration, and wait for approval. Do not regenerate on your own.

## rename_task_file.py

```
python3 rename_task_file.py TASK --id N [--depends N ... | none] [--slug new-slug]
                            [--vault] [--dry-run] [--json]
```

Renames walkthrough N so its filename matches the PRD's dependencies, then rewrites every wikilink to it (including links with anchors and escaped pipes in tables, keeping each alias). By default the new dependency chain is read from the PRD; `--depends` and `--slug` override it. `--vault` rewrites links across all of `prd/` instead of just the task folder. It refuses if the target filename exists or if more than one walkthrough claims the number.

After renaming, the file's own `depends_on` and `blocks` front matter may still be out of date. Run `check_drift.py`, and regenerate that walkthrough if it reports dependency drift.

## Conventions the scripts rely on

- **Link identity.** Every wikilink in `depends_on`, `blocks`, and the PRD table carries an alias in the form `NN Name`. The leading number is how the scripts know which task a link refers to, so a link to a task without a walkthrough can point at the PRD: `"[[<repo>/<task-name>/prd-<prd-name>#Tasks|01 Project wiring]]"`.
- **Filenames.** `NN-slug.md`, or `NN.MM[.KK]-slug.md` where the extra numbers are direct prerequisites, in the order listed in the PRD. The PRD is `prd-<name>.md`. A file that matches neither pattern is reported.
- **Tables.** Wikilinks inside table cells escape the pipe: `[[path\|NN Name]]`.
- **Front matter.** A small YAML subset: scalars, lists (inline or dashed), and a one-level `settings` map. Wikilinks must be quoted.
- **Next up.** The callout names the first eligible user-owned task; while its prerequisites are unfinished it reads "After Claude's scaffolding: ..." and still names that task.
