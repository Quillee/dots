# step-by-step

A copilot workflow for Claude. Claude does the scaffolding; you complete the important parts, so you stay in the loop and stay the author of the decisions that matter.

Claude is fast, and speed makes it hard to follow along. This skill slows the *right* things down. Claude stops at natural handoff points, briefs you once, and leaves everything in plain markdown files so any Claude instance (or you, after a week away) can pick up exactly where things stopped.

## Contents

- [How it works](#how-it-works)
- [Quick start](#quick-start)
- [Options](#options)
- [Examples](#examples)
- [Where files live](#where-files-live)
- [File naming](#file-naming)
- [What each file contains](#what-each-file-contains)
- [Resuming across Claude instances](#resuming-across-claude-instances)
- [PRD is the source of truth](#prd-is-the-source-of-truth)
- [Obsidian setup](#obsidian-setup)
- [Installing](#installing)
- [Design decisions](#design-decisions)
- [Package contents](#package-contents)

## How it works

Seven phases. The first four plan the work; phases 5 to 7 then repeat as a loop of **stages**, one per task you own:

1. **Grill.** Claude interviews you one question at a time, with a recommended answer on each, in the style of your grill-me skill. If the codebase can answer a question, Claude explores it instead of asking.
2. **PRD.** Claude writes a PRD from what it learned (modeled on your to-prd skill), including the task table and a dependency tree. It checks the test seams with you first.
3. **Split approval.** Claude proposes which tasks are Claude's (**scaffold**) and which are yours (**you own**). You approve or flip any of them before work starts.
4. **Walkthroughs.** Tasks that would be painful to resume cold get a walkthrough file with steps, a contract, graduated hints, and open questions. Subagents write these in parallel.
5. **Scaffold the next stage.** For the next task you own, Claude builds only its prerequisites (test-first), writes a minimal stub that throws a `TODO(you)` marker, and writes real failing tests that define done. It does not wire the stub into anything that runs, and it does not scaffold ahead for later tasks.
6. **Brief and stop.** Claude tells you which walkthrough step to start on, the command that runs the tests, which ones are red, and a suggested commit checkpoint. Then it stops. It does not start your task and does not commit.
7. **Close the stage.** When you are done, Claude runs the tests and reviews the qualitative side that tests cannot see (contract, naming, error handling, edge cases), updates the PRD, suggests a commit checkpoint, then scaffolds the next stage and stops again.

The tests are your feedback loop: you can run them yourself, any time, without Claude. Claude's review adds judgment on top of them.

## Quick start

```
/step-by-step I want to build a rate limiter for our public API
```

That runs everything with the defaults. Add options anywhere in the message to change behavior (see below).

## Options

Every option has a default, so the bare command always works. Options can be written as `key=value` or as plain words in your sentence. Claude records the final settings in the PRD front matter and states them in one line at the start.

| Option | Values | Default | What it does |
|---|---|---|---|
| `grill` | `full` / `quick` / `skip` | `full` | How deep the interview goes before the PRD. `skip` is for when you've already thought it through and pasted a spec. |
| `own` | `core` / `more` / `most` | `core` | How much lands on your plate. `core` is only judgment calls and central logic, `more` adds integration and anything you'd need to maintain, `most` leaves Claude only boilerplate and wiring. |
| `hints` | `none` / `graduated` / `full` | `graduated` | Hints in walkthroughs. `none` gives a bare steps list, `graduated` is nudge, then pointer, then worked example, and `full` adds a folded reference solution near the top. |
| `stop` | `prd` / `plan` / `scaffold` | `scaffold` | Where Claude pauses. `prd` stops after the PRD and split are approved, `plan` stops after walkthroughs are written but before any scaffolding, and `scaffold` (the default) scaffolds one stage, briefs you, and stops again after every later stage. |
| `level` | `new` / `familiar` / `expert` | `familiar` | How fine-grained the steps are and how much concept explanation goes in. `new` explains the why behind each step, `expert` keeps it terse. |
| `list` | `list` or `list all` | current repo | Shows tasks with status and next step. `list all` covers every repo. |
| `resume` | optional task name | n/a | Picks up an existing task. |

Details on each value and the natural-language phrasings Claude recognizes are in `references/options.md`.

## Examples

Every example below uses the default values, so they all behave the same. They show the different ways to write them.

**Fully explicit, every default written out**

```
/step-by-step grill=full own=core hints=graduated stop=scaffold level=familiar I want to build a rate limiter for our public API
```

**Bare command, same result.** Omitted options fall back to the defaults.

```
/step-by-step I want to build a rate limiter for our public API
```

**Plain words instead of key=value**

```
/step-by-step full grill, I own the core, graduated hints, stop after scaffolding, I'm familiar with this area. I want to build a rate limiter for our public API
```

**Each option on its own, at its default**

| Option | Example |
|---|---|
| `grill` | `/step-by-step grill=full I want to build a rate limiter` |
| `own` | `/step-by-step own=core I want to build a rate limiter` |
| `hints` | `/step-by-step hints=graduated I want to build a rate limiter` |
| `stop` | `/step-by-step stop=scaffold I want to build a rate limiter` |
| `level` | `/step-by-step level=familiar I want to build a rate limiter` |

**Resume and list.** These are actions, so they have no default value. `list` defaults to the current repo.

```
/step-by-step list
/step-by-step list all
/step-by-step resume
/step-by-step resume rate-limiter
```

A bare `resume` with several unfinished tasks in the repo shows the list and asks which one. With exactly one unfinished task, it goes straight there.

**Non-default examples**

```
/step-by-step grill=quick own=more hints=none stop=plan level=expert I want to add SSO
/step-by-step skip the grill, I'll paste the spec. I own most of it, stop after the PRD.
/step-by-step I'm new to this, explain the why. Full hints please. I want to build a CLI tool.
```

**What happens end to end with the defaults**

1. Full grill, one question at a time, with a recommendation on each.
2. PRD written to `prd/<repo>/rate-limiter/prd-rate-limiter.md`, with the task table and Mermaid dependency tree.
3. You approve the Claude/You split.
4. Walkthroughs written with graduated hints in `prd/<repo>/rate-limiter/NN.MM-slug.md`.
5. Claude scaffolds all its tasks against stubs, then stops.
6. A brief tells you what was scaffolded and which walkthrough step you start on.

## Where files live

`prd/` sits **exactly one level above the repo root**, shared by sibling repos, with one subfolder per repo and one per task:

```
parent-dir/
├── prd/                          <- Obsidian vault root
│   └── my-repo/
│       └── rate-limiter/
│           ├── prd-rate-limiter.md
│           ├── 01-project-wiring.md
│           ├── 02.01-interfaces.md
│           └── 03.02-token-store.md
└── my-repo/                      <- the repo
```

Claude finds the repo root (`git rev-parse --show-toplevel`), takes its parent directory, and creates `prd/` there if it doesn't exist. Because `prd/` is outside the repo, the repo's git does not track it. Back it up or version it separately if you want history. Claude mentions this once, the first time it creates the directory.

## File naming

- PRD: `prd-<prd-name>.md`
- Walkthrough with no prerequisites: `NN-<slug>.md`
- Walkthrough that depends on another task: `NN.MM-<slug>.md`, where `NN` is the task itself and `MM` is the task it waits on.
- Several prerequisites chain on: `05.02.03-<slug>.md` means task 5 waits on tasks 2 and 3.
- Numbers are zero-padded and ordered so prerequisites come first. Filenames list direct prerequisites only (more than three is a sign the task should be split). The full dependency graph lives in the PRD.

## What each file contains

**The PRD (`prd-<name>.md`)** is the source of truth:

- Front matter: repo, task, status, dates, and the settings used
- A "Next up" callout naming the first unfinished task of yours
- The task table: number, name, owner, dependencies, status, walkthrough link, notes
- A Mermaid dependency tree
- Problem statement, solution, user stories, implementation decisions, testing decisions (including the agreed seams), assumptions and open questions, out of scope, further notes, and a change log

**A walkthrough (`NN.MM-<slug>.md`)** holds the detail:

- A "Resume here" callout so a fresh instance knows exactly where to start
- Why the task is yours, and the context needed to start cold
- The contract: the stub your code must satisfy
- Checkbox steps, each with a "done when"
- Graduated hints, kept folded so you don't spoil them
- Open questions for further discussion
- Acceptance criteria and a short log

Small tasks that wouldn't be painful to resume don't get a walkthrough. They stay as a PRD row with notes, plus a `TODO(you)` stub in the code.

## Resuming across Claude instances

Open a fresh chat and say `/step-by-step resume`. Claude will:

1. Find your task (and ask which one if several are unfinished).
2. Read the PRD, including the settings you chose.
3. Run a drift check: do the PRD and walkthroughs still agree?
4. Open the walkthrough for your first unfinished task and read its "Resume here" line.
5. Re-orient you in 3 to 4 lines. It does not rescan the whole codebase.

Because all state lives in the files, nothing depends on the earlier chat.

## PRD is the source of truth

If the PRD and a walkthrough ever disagree, **the PRD wins** and the walkthrough is regenerated. Regeneration never starts from scratch:

- Completed steps and open questions carry over.
- Anything the change invalidates is flagged to you, not silently dropped.
- Claude tells you what will change before overwriting.
- If your answer to an open question changes scope, Claude proposes a PRD edit and waits for your approval.

Task-level status (not-started, in-progress, blocked, done, dropped) lives in the PRD table. Step-level progress lives in walkthrough checkboxes.

## Obsidian setup

Open the `prd/` directory as an Obsidian vault. Everything uses core features only, so there are no plugins to install:

- Path-qualified wikilinks with aliases, e.g. `[[my-repo/rate-limiter/03.02-token-store|03 Token store]]`, so backlinks and graph view work
- YAML properties on every file (links in YAML are quoted)
- A Mermaid dependency tree in the PRD
- Checkbox steps
- `[!question]` callouts for open questions
- Folded `[!hint]-` callouts for hints, collapsed by default so you won't spoil your own task

The files are plain markdown, so they also read fine without Obsidian.

## Installing

Upload `step-by-step.zip` as a skill (Claude.ai: Settings, Capabilities, Skills), or unzip the `step-by-step/` folder into your skills directory (for Claude Code, `~/.claude/skills/` or `.claude/skills/` in a project). Then invoke it with `/step-by-step` followed by what you want to build.

The skill triggers on `/step-by-step` and on natural phrases such as "keep me in the loop", "you scaffold, I'll build", "walk me through it", "resume my task", and "where did we leave off". It deliberately does not trigger on quick one-off requests where you just want something done.

## Design decisions

- **Claude proposes the split, you approve.** Ownership follows a stated rule (the `own` option), and you can flip any task.
- **One stage at a time.** Claude prepares exactly one task of yours, briefs you once, and stops. Nothing is scaffolded ahead of you, so each stage ends in something you can run, test, and commit.
- **Tests define done, and they are red, not hidden.** Claude writes real failing tests before you start, never skipped or pending ones, and they fail for the right reason. You get feedback by running them; Claude's review covers what they can't see.
- **Stubs fail loudly and stay unwired.** A stub throws its `TODO(you)` marker and nothing that runs calls it, so unfinished work can neither pass silently nor affect the app. Wiring is Claude's task, done after the stub is green.
- **Commits are yours.** Claude suggests a checkpoint and message at every stop and never commits unasked.
- **Hints live in the walkthrough**, not in chat, so any instance can serve them and nothing is improvised differently each time.
- **Subagents write walkthroughs** because good steps and hints take real thought. If subagents aren't available, Claude writes them inline, so the skill stays portable.
- **Judgment call to be aware of:** walkthroughs are created when a task would be painful to resume cold. When in doubt for a task of yours, Claude creates one, because that's where hints live.
- **Agnostic by design.** Plain markdown files in a fixed directory structure, with no dependence on any one tool.

## Scripts

Five deterministic helpers in `scripts/` handle the mechanical parts, so Claude does not re-derive them each run. They use only the Python 3.12 standard library. The skill tells Claude to run them when it can and to follow the manual procedure when it cannot. See `references/scripts.md`.

| Script | What it does |
|---|---|
| `list_tasks.py` | Resolve paths, list tasks, pick a task to resume |
| `new_task.py` | Create the PRD and walkthrough skeletons from a task list |
| `validate_task.py` | Check a task folder is well formed |
| `check_drift.py` | Check the PRD and walkthroughs agree |
| `rename_task_file.py` | Rename a walkthrough and rewrite every link to it |

## Package contents

```
step-by-step/
├── SKILL.md                          main instructions and workflow
├── README.md                         this file
├── scripts/                          deterministic helpers (see references/scripts.md)
└── references/
    ├── options.md                    every option value, and how phrasings are parsed
    ├── prd-template.md               PRD structure and filling rules
    ├── walkthrough-template.md       walkthrough structure, steps, and hints
    ├── obsidian-conventions.md       links, properties, callouts, Mermaid, renames
    ├── resume-and-regeneration.md    resume procedure, drift check, regeneration
    └── scripts.md                    usage for the deterministic scripts
```
