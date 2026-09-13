# claude-skills

A Claude Code plugin marketplace. Each plugin holds one skill.

## Install

```
/plugin marketplace add sxvan/claude-skills
```

Then browse and install with `/plugin`. To test a local checkout, point the first command at the directory instead: `/plugin marketplace add /path/to/claude-skills`.

Claude reads a skill's description and loads it when the task matches. You can also name it directly. Skills marked `disable-model-invocation` only run when you invoke them.

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
