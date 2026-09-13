# claude-skills

A Claude Code plugin marketplace with skills for writing prose that does not read as AI generated, and for writing code a reviewer can check at a glance.

## Install

```
/plugin marketplace add sxvan/claude-skills
/plugin install human-writing@claude-skills
/plugin install human-structure@claude-skills
/plugin install elegant-coding@claude-skills
```

Or browse with `/plugin` after adding the marketplace.

## Plugins

| Plugin | What it does |
| --- | --- |
| `human-writing` | Word and punctuation choice. Removes the vocabulary and punctuation patterns that mark writing as AI generated. |
| `human-structure` | What a message says and how it is shaped: length, ordering, prose versus lists, and whether a sentence carries information. |
| `elegant-coding` | Code whose correctness is visible at a glance: invalid states made unrepresentable rather than guarded against, few branches, and a small diff. |

Each plugin is a skill, so Claude loads it on its own when the task calls for it. You can also invoke one directly by name.

## Layout

```
.claude-plugin/marketplace.json     the marketplace manifest
plugins/<plugin>/
  .claude-plugin/plugin.json        the plugin manifest
  skills/<skill>/SKILL.md           the skill
  skills/<skill>/references/        examples and other files loaded on demand
eval/                               A/B runner: each case once with the skill, once without
```

## Adding a skill

1. Create `plugins/<name>/.claude-plugin/plugin.json` and `plugins/<name>/skills/<name>/SKILL.md`.
2. Add an entry to the `plugins` array in `.claude-plugin/marketplace.json`.
3. Commit and push. Users get it with `/plugin marketplace update claude-skills`.

## Local testing

```
/plugin marketplace add /home/silvan/repos/claude-skills
/plugin install human-writing@claude-skills
```

## License

MIT
