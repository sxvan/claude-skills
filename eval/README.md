# eval

`eval/run` runs each case twice, once with its skills loaded and once without, so you can compare the two outputs by hand.

```
eval/run                            # every case in eval/cases
eval/run eval/cases/release-note.json
```

A case is a JSON file:

```json
{
  "prompt": "Write a release note for version 2.3 ...",
  "skills": ["human-writing", "human-structure"],
  "model": "opus"
}
```

`skills` names directories under `plugins/`. `model` is optional and defaults to opus.

Results land in `eval/results/<case>/<timestamp>/` as `prompt.md`, `with.md` and `without.md`. That folder is gitignored.

## How the two arms are kept comparable

Both arms run in an empty temp directory under `--restricted`, which drops Bash and ignores your user, project and local settings. Otherwise the skills you already have installed would show up in the baseline as well, and this repo's CLAUDE.md would load into both. The with arm adds `--plugin-dir` for each named skill and a line in front of the prompt telling Claude to use it. The without arm adds `--disable-slash-commands`, so no skill can load at all.
