# Walkthrough template

File: `prd_root/<repo>/<task-name>/NN-<slug>.md`, or `NN.MM-<slug>.md` when the task depends on task MM (more prerequisites chain on: `05.02.03-<slug>.md`).

A walkthrough holds the implementation detail, the specific steps, the hints, and the open questions for one task. It is written so a fresh Claude instance or the user after a week away can pick it up cold. If it disagrees with the PRD, the PRD wins and the walkthrough is regenerated.

Calibrate step size and explanation depth to `level`. Include hint callouts per `hints` (omit them for `none`; add a reference solution for `full`).

In `depends_on` and `blocks`, link each task to its walkthrough. If a task has no walkthrough, link to the PRD instead and keep the alias: `"[[<repo>/<task-name>/prd-<prd-name>#Tasks|01 Project wiring]]"`. The leading number in the alias is how tooling identifies the task, so every link needs an alias in the form `NN Name`.

## Contents
- Template
- Writing good steps
- Writing good hints
- Claude-owned walkthroughs

## Template

````markdown
---
type: walkthrough
repo: <repo>
task: <task-name>
id: 3
name: Token store
owner: you              # you | claude
status: not-started     # not-started | in-progress | blocked | done | dropped
depends_on:
  - "[[<repo>/<task-name>/02.01-interfaces|02 Interfaces]]"
blocks:
  - "[[<repo>/<task-name>/04.03-api-wiring|04 API wiring]]"
up: "[[<repo>/<task-name>/prd-<prd-name>|PRD]]"
tags:
  - walkthrough
  - owner/you
---

# 03 Token store

> [!info] Resume here
> Step 1. Nothing started yet.

## Why this is yours

One or two sentences on why this task is a judgment call or core logic worth the user doing themselves.

## Context

What already exists (scaffolded by Claude), what the surrounding code expects, and any decisions from the PRD that matter here. Enough that someone arriving cold does not need to re-read the whole PRD.

## Contract

The stub the user's code must fulfil: signature, inputs, outputs, errors, and behavior in prose. Name where the stub lives. It throws its `TODO(you)` marker when called, and nothing in the running app calls it until the task is green, so it is not wired in.

## Tests

The tests that define done for this task. Claude writes them before the user starts; they are red until the user finishes. The user can run them without Claude.

- **Run:** `<the exact command, scoped to these tests>`
- **Red now:**
  - `<test name>` in `<file>`: <what behavior it proves>.
  - `<test name>` in `<file>`: <...>.
- **Baseline:** <failures that already existed before this stage, so they are not mistaken for this task's>.

Judgment calls left to the user (see open questions) are deliberately not asserted.

## Steps

- [ ] 1. <Small, observable step>. *Done when:* <what the user can check>.
- [ ] 2. <Next step>. *Done when:* <...>.
- [ ] 3. <...>

## Hints

### Step 1

> [!hint]- Hint 1: nudge
> A question or concept to consider. No code.

> [!hint]- Hint 2: pointer
> Where to look (module, doc, or API) and the shape of the approach.

> [!hint]- Hint 3: worked example
> A worked example on an analogous case, or a near-solution.

### Step 2

> [!hint]- Hint 1: nudge
> ...

## Reference solution

> [!success]- Reference solution
> Included only when `hints=full`. A complete working solution.

## Open questions

> [!question] Q1: <Question for further discussion>
> Context, options, and a recommendation if there is one.

## Done when

The acceptance criteria for the whole task, tied to the Tests section: the listed tests are green, the surrounding suite still passes, and the stub's `TODO(you)` marker is gone. Add anything the tests cannot show; Claude's closing review covers it.

## Log

- YYYY-MM-DD: Created from PRD.
````

## Writing good steps

- Each step is small enough to finish and verify on its own, and names what to look at and why (more of the why for `level=new`, less for `expert`).
- Every step has a "Done when" the user can check without asking Claude.
- Order steps so each builds on the last. Do not bury a decision in the middle of a mechanical step; give it its own step.
- Keep file paths in walkthroughs (they are working notes, unlike the PRD), but prefer module and symbol names where they will survive refactors.

## Writing good hints

- Hint 1 is a nudge: the question to ask, or the concept in play. No code.
- Hint 2 is a pointer: where to look and the shape of the approach.
- Hint 3 is a worked example, ideally on an *analogous* problem, so the user still does the thinking on the real one.
- Always folded (`[!hint]-`) so they are not read by accident.
- Write hints that would actually unstick someone, based on where this task is genuinely tricky. If one proves insufficient during the work, add a better one.

## Claude-owned walkthroughs

When a Claude-owned task is painful to resume cold, it still gets a walkthrough (`owner: claude`). Use the same structure, but skip "Why this is yours" and the hints. Claude does these tasks test-first, ticks the steps off as it goes, and the "Resume here" marker tells a fresh instance where it stopped.
