# Options reference

Every option has a default, so the bare command always works. Record the final settings in the PRD front matter under `settings:` and state them in one line at the start of the run, e.g. "Settings: grill=full, own=core, hints=graduated, stop=scaffold, level=familiar."

## Contents
- Parsing
- grill
- own
- hints
- stop
- level
- list and resume

## Parsing

Accept all of these as equivalent:

```
/step-by-step grill=quick own=more I want to build X
/step-by-step quick grill, I own more, I want to build X
/step-by-step I want to build X, keep the grilling short and give me more of the work
```

Natural-language phrasings to recognize:

| Phrase (examples) | Maps to |
|---|---|
| "quick grill", "short interview", "just a few questions" | `grill=quick` |
| "skip the grill", "I already have a spec", "no interview" | `grill=skip` |
| "I own more", "give me more of the work" | `own=more` |
| "I own most", "just do the boilerplate" | `own=most` |
| "no hints", "bare steps" | `hints=none` |
| "full hints", "include the solution" | `hints=full` |
| "stop after the PRD", "just the PRD" | `stop=prd` |
| "stop after the plan", "write the walkthroughs but don't scaffold" | `stop=plan` |
| "I'm new to this", "explain the why" | `level=new` |
| "I know this area well", "keep it terse" | `level=expert` |
| "list", "show my tasks" | `list` |
| "list all", "tasks across repos" | `list all` |
| "resume", "where did we leave off", "pick it back up" | `resume` |

If a phrase is ambiguous, pick the default rather than asking. Words that are not options belong to the goal. If the user overrides something in plain words that has no option (for example "don't use subagents" or "use this repo name"), honor it.

## grill

| Value | Behavior |
|---|---|
| `full` (default) | Exhaust the decision tree, one question at a time, with a recommended answer on each. |
| `quick` | 3 to 6 questions on the branches where a wrong guess is expensive (scope, ownership, key constraints). State assumptions for everything else and record them in the PRD under assumptions. |
| `skip` | The user already decided. Read their spec, explore the codebase, ask only about true blockers, and record remaining gaps as assumptions and open questions in the PRD. |

In every mode: if the codebase can answer a question, explore instead of asking.

## own

Controls how much lands on the user. The test underneath all three: if a wrong choice would teach the user something, or they'd need to explain it in a code review, it is theirs.

| Value | User owns | Claude owns |
|---|---|---|
| `core` (default) | Judgment calls, design decisions, and the central logic where the main idea of the feature lives | Everything else: setup, wiring, integration, boilerplate, stubs, test harness |
| `more` | Everything in `core`, plus integration points, data model, error-handling policy, and anything the user would need to maintain or debug | Setup, boilerplate, config, interface definitions, mechanical code |
| `most` | Nearly everything | Only boilerplate, project setup, config, dependency installation, wiring, mechanical refactors, and tests |

The user can flip any single task's owner during split approval regardless of this setting.

## hints

| Value | Walkthrough contents |
|---|---|
| `none` | Steps, contract, and open questions only. No hint callouts. |
| `graduated` (default) | Per step, three folded hints in order: Hint 1 is a nudge toward the right question or concept (no code); Hint 2 points to the specific place in the codebase, doc, or API and the shape of the approach; Hint 3 is a worked example on an analogous case or a near-solution. |
| `full` | Everything in `graduated`, plus a folded `[!success]- Reference solution` callout near the top of the walkthrough. |

Prefer solving an analogous problem in Hint 3 rather than the exact one, so the user still does the thinking. Always keep hints folded (`-` after the callout type) so the user does not spoil them by accident.

## stop

| Value | Claude pauses after |
|---|---|
| `prd` | The PRD is written and the owner split is approved. |
| `plan` | All walkthroughs are written and verified, before any scaffolding. |
| `scaffold` (default) | Each stage is scaffolded: Claude builds the prerequisites for the user's next task, writes its failing tests, and gives the brief. Claude then stops, and stops again after every later stage, so the work proceeds one user task at a time. |

At every stop, give the brief (what exists, where to start, the test command, a suggested commit checkpoint, settings) and end the turn.

## level

Calibrates how fine-grained the steps are and how much explanation they carry.

| Value | Steps | Explanation |
|---|---|---|
| `new` | Small, each with the reason behind it | Explain concepts and terms; link to docs where useful |
| `familiar` (default) | Moderate; assume the basics | Explain only the non-obvious decisions |
| `expert` | Coarse; one step may span several actions | Terse. State the goal and the contract, skip the rationale |

`level` changes the walkthrough depth, not which tasks the user owns (that is `own`).

## list and resume

These are actions rather than settings, so they have no default value.

- `list`: show tasks for the current repo, one line each: name, status, next step. `list all` covers every repo under `prd_root`.
- `resume [name]`: with a name, go straight to that task. Without one, go straight to the only unfinished task if there is exactly one for the repo; otherwise show the list and ask which.
