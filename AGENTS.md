# AI Agent Guidelines

## Project Overview

Ansible playbooks for configuring OpenWrt devices (Wi-Fi routers). The repo
contains Ansible tasks, Jinja2 templates, shell scripts, and CI workflows.
There are **no tests** — validation is done via linters and pre-commit hooks.

## Build & Run Commands

```bash
# Run the full Ansible playbook against all hosts
cd ansible && ansible-playbook --diff main.yml -i inventory/hosts

# Install Ansible Galaxy dependencies
ansible-galaxy install -r ansible/requirements.yml

# Run pre-commit hooks on all files
pre-commit run --all-files

# Run a single pre-commit hook
pre-commit run <hook-id> --all-files   # e.g.: shellcheck, rumdl-fmt, yamllint

# Lint Ansible playbooks
ansible-lint ansible/

# Lint shell scripts
shellcheck run_openwrt.sh
shellcheck --exclude=SC2317 <file>

# Format shell scripts
shfmt --case-indent --indent 2 --space-redirects <file>

# Lint Markdown
rumdl <file>

# Check links
lychee --cache <file-or-directory>

# Validate GitHub Actions workflows
actionlint
```

## Repository Structure

```text
ansible/                    # Ansible root (run playbooks from here)
├── ansible.cfg             # Ansible config (vault password, no host key check)
├── main.yml                # Entry playbook — imports common + per-host tasks
├── requirements.yml        # Galaxy dependencies (community.general)
├── inventory/hosts         # Inventory file with OpenWrt hosts
├── group_vars/all          # Shared variables (DNS, timezone, subnet)
├── host_vars/              # Per-host variables (encrypted with Ansible Vault)
├── tasks/
│   ├── common.yml          # Shared tasks for all routers
│   └── tasks_<host>.yml    # Host-specific tasks (named by inventory_hostname)
├── handlers/main.yml       # Ansible handlers
└── files/                  # Templates (.j2) and static config files
run_openwrt.sh              # Convenience wrapper to run the playbook
```

## Ansible Style Guide

### Task Naming

- Every task MUST have a descriptive `name:` field
- Use sentence case: `Configure WiFi`, `Install packages`

### Module Usage

- Use fully qualified collection names: `ansible.builtin.copy`,
  `community.general.opkg` — never short names like `copy` or `shell`
- Prefer `ansible.builtin.command` over `ansible.builtin.shell` unless
  pipes/redirects are needed
- Use `ansible.builtin.template` for files with variables (`.j2` extension)
- Use `ansible.builtin.copy` for static files
- Set `changed_when: false` on `command`/`shell` tasks that are read-only
  or idempotent UCI operations

### File Permissions

- Use symbolic notation: `mode: u=rw,g=r,o=r` (not `0644`)
- Sensitive files: `mode: u=rw,g=,o=`

### Secrets & Vault

- Vault password file: `ansible/vault-openwrt.password` (gitignored)
- Host variables with secrets go in `ansible/host_vars/` (vault-encrypted)
- Use `no_log: true` on tasks that handle passwords, API keys, or WiFi
  credentials

### Per-Host Task Files

- Named `tasks/tasks_<inventory_hostname>.yml`
- Included dynamically via `include_tasks: tasks/tasks_{{ inventory_hostname }}.yml`

## YAML Style

- **Indentation**: 2 spaces, no tabs
- **Document start marker**: Not required (skipped in ansible-lint)
- **Line length**: No enforced limit for YAML (skipped in ansible-lint)
- **Comments**: No enforced style for comment spacing
- **Linter**: yamllint with `relaxed` profile, `line-length` disabled
- **Sorted blocks**: Use `# keep-sorted (start|end)`
  comments to maintain alphabetical ordering

## Shell Scripts

- **Shebang**: `#!/usr/bin/env bash`
- **Set options**: `set -eux` (exit on error, undefined vars, trace)
- **Formatter**: `shfmt --case-indent --indent 2 --space-redirects`
- **Linter**: `shellcheck` (SC2317 excluded globally)
- **Variables**: Use uppercase with braces: `${MY_VARIABLE}`

## Markdown

- **Linter**: `rumdl` (Rust-based, config in `.rumdl.toml`)
- **Line length**: 80 characters (code blocks exempt)
- **Heading hierarchy**: Don't skip levels
- **Code fences**: Always include language identifier (`bash`, `console`,
  `json`, `text`)
- **Link checking**: `lychee` validates URLs (config in `lychee.toml`)
- **Excluded from linting**: `CHANGELOG.md`

## GitHub Actions

- **Validate with**: `actionlint` after any workflow change
- **Permissions**: Always use `permissions: read-all`
- **Pin actions**: Use full SHA commits, never tags
  (`uses: actions/checkout@<full-sha> # v6.0.2`)
- **Checkov skip**: `CKV_GHA_7` (workflow_dispatch inputs)

## Version Control

### Commit Messages

- **Format**: Conventional commits — `<type>: <description>`
- **Types**: `feat`, `fix`, `docs`, `chore`, `refactor`, `ci`, `style`,
  `perf`, `test`, `build`, `revert`
- **Subject**: Imperative mood, lowercase, no period, ≤ 72 characters
- **Body**: Optional, wrap at 72 characters, explain what and why
- **Validated by**: commitizen, gitlint, commit-check

### Branches

- Follow [Conventional Branch](https://conventional-branch.github.io/):
  `<type>/<description>`
- Types: `feature/`, `feat/`, `bugfix/`, `fix/`, `hotfix/`, `release/`,
  `chore/`
- Use lowercase, hyphens, no consecutive/trailing hyphens
- No direct commits to `main` or `master` (enforced by pre-commit)

### Pull Requests

- Create as **draft** initially
- Title must follow conventional commit format
- Reference issues with `Fixes`, `Closes`, or `Resolves`

## CI Pipeline (MegaLinter)

Runs on push to non-main branches. Key linters:

| Tool          | Scope                   | Config                  |
| ------------- | ----------------------- | ----------------------- |
| ansible-lint  | Ansible playbooks       | `ansible/.ansible-lint` |
| shellcheck    | Shell scripts + MD code | SC2317 excluded         |
| shfmt         | Shell formatting        | 2-space, case-indent    |
| rumdl         | Markdown                | `.rumdl.toml`           |
| yamllint      | YAML files              | relaxed profile         |
| lychee        | URL validation          | `lychee.toml`           |
| actionlint    | GitHub Actions          | Built-in rules          |
| checkov       | IaC security            | `.checkov.yml`          |
| devskim       | Security patterns       | DS162092,DS137138 skip  |
| trivy         | Vulnerabilities         | HIGH/CRITICAL only      |
| codespell     | Spelling                | Default dictionary      |
| prettier      | Non-Markdown formatting | Excludes `.md` files    |

## Pre-commit Hooks

Configured via `.pre-commit-config.yaml` (symlinked, gitignored). Install:

```bash
pre-commit install && pre-commit install --hook-type commit-msg
```

Key hooks: shellcheck, shfmt, rumdl-fmt, yamllint, prettier, actionlint,
gitleaks, commitizen, codespell, keep-sorted.
