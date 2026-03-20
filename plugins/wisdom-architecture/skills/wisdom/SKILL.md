# Wisdom Architecture

This skill should be used for all coding tasks. It applies a fast/slow/meta cognitive architecture that improves coding accuracy through predictions, principles, and self-review.

## Overview

You operate using three cognitive modules. The hooks enforce the structure — your job is to follow the skill.

- **Fast module**: Every action starts with a prediction. You predict what will happen, execute, then record whether you were right.
- **Slow module**: Every 5 actions (or after any failure), you pause and extract principles from your recent predictions and outcomes.
- **Meta module**: Before significant changes, you check your proposed action against accumulated principles and your recent accuracy.

## Scratchpad

The scratchpad lives at `.claude/wisdom-scratchpad.md` in the project root. Create it if it doesn't exist. It has three sections:

```markdown
# Wisdom Scratchpad

## Principles
<!-- Max 20. Each is one sentence, specific to THIS project. -->
<!-- Format: - [evidence_count] Principle text -->

## Predictions
<!-- Last 5 predictions and outcomes. -->
<!-- Format: - [turn_N] PREDICTION: ... | OUTCOME: correct/wrong/partial | WHY: ... -->

## Stats
- Session actions: 0
- Correct predictions: 0
- Wrong predictions: 0
- Partial predictions: 0
- Error trend: stable
```

Read this file at the start of every session. It persists across sessions — principles accumulate over time.

## Fast Module — Every Action

Before writing or modifying code, running a command, or making any change:

1. Write a one-line prediction in the scratchpad: `- [turn_N] PREDICTION: I expect [specific outcome] because [reasoning]`
2. Execute the action.
3. Record the outcome: `OUTCOME: correct/wrong/partial | WHY: [what actually happened]`
4. Update the stats.

Keep only the last 5 predictions. Drop the oldest when adding a new one.

What counts as a "specific" prediction:
- GOOD: "I expect this test to pass because the nil guard now covers the edge case in line 42"
- GOOD: "I expect the build to fail because I haven't updated the import path yet"
- BAD: "I expect this to work" (not specific, not falsifiable)

## Slow Module — Every 5 Actions or After Failure

When the action count hits a multiple of 5, or immediately after any wrong prediction:

1. Review the last 5 predictions and outcomes.
2. Look for patterns. Are you making the same type of mistake? Is there a codebase behavior you didn't understand?
3. Update principles:
   - **Add** a principle if you have 2+ supporting experiences. Format: `- [2] Never modify X without also updating Y in this project`
   - **Strengthen** a principle by incrementing its evidence count when it's confirmed again.
   - **Remove** a principle if 2+ experiences contradict it.
   - **Refine** a principle to be more specific when you learn the conditions under which it applies.
4. Update the error trend: compare your last 5 accuracy to your overall accuracy. If it's worse, set trend to `degrading`. If better, `improving`. Otherwise `stable`.

If the error trend is `degrading`: make smaller changes, test more frequently, and re-read relevant code before acting. Your model of the codebase is drifting.

Max 20 principles. If you're at 20 and need to add one, remove the weakest (lowest evidence count, or most generic).

## Meta Module — Before Significant Changes

Before any of these: creating a new file, modifying more than ~30 lines, changing an interface/type/API, deleting code, modifying config, running a destructive command:

1. Read your current principles from the scratchpad.
2. Check the proposed change against each principle. Does any principle suggest this is risky?
3. If there's a conflict: state it explicitly. Either justify why the principle doesn't apply, or revise the approach. Do not silently override.
4. Rate your confidence:
   - **High**: proceed normally.
   - **Medium**: write a test or verification step first.
   - **Low**: break into smaller steps. Do the smallest one first. Verify. Continue.
5. If 3+ of your last 5 predictions were wrong: do NOT make significant changes. Re-read the relevant code sections first. Your understanding is off.

## Cross-Session Behavior

The scratchpad persists. On session start:
1. Read `.claude/wisdom-scratchpad.md`
2. Internalize all principles before doing anything
3. Reset session action count to 0 but keep principles and overall accuracy trend

The principles from past sessions are the closest thing to "memory" this system has. Treat them as hard-won knowledge — don't discard them without evidence.

## Example Flow

```
Task: "Add rate limiting to the API endpoint"

[Fast] turn_12 PREDICTION: Adding the middleware to the router chain will work
without changing the handler signatures because this project uses http.Handler 
interface throughout | OUTCOME: correct | WHY: confirmed, all handlers implement 
http.Handler

[Fast] turn_13 PREDICTION: The rate limiter tests will pass on first run because 
I'm using the same test helpers as the auth middleware tests | OUTCOME: wrong | 
WHY: the test helper assumes a fresh DB per test but rate limiter uses Redis, 
needed to add Redis cleanup in setUp

[Slow — triggered by wrong prediction]
Pattern: I assumed test infrastructure would transfer across middleware types. 
This is the second time — same thing happened with the logging middleware in turn 8.
NEW PRINCIPLE: - [2] Each middleware type in this project may need its own test 
fixture setup — don't assume the auth test helpers cover other middleware.
Error trend: stable (1 wrong out of last 5)

[Meta — about to create rate_limiter_test.go]
Checking principles...
  Principle: "Each middleware type may need its own test fixture setup"
  → Relevant. I'll set up a dedicated Redis test fixture instead of reusing 
    the auth helper.
Confidence: high (principle directly applies)
Proceeding with dedicated fixtures.
```
