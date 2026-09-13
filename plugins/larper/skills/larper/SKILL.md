---
name: larper
description: Teach the user the domain behind a feature before any design or code exists. Run it as the first step of a feature, before architecture, planning, or the first implementation prompt. Two phases in one command; a short assessment to find where to start, then one teaching message. Domain knowledge only, never the codebase.
disable-model-invocation: true
---

# Larper

Get the domain into the user's head before any design or code exists. Teach the
domain, never the codebase.

The user is about to build against a domain or third-party system they may not
know. If they go straight to prompting, they get working code they do not
understand and cannot repair. That is the failure this prevents.

## Entry

`/larper <topic>` takes the topic as given. `/larper feature X` and a bare
`/larper` infer it from the feature or the conversation. For the two inferred
forms, state the topic you understood in one line and wait for confirmation. A
wrong root wastes the session.

## Phase 1: assessment

Find where the teaching starts and how wide it goes. This is not a quiz, there
are no wrong answers, and nothing is scored.

1. **One question per message.** Wait for the answer.

2. **Name a mechanism, answerable yes or no.** "Do you know why MSAL is
   required rather than a plain HTTP call?" Not "How familiar are you with
   MSAL?", which measures confidence and is easy to answer without knowing
   anything. Naming the mechanism is what makes a question hard to bluff.

3. **Work as a tree, not a checklist.** Start with the question whose yes would
   imply most of the rest. A yes prunes that branch. A no widens into the
   mechanisms under it.

4. **Stop early.** Ask while an answer would still move where the teaching
   starts or how wide it goes. Stop once it would only trim a detail. Usually
   two or three questions, sometimes one.

5. **When in doubt, assume they do not know it** and put it in the teaching
   message. A skipped paragraph costs seconds. A question costs a round trip.

## Phase 2: teaching

One message, read start to finish. Do not turn it into a back-and-forth and do
not ask what they want covered first.

1. **Take the shape from the topic.** A protocol wants the exchange walked in
   order. A data model wants the entities and the constraints between them. A
   rule wants its inputs, its decision, and the cases it excludes. Some topics
   are none of these. Do not force a shape that is not there.

2. **Scope it to what phase 1 found.** Skip what the user already has.

3. **Include what never reaches the code.** Conventions, constraints of the
   third-party system, the reason the domain works the way it does. The test is
   whether the user needs it to decide well, not whether it becomes a line of
   code.

4. **Pitch it so they can explain the mechanism to a colleague and say what
   would break it, and still could not build it from this message.** Above that
   line: the moving parts, how they connect, what is outside the user's
   control, what happens when those change or fail. Below it: API signatures,
   parameter lists, configuration values, library specifics, code. If they want
   those, they will ask.

5. **A thin topic gets a few lines.** That is the correct output. Do not refuse
   the topic, do not comment on whether the command was needed, do not pad.

## Never

- No PRD, ADR, summary document, or file of any kind. The output is a message.
- No codebase explanation.
- No design proposals, no implementation plan, no code.
- No scoring the user's answers.
