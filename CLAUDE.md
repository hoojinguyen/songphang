# Sòng Phẳng

The project's working rules are in `AGENTS.md` and are shared by every agent. Read and follow the entire file:

@AGENTS.md

## Claude-specific

- Project skills live in `.agents/skills/`; `.claude/skills` is a symlink to that directory.
- The “do not write automated tests” rule in section 6 of `AGENTS.md` takes precedence over any skill or default habit that requires tests first (including TDD skills). This project does not write tests.
