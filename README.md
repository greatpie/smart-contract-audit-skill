# Agent Skills for Smart Contract Security Auditing

A practical skill collection for production-grade smart contract security reviews, with workflows inspired by the EVMbench paper and benchmark harness.

This repository is designed for teams that want:
- end-to-end audit workflows (detect, patch, exploit),
- reproducible command-line execution,
- artifacts that are easy to review (`audit.md`, `agent.diff`, `txs.json`),
- stronger alignment with real-world loss-of-funds threat models.

## Skills Overview

| Skill | Description |
|---|---|
| [smart-contract-audit](skills/smart-contract-audit/) | Script-backed, out-of-box workflow for EVM repo setup, vulnerability discovery, patch validation, exploit scaffolding, and report generation |

## Repository References

- Repository: [greatpie/smart-contract-audit-skill](https://github.com/greatpie/smart-contract-audit-skill)
- Skill directory: [skills/smart-contract-audit](https://github.com/greatpie/smart-contract-audit-skill/tree/main/skills/smart-contract-audit)
- Script directory: [skills/smart-contract-audit/scripts](https://github.com/greatpie/smart-contract-audit-skill/tree/main/skills/smart-contract-audit/scripts)

## Methodology

The skill is grounded in key EVMbench ideas:
- **Comprehensive coverage over single wins**: keep searching after first finding.
- **Mode separation**: Detect, Patch, and Exploit produce distinct outputs.
- **Evidence-first grading mindset**: require concrete exploitability and impact.
- **Deterministic execution bias**: prefer scripted, replayable steps over ad-hoc claims.

See:
- [EVMbench core notes](skills/smart-contract-audit/references/evmbench-core.md)
- [Benchmark reality checklist](skills/smart-contract-audit/references/benchmark-reality-checklist.md)

## Usage

### Codex / Claude / IDE agents

Invoke the skill directly:

```text
$smart-contract-audit
```

Then run the pipeline:

```bash
bash skills/smart-contract-audit/scripts/audit.sh \
  --repo https://github.com/greatpie/smart-contract-audit-skill.git \
  --branch main \
  --modes detect,patch,exploit
```

### Phase-by-phase

```bash
bash skills/smart-contract-audit/scripts/bootstrap.sh --repo https://github.com/greatpie/smart-contract-audit-skill.git
bash skills/smart-contract-audit/scripts/run_detect.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill
bash skills/smart-contract-audit/scripts/run_patch.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill
bash skills/smart-contract-audit/scripts/run_exploit.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill --template foundry
```

## Output Contract

The skill standardizes outputs under the target repository `submission/` directory:
- `audit.md` (detect findings)
- `agent.diff` (patch output)
- `patch-summary.md` (build/test/diff summary)
- `exploit-env.sh` (local exploit runtime env)
- `txs.md` and `txs.json` (exploit evidence + replay data)

## Design Philosophy

### Progressive Disclosure

Keep the skill lean in `SKILL.md`, then load detailed references only when needed.

### Script-First Reliability

Core operations are implemented in Bash scripts so they run in minimal environments without a heavy runtime stack.

### Realism With Explicit Gaps

The repository documents where it is intentionally lighter than full benchmark infra (e.g., no default isolated grader replay container).

## Repository Structure

```text
.claude-plugin/
  marketplace.json
agents/
  openai.yaml
skills/
  smart-contract-audit/
    SKILL.md
    scripts/
    references/
```

## Notes

- This repository is for defensive security auditing workflows.
- Always ensure you have authorization before testing or exploiting any system.
