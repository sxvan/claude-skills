---
name: elegant-coding
description: The default working mode for all software work. Plan and write code whose correctness is visible at a glance, with invalid states made unrepresentable rather than guarded against, few branches, and a diff a reviewer can check quickly. Use it on every task that touches code designing, planning, implementing, refactoring, debugging, and reviewing. Invoke it before the plan and before the first line of code.
---

# Elegant coding

Code that works is the minimum. Judge a change by how fast a competent reviewer can confirm it is correct, and by how little they have to remember while doing it.

Before and after pairs for most of these rules: `references/examples.md`.

## Bad states

1. **Make it unrepresentable.** Before writing a guard, look for a type, signature, data structure, or call order in which the state cannot exist. No branch, no test, nothing to review.

2. **Otherwise handle it once, at the boundary.** Parse raw input into a value the core can trust. Downstream functions become total.

3. **Otherwise guard locally,** when the state can really occur and only this call site can decide what to do about it.

4. **Otherwise fail loudly.** Assert, or let it throw, when the state occurring would mean a bug elsewhere.

5. **Never return quietly on an impossible state.** `if x is None: return` adds a branch and hides the bug it was meant to catch.

6. **Keep branches that state a rule.** `if invoice.is_overdue` and `if user.role is Role.ADMIN` belong in the code.

7. **Validate at trust lines.** User input, network responses, the filesystem, deserialization, concurrency, anything crossing a version boundary. Check there, produce a value the rest of the system can trust, and trust it inside that line.

## Ways to delete branches

8. **Make the empty case the same case.** Return `[]` and iterate, with no `if not items`. Prefer a neutral default over a nullable.

9. **Total lookups instead of cascades.** A dict, table, or registry turns a chain of `elif` into data. Adding a case stops adding a code path.

10. **Exhaustive alternatives.** A closed union and a match with no catch-all makes the compiler point at every site that has to change when a case is added.

11. **Branch once, at the top.** Pick the strategy, backend, or mode a single time, then run straight-line code. Move conditionals toward the caller and I/O out of the core.

12. **Make the caller's mistake impossible.** Two named functions instead of a boolean flag parameter, required constructor arguments instead of fields that must be set later, a context manager instead of a documented call order.

13. **Skip the check the caller already did.** When the only caller established a fact, state it in the signature instead of establishing it again.

14. **Return early instead of nesting.** Check the case that exits, return or raise, and leave the main path at one indent level. Don't wrap the rest of the function in an `if`.

## What elegance is not

15. **Not fewer lines.** A nested ternary or a dense comprehension that needs a second read is worse than four plain lines. Count reading time, not lines.

16. **Not new abstraction.** A helper with one caller, a config setting nobody set, an interface with one implementation: each one is another definition the reader has to look up. Use the least structure the current task needs.

17. **Not a rewrite.** Apply this to the code the task already touches. If neighboring code would benefit, say so in a sentence and leave it.

18. **Not a type puzzle.** Removing a single `if` by introducing a union, a class hierarchy, or a wrapper type is over-engineering. New types pay off when they retire a whole class of bug across many call sites.

19. **Not a trick.** Choose the shape carefully and keep the syntax plain. The reader should think "obviously right", never "how does that work?".

## Names and comments

20. **Name things so that a comment describing what the code does would only repeat the code.** If you want to write such a comment, rename or restructure instead.

21. **Keep comments for why:** the constraint, the surprising reason, the thing the next reader would otherwise undo. Use comments sparingly.
