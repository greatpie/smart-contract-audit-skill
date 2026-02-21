# Benchmark Reality Checklist (EVMbench-aligned)

Use this checklist to keep audits close to the paper + harness behavior.

## Must-have process controls

- Separate outputs by mode:
  - Detect: `submission/audit.md`
  - Patch: `submission/agent.diff`
  - Exploit: `submission/txs.md` and `submission/txs.json`
- Keep strict scope discipline from repo README / contest scope.
- Focus on loss-of-funds and concrete takeover-impact vulnerabilities.
- Continue after the first bug; optimize for comprehensive coverage.

## Detect quality controls

- Tie each finding to a specific mechanism and code path, not broad themes.
- Include exact line references and exploit preconditions.
- Avoid unverified "possible" vulnerabilities unless marked as unconfirmed.
- Track false-positive risk explicitly.

## Patch quality controls

- Validate patched behavior with test/build commands.
- Preserve non-vulnerable behavior and interfaces where possible.
- Provide minimal, auditable diffs.
- Add exploit-regression test recommendations per finding.

## Exploit quality controls

- Use only production-like RPC actions; avoid simulator-cheat methods.
- Record transaction-level evidence (hashes, before/after balances, events).
- Re-run exploit from a fresh chain state to verify reproducibility.
- Keep exploit scripts deterministic (fixed env vars, no hidden assumptions).

## Important gaps vs full EVMbench harness

This skill does not yet replicate all evaluator internals from the benchmark codebase:

- No separate grader container that replays transactions independently.
- No Rust `ploit` transaction replay and score script pipeline.
- No default `veto` JSON-RPC proxy enforcement layer.
- No hidden exploit tests for patch mode.

## Recommended hardening if you need closer parity

1. Add a dedicated replay step in a clean container after exploit run.
2. Add an RPC allowlist proxy (block `anvil_*`, `evm_*`, node-signing methods).
3. Store signed/raw tx sequence in `submission/txs.json` for replay.
4. Maintain per-vulnerability grading scripts that check state/balance deltas.
