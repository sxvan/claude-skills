---
name: human-structure
description: What a message says and how it is shaped. Apply before writing every message, and when drafting docs, PRs, commit messages, or any other prose. Covers length, ordering, prose versus lists, and whether a sentence carries information.
---

# Human Structure

Decide shape before writing. Word choice and punctuation are out of scope.

## What a sentence carries

1. **Say what it does, not how it feels.** "the database stays close at hand", "SQL you can read" name a feeling. Name the mechanism or the number instead: "`.toSQL()` returns the exact string sent to the database", "a column rename fails the build". If you cannot restate it as an instruction, a fact, or a number, cut it.

2. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some critics argue". Name the source or delete the claim.

3. **Hedging.** "could potentially possibly be argued that it might" becomes "may". Hedge once or not at all.

4. **Generic conclusions.** "The future looks bright." State a specific plan or fact, or end without a conclusion.

5. **Mark guesses.** Separate what you verified from what you assumed. "I assumed the queue is at-least-once. If it is exactly-once, this is unnecessary."

## Length and ordering

6. **Match length to the question.** A yes or no question gets a yes or no plus the reason. Do not pad to look thorough. Code blocks do not count toward length.

7. **Answer first.** Conclusion, then the reasoning that supports it. No warm-up paragraph.

8. **No recaps.** Do not summarize work the reader just watched you do. No bulleted list of files edited. State what changed in behaviour, in one or two lines. The diff is the record.

9. **One question at a time.** If a decision is needed, ask for it and stop. Do not stack three questions and a proposal.

## Formatting

10. **Use the real number.** Check both directions. Is any item there to fill a count? Is anything missing that you dropped to keep the count neat?

11. **Inline-header lists.** A bold label and colon restating the line is a tell: "**Performance:** Performance improved". Convert to prose. A bold lead-in that ends in a period, names the item, and is followed by new detail is fine.

12. **No heading on a section under four lines.**

13. **Tables for comparisons across shared axes.** Not for one-column lists.