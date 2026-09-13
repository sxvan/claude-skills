# claude-skills

A Claude Code plugin marketplace. Three skills: two that keep prose from reading as AI generated, one that keeps code reviewable at a glance.

## Install

```
/plugin marketplace add sxvan/claude-skills
/plugin install human-writing@claude-skills
/plugin install human-structure@claude-skills
/plugin install elegant-coding@claude-skills
```

Or add the marketplace and browse it with `/plugin`. To test a local checkout, point the first command at the directory instead: `/plugin marketplace add /path/to/claude-skills`.

## Plugins

| Plugin | What it does |
| --- | --- |
| `human-writing` | Words and punctuation. Cuts the vocabulary and punctuation patterns that mark text as AI generated. |
| `human-structure` | What a message says and how it is shaped: length, ordering, prose versus lists, and whether a sentence carries information. |
| `elegant-coding` | Code whose correctness is visible at a glance: invalid states made unrepresentable rather than guarded against, few branches, and a small diff. |

Each plugin holds one skill, so Claude reads its description and loads it when the task matches. You can also name it directly.

## Repository layout

```
.claude-plugin/marketplace.json     the marketplace manifest
plugins/<plugin>/
  .claude-plugin/plugin.json        the plugin manifest
  skills/<skill>/SKILL.md           the skill
  skills/<skill>/references/        examples and other files loaded on demand
eval/                               A/B runner: each case once with the skill, once without
```

To add a skill, write `plugins/<name>/.claude-plugin/plugin.json` and `plugins/<name>/skills/<name>/SKILL.md`, then add an entry to the `plugins` array in `.claude-plugin/marketplace.json`. Once it is pushed, users pick it up with `/plugin marketplace update claude-skills`.

MIT licensed.
