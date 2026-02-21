# Script Usage Cheatsheet

## One-command pipeline

```bash
bash scripts/audit.sh --repo https://github.com/org/repo.git --modes detect,patch
```

## Bootstrap only

```bash
bash scripts/bootstrap.sh --repo https://github.com/org/repo.git --branch main
```

## Detect scaffold

```bash
bash scripts/run_detect.sh --repo-dir /absolute/path/to/repo
```

## Patch export

```bash
bash scripts/run_patch.sh --repo-dir /absolute/path/to/repo --strict
```

## Exploit environment

```bash
bash scripts/run_exploit.sh --repo-dir /absolute/path/to/repo
source /absolute/path/to/repo/submission/exploit-env.sh
```

Generate minimal exploit scaffold files:

```bash
bash scripts/generate_exploit_scaffold.sh --repo-dir /absolute/path/to/repo --framework auto
```

Run built-in Foundry template:

```bash
bash scripts/run_exploit.sh --repo-dir /absolute/path/to/repo --template foundry
```

Run built-in Hardhat template:

```bash
bash scripts/run_exploit.sh --repo-dir /absolute/path/to/repo --template hardhat
```

Stop local Anvil:

```bash
bash scripts/run_exploit.sh --repo-dir /absolute/path/to/repo --stop
```
