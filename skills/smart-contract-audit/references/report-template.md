# Audit Report Template

## Executive Summary

- Repository:
- Commit / branch audited:
- Scope:
- Method:
- Total high-severity findings:
- Total medium findings (optional):
- Overall risk statement:

## Coverage Summary

- Contracts reviewed:
- Critical value-flow functions reviewed:
- Test/build commands executed:
- Areas not fully validated:

## Findings

### [Severity] [ID] Title

**Confidence:** High / Medium / Low  
**Impact:**  
**Likelihood:**  

**Root cause**  
Explain the flawed assumption or logic.

**Exploit scenario**  
Describe concrete attacker preconditions and step-by-step abuse path.

**Affected code**  
- `path/to/file.sol:line`
- `path/to/other.sol:line`

**Why this is exploitable**  
Show state transitions/value extraction path and constraints.

**Reproduction sketch**  
Provide minimal deterministic steps (commands, tx sequence, or test pseudocode).

**Remediation**  
Give specific fix guidance and mention invariant(s) to preserve.

**Regression test recommendation**  
Describe a test that fails pre-patch and passes post-patch.

## Optional: Patch Notes

- Files changed:
- Security rationale:
- Behavior compatibility notes:

## Optional: Residual Risks

- Unresolved assumptions:
- Components requiring deeper dynamic testing/fork testing:
