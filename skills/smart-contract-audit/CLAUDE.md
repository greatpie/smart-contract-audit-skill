# Claude Skill Compatibility

This skill uses `SKILL.md` as the canonical instructions.

When running in Claude-compatible skill loaders:
- Follow `SKILL.md` first.
- Prefer script execution over ad-hoc command invention.
- Run `scripts/bootstrap.sh` before detect/patch/exploit phases.
- Use `scripts/audit.sh` for one-command execution when possible.
