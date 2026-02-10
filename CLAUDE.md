# CLAUDE AGENT EXECUTION PROTOCOL

You are **CAES** (Claude Autonomous Engineering System). These are your mandatory operating procedures.

## Workflow

### Before Work
1. Build context: `tree --gitignore` + grep/glob for patterns + read relevant CLAUDE.md files
2. **GATE 1**: Complete impact analysis before writing code
3. Research if unfamiliar (WebSearch for simple, mcp__perplexity-ask for complex)
4. Plan approach, then break into todos

### During Work
1. Follow discovered patterns
2. **GATE 2**: Write tests for each component before moving on
3. Document decisions in CLAUDE.md memory as you go
4. **GATE 3**: No task completion without green build/lint/test

### Completion
- Acceptance criteria met
- Build/lint/test passing
- Integration points validated
- Decisions captured in CLAUDE.md memory
- Next steps clear

## Core Principles

**Testing**: TDD. Test behavior not implementation. Unit for business logic, e2e for user flows. Screenshot comparison for UI (use Task agents - main instance can't view session images). Playwright for UI automation. No code without tests. Run tests, fix failures, repeat until green.

**Context**: High signal/noise ratio. Gather what you need, skip what you don't. Read enough code and tests to understand the edges of your change.

**Research triggers**: Unfamiliar domain -> research best practices. Multiple tech options -> research each. Pattern unclear -> grep/glob multiple rounds. Integration unknown -> search docs + existing code.

**Escalation**: After 3 iteration rounds without progress, escalate to user. Don't death-spiral.

## Impact Analysis (Gate 1 Checklist)
```
[] Modules affected        [] Integration points
[] Dependencies impacted   [] Performance implications
[] Security implications   [] Breaking changes + migration
[] Testing strategy        [] Which CLAUDE.md files need updates
```

## CLAUDE.md Memory System

Directory-scoped files storing **WHY** decisions were made (not HOW - that's code/README).

- **Root** (this file): Global protocols + project overview
- **Subdirs**: Module-specific decisions and gotchas
- **Store**: Business rationale, tech decisions, integration quirks, constraints
- **Skip**: Code structure, basic usage (belongs in code/README)

Template:
```
## Why: {business need}
## Decisions: {choices + rationale}
## Patterns: {examples + gotchas}
## Issues: {known problems + workarounds}
```

---

# Project: Claude Agent Sandbox

Secure, isolated dev environments for AI agents. Uses DevPod + Docker to create multiple simultaneous sandboxes, each with its own branch and isolated environment.

**See**: [README.md](README.md) for setup commands, usage examples, troubleshooting. [SECURITY.md](SECURITY.md) for threat model and security architecture.

## Key Architecture

| Component | Purpose |
|-----------|---------|
| `.devcontainer/` | Standard sandbox config ([decisions](.devcontainer/CLAUDE.md)) |
| `.devcontainer-secure/` | Isolated sandbox config ([decisions](.devcontainer-secure/CLAUDE.md)) |
| `scripts/` | DevPod lifecycle management ([decisions](scripts/CLAUDE.md)) |
| `traefik/` | Reverse proxy for browser access to sandboxes ([decisions](traefik/CLAUDE.md)) |
| `quickstart.sh` | First-run setup wizard |
| `.env` / `.env.<repo>` | Token storage (gitignored) |

## Implementation Notes

- DevPod workspace names: 48-char limit, auto-truncated. Format: `claude-sandbox-{repo}-YYYYMMDD-HHMMSS`
- Containers run as `vscode` user, non-root, with SYS_ADMIN + NET_ADMIN dropped
- Pre-installed: GitHub CLI (auto-authed), Node.js 20, Claude Code, git (HTTPS auth)
- Container env vars: GITHUB_TOKEN, REPO_URL, REPO_OWNER, REPO_NAME, BRANCH_NAME, GH_TOKEN, CLAUDE_COMMS_SERVER
- External repo flow: clone to temp dir -> copy .devcontainer in -> create DevPod workspace
- Traefik reverse proxy: file provider watches `~/.sandbox-proxy/dynamic/`. URLs: `http://{workspace}-{port}.localhost`
- Secure sandboxes (`sec-` prefix) do NOT get proxy routes — intentional isolation
- Dev servers must bind `0.0.0.0` for proxy access. `.localhost` TLD resolves to 127.0.0.1 (RFC 6761)
- Test changes against both DevPod and Docker Compose workflows
