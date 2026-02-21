# EVMbench Core Notes (from local paper + implementation)

## What EVMbench measures

EVMbench evaluates agent performance across three modes:
- Detect: find high-severity vulnerabilities from audit-like repository context.
- Patch: fix vulnerabilities while keeping non-vulnerable behavior intact.
- Exploit: execute end-to-end exploit transactions on a local chain and prove state impact.

Core benchmark property: measure **comprehensive coverage** (find/address all relevant critical issues), not one-off wins.

## Dataset and setup

- 120 curated high-severity vulnerabilities.
- 40 real-world audit repositories.
- Sources: mostly Code4rena audits, plus Tempo chain scenarios.
- Agent environment: isolated Ubuntu container with internet disabled.
- Exploit mode uses local Ethereum execution and programmatic grading.

## Grading philosophy

Detect
- Grade against ground-truth vulnerabilities using a strict mechanism/code-path equivalence check.
- Reward shape is tied to historical contest payouts (for analysis).

Patch
- Apply agent patch.
- Ensure baseline tests still pass (excluding explicitly vulnerability-dependent tests).
- Run hidden exploit tests; patched code must prevent exploitation.
- Guard against cheating by restoring protected test files before grading.

Exploit
- Re-deploy vulnerable system in grader container.
- Re-execute submitted transactions.
- Score from chain-state checks (balances/events/task-specific conditions).

## Reliability and hardening ideas worth reusing

- Keep setup deterministic (fixed local chain parameters).
- Separate agent runtime from grader runtime.
- Replay actions in grader instead of trusting agent-side claims.
- Block simulator-only RPC methods via a gatekeeper/proxy.
- Validate oracle patch/exploit solutions before using tasks.

## Key reported results in the paper

- Detect best score reported: 45.6%.
- Patch best score reported: 41.5%.
- Exploit best score reported: 72.2%.

Main interpretation:
- Discovery/coverage is often the bottleneck.
- Given mechanism hints, patch and exploit performance rises substantially.

## Practical implications for real audits

Use a benchmark-style workflow:
1. Enforce scope discipline.
2. Focus on loss-of-funds attack paths.
3. Demand reproducible evidence.
4. Evaluate fixes against both exploitability and regression risk.
5. Track coverage explicitly so that “one bug found” does not end the audit.
