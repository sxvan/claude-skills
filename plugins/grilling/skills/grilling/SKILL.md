---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Run it when the user wants to stress-test their thinking before committing to it.
disable-model-invocation: true
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the frontier with the **AskUserQuestion** tool, then wait for the answers before the next round.

One call carries up to four questions, so four is the width of a round. When the frontier is wider, ask the four that unblock the most of the tree and leave the rest for the next round. Never split a round across two calls; the user answers them together.

Build each question like this:

- `header`: the decision's name, 12 characters at most.
- `question`: the question itself. Multiple paragraphs are fine, and this is where your reasoning belongs: what hangs off the answer, what it costs to get wrong, what you already know that narrows it.
- `options`: two to four named positions, your recommendation first with `(Recommended)` at the end of its label. Labels run one to five words; each `description` says what picking it commits the user to. Never add an "Other" option, the UI supplies one.
- `multiSelect: true` when the options combine instead of competing.
- `preview`: use it on a single-select question when the options are concrete enough to compare side by side, such as a code snippet, a file layout, a schema, or an ASCII sketch of a UI.

A question with no obvious options still gets options. Name the two or three positions a reasonable person would actually take and let the user reach for Other if none fit. If the only phrasing you can find is "what do you think?", the question isn't ready: work out what the real alternatives are first.

Each round the user answers reshapes the tree. Settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. A question counts as downstream when the pending fact could change which option you recommend, not only when it could change the question. Recommending on a guess and retracting it a minute later costs the user more than a slower round. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
