# Script Usage Cheatsheet

## One-command pipeline

```bash
bash scripts/audit.sh --repo https://github.com/greatpie/smart-contract-audit-skill.git --modes detect,patch
```

## Bootstrap only

```bash
bash scripts/bootstrap.sh --repo https://github.com/greatpie/smart-contract-audit-skill.git --branch main
```

## Detect scaffold

```bash
bash scripts/run_detect.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill
```

## Patch export

```bash
bash scripts/run_patch.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill --strict
```

## Exploit environment

```bash
bash scripts/run_exploit.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill
source /Users/pie/Projects/temp/smartcontract-audit-skill/submission/exploit-env.sh
```

Generate minimal exploit scaffold files:

```bash
bash scripts/generate_exploit_scaffold.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill --framework auto
```

Run built-in Foundry template:

```bash
bash scripts/run_exploit.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill --template foundry
```

Run built-in Hardhat template:

```bash
bash scripts/run_exploit.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill --template hardhat
```

Stop local Anvil:

```bash
bash scripts/run_exploit.sh --repo-dir /Users/pie/Projects/temp/smartcontract-audit-skill --stop
```
