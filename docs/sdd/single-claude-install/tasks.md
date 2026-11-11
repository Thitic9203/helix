# Tasks — single Claude Code install

1. **T1 (R1–R5)** Write `scripts/tests/single-claude-install.test.sh`; it fails on current main (N links in `~/.claude/skills`). Then change `link-skills.sh`. Done: test green.
2. **T2 (R2)** Move existing tests' sample folder from `~/.claude/skills` to `~/.cursor/skills`. Done: `run.sh` green.
3. **T3 (R7)** Doctor: drop Claude Code links check, add leftover WARN; assert in the new test. Done: green.
4. **T4 (R8)** README, wiki, supported-agents, plugin-sync message. Done: ci-check-doc-skill-lists + portable pass.
