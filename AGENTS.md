# AI Agent Guidelines

## Project Overview

Ansible playbooks for configuring OpenWrt devices (Wi-Fi routers).
Repository: `ruzickap/ansible-openwrt`. License: Apache 2.0.

Target hosts: `gate.xvx.cz` (ASUS RT-AX53U) and
`gate-bracha.xvx.cz` (ZyXEL NBG6617), defined in
`ansible/inventory/hosts`.

## Build / Run / Lint Commands

```bash
# Run the full playbook (requires vault password file)
cd ansible && ansible-playbook --diff main.yml -i inventory/hosts

# Or use the wrapper script
./run_openwrt.sh

# Install Ansible Galaxy dependencies
ansible-galaxy collection install -r ansible/requirements.yml

# Lint Ansible playbooks
ansible-lint ansible/

# Lint shell scripts
shellcheck run_openwrt.sh
shfmt --case-indent --indent 2 --space-redirects -d run_openwrt.sh

# Lint Markdown
rumdl ./*.md

# Check links
lychee --config lychee.toml .

# Lint GitHub Actions workflows
actionlint

# Validate JSON files
jsonlint --comments .github/renovate.json5
```

There is no test suite. This is an infrastructure-as-code repository.
CI runs MegaLinter (`.mega-linter.yml`) which orchestrates all
linting. Validate changes locally with the tools listed above.

## Ansible Code Style

- **Always use FQCN** (Fully Qualified Collection Names) for all
  modules: `ansible.builtin.copy`, `ansible.builtin.command`,
  `community.general.opkg` -- never bare module names
- **Indentation**: 2 spaces, no tabs, throughout all YAML files
- **Variables**: `lowercase_with_underscores` for Ansible variables
  (e.g., `wifi_password`, `usb_disk_mount_path`)
- **Secrets**: Encrypt with Ansible Vault (`!vault`); use `no_log: true`
  on tasks that handle sensitive data
- **Idempotency**: Use `changed_when: false` on commands that do not
  alter state (queries, reads)
- **Templates**: Jinja2 files use `.j2` extension; placed under
  `ansible/files/`
- **Host-specific files**: Organized under
  `ansible/files/<hostname>/etc/...`
- **Host-specific tasks**: `ansible/tasks/tasks_<hostname>.yml`,
  loaded dynamically via `include_tasks`
- **Host-specific variables**: `ansible/host_vars/<hostname>`
- **Global variables**: `ansible/group_vars/all`
- **Handlers**: Defined in `ansible/handlers/main.yml`; use for
  deferred service actions
- **Error handling**: Use `block`/`rescue` pattern where failures
  are expected (e.g., USB disk mounting)
- **List ordering**: Use `# keep-sorted start` / `# keep-sorted end`
  comment markers around sorted lists (e.g., package lists)

### Ansible-lint Exceptions

Configured in `ansible/.ansible-lint.yml`:

- `package-latest` -- allowed
- `yaml[comments]` -- allowed
- `yaml[document-start]` -- allowed
- `yaml[line-length]` -- allowed

## Shell Scripts

- **Linting**: Must pass `shellcheck` (SC2317 is excluded globally)
- **Formatting**: `shfmt --case-indent --indent 2 --space-redirects`
- **Variables**: Use uppercase with braces: `${MY_VARIABLE}`
- **Shell code blocks** in Markdown (tagged `bash`, `shell`, or `sh`)
  are extracted and validated by CI

## Markdown

- Must pass `rumdl` checks (config in `.rumdl.toml`)
- Wrap lines at 72 characters
- Use proper heading hierarchy (no skipped levels)
- Include language identifiers in code fences
- `CHANGELOG.md` is excluded from linting and link checking

## JSON Files

- Must pass `jsonlint --comments`
- `.devcontainer/devcontainer.json` is excluded

## Link Checking

- Uses `lychee` (config in `lychee.toml`)
- Accepts status 200 and 429; caches results
- Excludes: template variables, shell variables, private IPs
- Excluded files: `CHANGELOG.md`, `package-lock.json`

## GitHub Actions Workflows

- Validate with `actionlint` after any workflow change
- Pin all actions to full SHA digests (not tags)
- Use minimal permissions: `permissions: read-all` at workflow level,
  scope per job only as needed
- Use `timeout-minutes` on all jobs

## Security Scanning (CI)

- **Checkov**: Skips `CKV_GHA_7` (workflow_dispatch inputs)
- **DevSkim**: Ignores DS162092, DS137138; excludes `CHANGELOG.md`
- **KICS**: Fails only on HIGH severity (`--fail-on high`)
- **Trivy**: HIGH and CRITICAL only, ignores unfixed vulnerabilities
- Never commit plaintext secrets; use Ansible Vault encryption

## Version Control

### Commit Messages

Conventional commit format. Subject line rules:

- Format: `<type>: <description>`
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`,
  `style`, `perf`, `ci`, `build`, `revert`
- Imperative mood, lowercase, no trailing period
- Maximum 72 characters (subject); 72 characters (body lines)
- Body: explain what and why, reference issues with
  `Fixes`/`Closes`/`Resolves`

### Branching

Conventional branch format: `<type>/<description>`

- `feature/` or `feat/`, `bugfix/` or `fix/`, `hotfix/`,
  `release/`, `chore/`
- Lowercase, hyphens, no consecutive/leading/trailing hyphens
- Include issue number when applicable:
  `feature/issue-123-add-wifi-config`

### Pull Requests

- Always create as **draft** initially
- Title must follow conventional commit format
- Include clear description and link related issues

## Quality Checklist

- [ ] All YAML uses 2-space indentation
- [ ] Ansible modules use FQCN
- [ ] Secrets are Vault-encrypted with `no_log: true`
- [ ] Shell scripts pass `shellcheck` and `shfmt`
- [ ] Markdown wraps at 72 characters and passes `rumdl`
- [ ] GitHub Actions pinned to SHA with `timeout-minutes`
- [ ] Commit message follows conventional format
