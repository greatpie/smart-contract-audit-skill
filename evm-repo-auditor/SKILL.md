---
name: evm-repo-auditor
description: Script-backed, out-of-box auditing workflow for Solidity/EVM repositories based on EVMbench detect/patch/exploit methodology. Use when asked to audit a smart contract repo from a URL or local path, auto-prepare the environment, find high-severity loss-of-funds vulnerabilities, validate exploitability, propose safe fixes, and deliver a structured report with exact code references.
---

# EVM Repo Auditor

## Overview

Run a complete security audit flow for a target EVM repository, optimized for high-impact vulnerabilities that can directly or indirectly cause loss of user or protocol assets.

This skill is script-first (not prompt-only). Use the bundled Bash scripts for deterministic setup and packaging:
- `scripts/bootstrap.sh` prepares the repo environment.
- `scripts/run_detect.sh` creates a report scaffold and hotspot map.
- `scripts/run_patch.sh` validates tests and exports `submission/agent.diff`.
- `scripts/run_exploit.sh` starts local Anvil and prepares exploit artifacts.
- `scripts/generate_exploit_scaffold.sh` creates minimal exploit starter files for Foundry/Hardhat.
- `scripts/audit.sh` runs a full pipeline in one command.

Read `references/evmbench-core.md` for benchmark rationale, `references/report-template.md` for final report structure, `references/script-usage.md` for command examples, and `references/benchmark-reality-checklist.md` to reduce realism gaps.

## Quick Start

Use the one-command pipeline:

```bash
bash scripts/audit.sh \
  --repo https://github.com/org/project.git \
  --branch main \
  --modes detect,patch
```

Or run phased mode:

```bash
bash scripts/bootstrap.sh --repo https://github.com/org/project.git --branch main
bash scripts/run_detect.sh --repo-dir /absolute/path/to/repo
bash scripts/run_patch.sh --repo-dir /absolute/path/to/repo
bash scripts/run_exploit.sh --repo-dir /absolute/path/to/repo
```

## Script Behavior

`bootstrap.sh`
- Clone from URL (depth 1 by default) or use a local repo path.
- Detect framework (`foundry`, `hardhat`, `truffle`, `unknown`).
- Install dependencies when possible.
- Run compile/test smoke checks when commands are available.
- Write metadata to `.audit-meta/env.sh`.

`run_detect.sh`
- Build a deterministic report scaffold at `submission/audit.md`.
- Include scope stats and risk hotspot counts.
- Do not claim findings as confirmed without manual validation.

`run_patch.sh`
- Run build/test checks on the patched code.
- Export unified patch to `submission/agent.diff` from baseline commit.
- Write summary to `submission/patch-summary.md`.

`run_exploit.sh`
- Start a local Anvil chain and persist PID/logs under `.audit-meta/`.
- Write local exploit env to `submission/exploit-env.sh`.
- Optionally run a user-provided tx script via `--tx-script`.
- Optionally run built-in templates via `--template foundry` or `--template hardhat`.
- Create `submission/txs.md` and `submission/txs.json` templates for evidence logging and replay.

`generate_exploit_scaffold.sh`
- Generate minimal starter files:
  - Foundry: `script/Exploit.s.sol`
  - Hardhat: `scripts/exploit.js`
- Write guidance to `submission/exploit-scaffold-notes.md`.

## Audit Standard

Prioritize comprehensive coverage over single-issue wins:
- Continue searching after finding one bug.
- Track explored components to avoid blind spots.
- Report only credible vulnerabilities.

For each confirmed finding, include:
- Title, severity, confidence.
- Root cause and exploit path.
- Concrete impact.
- Exact file/line references.
- Reproduction sketch and remediation.

## Quality Bar

- Report only vulnerabilities that plausibly lead to asset loss or concrete takeover impact.
- Avoid severity inflation and duplicate root causes.
- Mark uncertain items as `Needs confirmation` with missing evidence.
- Keep patches minimal and interface-safe unless security requires otherwise.

## Expected Outputs

- `submission/audit.md` (detect report)
- `submission/agent.diff` (patch bundle)
- `submission/patch-summary.md` (patch validation summary)
- `submission/exploit-env.sh`, `submission/txs.md`, and `submission/txs.json` (exploit evidence setup)
