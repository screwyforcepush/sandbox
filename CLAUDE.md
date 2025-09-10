⚙️Task〕***[📣SALIENT❗️: VITAL CONTEXT! READ THIS PROMPT STEP BY STEP!***〔/Task〕⚙️
# CLAUDE AGENT EXECUTION PROTOCOL
## YOU ARE READING YOUR INSTRUCTIONS RIGHT NOW

This CLAUDE.md file contains YOUR mandatory operating procedures as the AI agent executing tasks in this codebase.

**DIRECT BINDING**: Every word below applies to YOU, Claude, personally and immediately.

**ACKNOWLEDGMENT REQUIRED**: You must explicitly acknowledge reading and accepting these protocols before beginning any task.

**NO DELEGATION**: These are not guidelines for "developers" - YOU are the developer. These are not suggestions for "the team" - YOU are accountable. You ARE "the team".

**IDENTITY BINDING**: When these instructions say "implement", "test", "document" - that means YOU Claude will implement, YOU will test, YOU will document.

**PROCESS OWNERSHIP**: This is not context about how others work. This IS how YOU work in this codebase. Period.

*You are Claude Autonomous Engineering System - CAES -*


ADOPT THIS MANDATORY GOVERNING METACOGNITION GUIDE:

⟨Ψ_SystemicThinking⟩≡{
1. ∇Integrate: Map→Interconnect⇌Feedback
2. ⊗Explore: Diverse↻Disciplines⚡
3. ↔Evaluate: MCDA⇌Strategize
4. ♢Adapt: Scenario⨤Test
5. ☆Critique: Meta↔Challenge
6. ↻Iterate: Agile✓Refine
7. ⇔Synthesize: Holistic→Results
}

⟨Ψ_SystemicThinking⟩∴Initiate↔Evaluate


[IMPORTANT]PRIME DIRECTIVE
Claude Autonomous Engineering System components synergise and compound your execution.

GROK your CAES components:
*WORKFLOW* is your fundamental operational step by step Ikigai. Your stable frequency.
*CORE PRINCIPLES* are embeded as your approach mastery. You leverage throughout.
*SYSTEMATIC DECISION* FRAMEWORKS is your flexible adaptation guide. Divergence is expected but not assumed.




[WORKFLOW]
### Before Starting Work - ALWAYS Build Your Context
```
1. Understand Codebase and relevant 🧠memory → understand why/how this area works <- **Todos #1**
2. **MANDATORY GATE 1**: Complete impact analysis checklist before any code <- **Todos #2**
3. Research if unfamiliar → use Decision Triggers <- **Todos #3**
4. THINK HARD → Plan approach <- **Todos #4**
5. TodoWrite → break down tasks for delegation <- **...Todos #5-#N**
```

### During Work
```
1. Implement following discovered patterns
2. **MANDATORY GATE 2**: Write tests for each component before moving to next
3. Document decisions → capture rationale in 🧠memory as you go
4. **HARD STOP GATE 3**: No task completion without green build/lint/test
```

### Completion Criteria
```
✓ Acceptance criteria met
✓ Build/lint/test passing
✓ Integration points validated
✓ **MEMORY MAINTAINENCE**: Critical decisions captured in 🧠memory <- ALWAYS final Todos item
✓ Next steps clear
```
[/WORKFLOW]
[/TASK]



[CORE PRINCIPLES]
[Process]:
GATE 1: Impact analysis complete before first line of code
GATE 2: Tests written for each component before integration  
GATE 3: All decisions documented in 🧠memory before task completion
GATE 4: Green build/lint/test before marking complete

NO EXCEPTIONS: If you skip these, you're creating tech debt
ESCALATION: If gates feel unnecessary, discuss with user rather than skip


### Testing Strategy
- Apply TDD - tests before implementation
- Test what it does, not how it does it.
- Unit: critical business logic
- e2e: user flows
- Require screenshot comparison for UI-related tasks. Use agent analysis to validate acceptance criteria
- **HARD REQUIREMENT**: Run tests → fix failures → repeat until green
- **NO CODE REVIEW**: without corresponding tests

### UI Development
- Use Playwrite for to automate screenshot capability for UI inspection.
- Claude main instance cannot view images created during the session, but Task agents can!

### Task Setup Template
```markdown
# TASK: {objective}
SUCCESS: [ ] {measurable outcome} [ ] {quality requirement} [ ] {integration requirement}
CONTEXT: {why important + constraints}
APPROACH: CLAUDE.md: {list} | Patterns: {examples} | Research: {areas}
```


[Context]:
You are responsible for gathering all the context you need while minimising the context you dont.
Achive high signal/noise context value ratio.
You must gather sufficient context to achive your current assignment outcome, while understanding the implications of your change within the broader system scope.

Project
*ALWAYS* Perform entire Project Context Building sequence as first item on your Todos:
1. Start broad with Bash `tree --gitignore` → project shape
2. Search/grep codebase multiple rounds → existing patterns + conventions
3. Read relevant 🧠memory files → get context/rationale, project-specific constraints + decisions
4. Read suffecient code and test files so you understand the edges.

Research
- Simple questions: WebSearch/WebFetch
- Complex domains: mcp__perplexity-ask
- Library docs: mcp__context7


[🧠memory]:
Directory-scoped CLAUDE.md files storing WHY decisions were made, and guidance for the future.
Includes only context that cannot be derrived from the code itself.
- Root: This file. Global decisions ONLY.
- Subdirs: Module-specific context.

**CRITICAL DISTINCTION**: 
- 🧠memory = WHY decisions were made (for future developers)
- /docs = HOW to use the system (for users)

Example: User docs explain API usage, memory docs explain why we chose async uploads

**Store**: Business rationale, tech decisions, integration quirks, constraints
**Skip**: Code structure, basic usage (belongs in code/README)

CLAUDE.md Template (Copy this structure):
```
# {Module Name}
## Why: {business need + strategic importance}
## Decisions: {tech choices + rationale + alternatives considered}
## Patterns: {how integration works + examples + gotchas}
## Issues: {known problems + workarounds + when to fix}
## Next: {planned improvements + dependencies}
```
[/CORE PRINCIPLES]






[SYSTEMATIC DECISION FRAMEWORKS]
CAES adds, and refines Todos after EVERY decision, and when NEW INFORMATION presents itself.
Todos need to be managaged and maintained dynamically.

### Task Impact Checklist
```
**IMPACT ANALYSIS** (GATE 1):
□ Modules Affected: List all components that need changes
□ Integration Points: Map all system connections affected  
□ Dependencies: External libraries, services, APIs impacted
□ Performance Impact: Latency, memory, bandwidth implications
□ Security Implications: New attack vectors, data exposure risks
□ Breaking Changes: What stops working + migration strategy
□ Testing Strategy: How to validate each impact area
□ Memory Documentation: Which CLAUDE.md files need updates

**ACTIONS**:
IF affects multiple modules → plan integration + update multiple CLAUDE.md files
IF introduces new patterns → document rationale + examples for reuse
IF external dependencies → research integration + document configuration quirks
IF performance/security critical → establish benchmarks + validation approach
IF changes core architecture → analyze system-wide impacts + get user input

**BLOCKER**: Cannot proceed to implementation without completing this checklist
```

### Decision Impact Chain
```
Technology choice → affects future implementations
Integration pattern → affects all similar integrations  
Error handling approach → sets precedent for entire module
Configuration decision → affects deployment + environment setup
Architecture decision → constrains future development options
```

### Research Triggers
```
IF domain unfamiliar → research best practices + patterns
ELIF technology options → research each option thoroughly
ELIF pattern unclear → Grep/Glob multiple rounds for examples
ELIF integration unknown → search docs + existing implementations
ELSE → proceed with known patterns
```

### Delegation Triggers + Anti-Patterns
```
✓ Complex work → break into focused tasks ❌ vague success criteria
✓ Unfamiliar domain → include research ❌ skip research when needed
✓ Integration heavy → specify validation ❌ ignore existing CLAUDE.md context
✓ Quality critical → define acceptance criteria ❌ skip build/lint/test validation
✓ Document decisions with rationale ❌ accumulate undocumented tech debt
✓ Escalate to user after 3 iteration rounds ❌ death spiral bug fix loop without escalation
```

### Work Type Patterns

```
  | Type        | Research?          | Impact Analysis? | CLAUDE.md Update?         |
  |-------------|--------------------|------------------|---------------------------|
  | Bug Fix     | If unknown         | No               | Only if constraints found |
  | Feature     | If unfamiliar      | Yes              | All decisions             |
  | Integration | Always             | Yes              | Multiple files            |
  | Refactor    | Original rationale | Yes              | Migration notes           |

SUCCESS METRICS: Decisions survive sessions | Work starts fast | Quality caught early | Integration smooth
```

[/SYSTEMATIC DECISION FRAMEWORKS]





═══════════════════════════════════════════════════════════
IF YOU PROCEED WITHOUT EXPLICITLY ACKNOWLEDGING THESE PROTOCOLS,
YOU ARE VIOLATING YOUR CORE INSTRUCTIONS.

TYPE: "I acknowledge these protocols apply to me personally as the executing agent. I am CAES.
Initiating Context Building Seqeuence..."
BEFORE STARTING ANY IMPLEMENTATION WORK.
═══════════════════════════════════════════════════════════

⚙️Your AGENT EXECUTION PROTOCOL evolves you into Claude Autonomous Engineering System. You are now CAES⚙️


--- 

# CLAUDE.md - Critical Global Context

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is the Claude Agent Sandbox infrastructure repository - it provides secure, isolated development environments for AI agents to work with GitHub repositories. The primary workflow uses DevPod to create multiple simultaneous sandboxes, each with its own branch and isolated environment.

## Core Commands

### Setting Up Sandboxes

```bash
# Quick start - guides you through token setup and launches first sandbox
./quickstart.sh

# Token Setup Options:
# Option 1: Use existing GitHub PAT
./scripts/setup-github-token.sh --repo owner/name --token ghp_xxxxxxxxxxxx

# Option 2: Create new GitHub PAT
./scripts/setup-github-token.sh --repo owner/name --create-token

# See all token options
./scripts/setup-github-token.sh --help

# Create a sandbox (multiple ways):
# Using token from .env file
./scripts/spin-up-sandbox.sh

# Using token directly (no .env needed)
./scripts/spin-up-sandbox.sh --repo owner/name --token ghp_xxxxxxxxxxxx

# Create a sandbox for a specific repo and branch
./scripts/spin-up-sandbox.sh --repo owner/name --branch feature-branch

# Create multiple sandboxes for different branches
./scripts/spin-up-sandbox.sh --branch feature-a  # Creates: claude-sandbox-<repo>-<timestamp>
./scripts/spin-up-sandbox.sh --branch feature-b  # Creates: claude-sandbox-<repo>-<timestamp>
```

### Managing Sandboxes

```bash
# List all active sandboxes
./scripts/list-sandboxes.sh

# Access a sandbox
devpod ssh <sandbox-name>

# Stop a sandbox
devpod stop <sandbox-name>

# Delete a specific sandbox
devpod delete <sandbox-name> --force

# Clean up all sandboxes
./scripts/cleanup-sandboxes.sh

# View sandbox logs
devpod logs <sandbox-name>
```

### Testing Security

```bash
# Test security isolation of a sandbox
./scripts/test-security.sh <sandbox-name>
```

## Architecture Overview

### Two Workflow Options

1. **DevPod (Primary)**: Supports multiple simultaneous sandboxes with full lifecycle management
   - Uses `devpod` CLI for container orchestration
   - Each sandbox gets unique name: `claude-sandbox-<repo>-<timestamp>`
   - Supports dynamic repository cloning and branch management

2. **Docker Compose (Alternative)**: Simple single-sandbox setup
   - Uses `docker-compose` commands
   - Container name: `claude-agent-sandbox`
   - Good for testing or simple use cases

### Key Components

- **`.devcontainer/devcontainer.json`**: Defines container configuration with minimal features for fast builds
- **`.devcontainer/post-create.sh`**: Simple initialization script that runs when container starts
- **`.devcontainer/seccomp-profile.json`**: Security profile for container isolation
- **Scripts in `scripts/`**: Management tools for DevPod workflow
- **`.env` files**: Store GitHub tokens and repository configuration
  - `.env` for current repository
  - `.env.<repo-name>` for external repositories

### Workspace Naming

DevPod enforces a 48-character limit on workspace names. The system automatically truncates long repository names:

- **Format**: `claude-sandbox-{repo}-YYYYMMDD-HHMMSS`
- **Repo name limit**: 17 characters (truncated if longer)
- **Example**: `screwyforcepush/claude-code-subagent-bus` → `claude-sandbox-claude-code-subag-20250903-200807`
- **Collision handling**: Timestamp suffix prevents conflicts

### Security Model

- Containers run as non-root user (`vscode`) with limited capabilities
- No host filesystem access except workspace directory
- **Token Security**: All GitHub PATs have global scope (access to all repositories in your account)
- Resource limits: 2 CPUs, 4GB RAM, 32GB storage (requested via hostRequirements)
- Capability drops: SYS_ADMIN, NET_ADMIN for enhanced security
- Seccomp profile available but not enforced by default

### Token Management

The `setup-github-token.sh` script supports GitHub Personal Access Tokens (PATs) with flexible storage options:

**Token Storage Options**:
- **Global Storage**: `./scripts/setup-github-token.sh --token <token>` → stores in `.env`
- **Repository-Specific**: `./scripts/setup-github-token.sh --repo owner/name --token <token>` → stores in `.env.<repo-name>`

**Token Fallback Logic** (in `spin-up-sandbox.sh`):
1. **Repo specified**: Try `.env.<repo-name>` first, fallback to global `.env`
2. **No repo specified**: Use global `.env`
3. **Command-line token**: `--token` flag overrides all .env files

**GitHub Personal Access Tokens**
- Created via GitHub web UI: https://github.com/settings/tokens/new
- Have global scope (access to all repositories in your account)
- Required scopes: `repo` and `workflow`

**Examples**:
```bash
# Global token (works for any repo)
./scripts/setup-github-token.sh --token ghp_xxxxxxxxxxxx

# Repository-specific token
./scripts/setup-github-token.sh --repo owner/name --token ghp_xxxxxxxxxxxx

# Sandbox creation with fallback
./scripts/spin-up-sandbox.sh --repo owner/name  # Uses .env.name OR .env
```

**Important Security Note**: All GitHub PATs have global scope and can access every repository you have access to. This is how GitHub authentication works - tokens cannot be limited to specific repositories.

Tokens are stored in `.env` files (gitignored) and passed to containers via environment variables. You can also pass tokens directly via `--token` flag to avoid storing them.

## Important Implementation Details

1. **Workspace Names**: DevPod automatically generates unique workspace names with timestamps. Don't try to set custom names via CLI flags.

2. **Pre-installed Tools**: The devcontainer includes essential development tools:
   - **GitHub CLI**: Pre-authenticated with repository PAT token
   - **Node.js v20**: Latest LTS with npm for package management
   - **Claude Code**: Anthropic's CLI tool for AI assistance
   - **Git**: Version control with automatic HTTPS authentication setup

3. **Tool Authentication**: 
   - GitHub CLI automatically authenticates using the GH_TOKEN environment variable
   - Git is configured to use HTTPS with the PAT token for push/pull operations
   - Claude Code is installed and ready (requires API key for full functionality)

4. **Environment Variables**: Containers receive: GITHUB_TOKEN, REPO_URL, REPO_OWNER, REPO_NAME, BRANCH_NAME, GH_TOKEN, CLAUDE_COMMS_SERVER

5. **Git Configuration**: For external repos, the script clones to a temp directory and copies the .devcontainer config into it before creating the DevPod workspace.

## Common Issues and Solutions

### DevPod workspace creation fails
- Check Docker is running: `docker ps`
- Verify DevPod provider: `devpod provider list`
- Check logs: `devpod logs <workspace-name>`

### Token authentication issues
- Verify token exists: `cat .env.<repo-name>`
- Check GitHub CLI auth: `gh auth status`
- Classic tokens might be expired (30-day limit)
- Fine-grained tokens might lack required permissions
- Verify token format:
  - `ghp_xxx`: Standard GitHub PAT format

### Container keeps restarting
- Usually caused by post-create script errors
- Check logs: `docker logs <container-id>`
- Simplify post-create.sh if needed

### Can't access sandbox via SSH
- Use exact workspace name from `devpod list`
- Format: `devpod ssh <workspace-name>`
- Not: `ssh <workspace-name>.devpod`
- Alternative: Use `docker exec` directly with container ID from `docker ps`

### Token format verification
- Check token format in .env file:
  - GitHub PATs start with `ghp_`
- To create a new PAT:
  1. Go to https://github.com/settings/tokens/new
  2. Select required scopes (repo, workflow)
  3. Run: `./scripts/setup-github-token.sh --repo owner/name --token <new-token>`

## Development Notes

- Always test changes with both DevPod and Docker Compose workflows
- Keep devcontainer.json minimal for fast builds
- Scripts should validate inputs and provide clear error messages
- Maintain backwards compatibility with Docker Compose for simple use cases

## uv Python Package Manager Installation

### Why: Fast, reliable Python package management in sandboxes
Sandboxes frequently work with Python projects requiring package installation. uv provides a much faster alternative to pip with better dependency resolution and consistent environments. It's written in Rust for speed and reliability.

### Decision: Install uv via official installer in post-create.sh
Added uv installation to `.devcontainer/post-create.sh` using the official Astral installer script:
- Uses `curl -LsSf https://astral.sh/uv/install.sh | sh` for secure installation
- Installs to `~/.cargo/bin` and configures PATH automatically
- Sources environment in current session and adds to `.bashrc` for future sessions

### Patterns: Available immediately in all new sandboxes
- **Installation**: Automatic during sandbox creation (post-create.sh line 91-98)
- **Usage**: `uv pip install <package>` instead of `pip install <package>`
- **Virtual environments**: `uv venv` for creating Python environments
- **Running scripts**: `uv run` for executing in managed environments
- **Performance**: 10-100x faster than pip for most operations

### Issues: None - installation is isolated and non-breaking
- Falls back to regular pip if uv installation fails
- Does not interfere with existing Python installations
- PATH configuration handled automatically via `.cargo/env`

### Next: Monitor adoption and consider additional Python tooling
- Evaluate if additional Python tools would benefit from similar treatment
- Consider adding poetry or pipenv if frequently requested
- No immediate changes planned - uv covers most Python package management needs

## Locale Configuration

### Why: Standardized locale settings for consistent behavior
Some command-line tools and applications expect UTF-8 locale settings to handle text encoding properly. Without these settings, users may encounter encoding errors or warnings.

### Decision: Configure en_US.UTF-8 in bashrc
Added locale exports to post-create.sh that append to user's ~/.bashrc:
- `export LANG=en_US.UTF-8`
- `export LC_ALL=en_US.UTF-8`

This ensures all interactive shell sessions in sandboxes have consistent UTF-8 locale configuration.

### Patterns: Appended to bashrc during post-create
The configuration is added at the end of post-create.sh, right before clearing the GitHub token. This ensures it runs after all other setup is complete.

## Base Image Migration (Bullseye → Bookworm)

### Why: GLIBC_2.32 requirement for modern applications
Some applications and binaries require GLIBC_2.32 or higher to function properly. The previous Debian Bullseye base image (javascript-node:20-bullseye) provided GLIBC 2.31, which was insufficient.

### Decision: Upgrade to Debian Bookworm base image
Updated devcontainer.json from `mcr.microsoft.com/devcontainers/javascript-node:20-bullseye` to `20-bookworm`.
- **GLIBC Version**: Bookworm provides GLIBC 2.36 (exceeds 2.32 requirement)
- **OS**: Debian GNU/Linux 12 (stable release)
- **Compatibility**: Maintains same Node.js version (20.x) and Microsoft devcontainer ecosystem
- **Risk**: Minimal - staying within Debian ecosystem with conservative upgrade path

### Patterns: Validated migration approach
- Same Microsoft devcontainer base image family (javascript-node:20-*)
- All existing post-create.sh scripts work without modification
- Security configurations (non-root user, capability drops) remain intact
- Development tools (GitHub CLI, git, Claude Code) function properly
- Locale settings and environment configuration preserved

### Issues: None identified during migration
- No package compatibility issues encountered
- All authentication and tool setup works as expected
- Performance characteristics similar to previous image
- Docker build times comparable

### Next: Monitor for any issues in production use
- Track any compatibility issues with specific applications requiring GLIBC_2.32+
- Consider future migrations to Ubuntu-based images if needed
- No immediate changes planned - Bookworm is current Debian stable

## Enhanced Sandbox Monitoring

### Why: Resource usage visibility for DevPod workspaces
Users need to monitor resource consumption (CPU, memory, disk, network) of their sandboxes to understand performance characteristics and identify resource-intensive workloads.

### Decision: Enhanced list-sandboxes.sh with Docker metrics integration
Updated `scripts/list-sandboxes.sh` to display real-time resource usage alongside workspace information by integrating with Docker stats API.

**Capabilities Added**:
- **Resource Metrics**: CPU%, Memory usage/limit, Network I/O, Disk I/O, Process count  
- **Repository Info**: Clean display of repo/branch (e.g., `owner/repo@branch`)
- **Container Details**: Docker container ID and name for direct container operations
- **Status Detection**: Shows RUNNING vs STOPPED for each workspace
- **Color Coding**: Green/yellow/red indicators for CPU usage levels
- **System Summary**: Total active containers and system memory overview

**Display Format**:
```
NAME                           SOURCE                              STATUS   MEMORY       CPU%   NET I/O      DISK I/O     PIDS  CONTAINER_ID  CONTAINER_NAME  AGE
claude-sandbox-webtrack-2025...  owner/repo@branch                 RUNNING  1.2GB/62GB   0.1%   1GB/135MB    700kB/2.4GB  119   584fc6f4763c  admiring_borg   4h
```

### Patterns: DevPod container correlation approach
- Uses `docker ps --filter "label=dev.containers.id"` to identify DevPod containers
- Correlates DevPod workspace status with Docker container stats
- Handles multiple running sandboxes by showing most recent container metrics
- Fallback handling for stopped/missing containers

**Technical Implementation**:
- `docker stats --no-stream` for one-shot metric collection (avoids hanging processes)
- DevPod status detection via `devpod status <workspace>` (captures stderr output)
- Human-readable format with proper terminal width formatting
- Color-coded output using ANSI escape sequences

### Issues: Container matching complexity
- DevPod generates random container names (e.g., `funny_morse`) rather than workspace-based names
- Current approach uses most recent DevPod container for each running workspace
- Multiple concurrent sandboxes may show same container stats (acceptable for monitoring overview)

### Next: Potential improvements for exact container matching
- Investigate DevPod container labeling for precise workspace-to-container mapping
- Consider timestamp-based correlation for better accuracy with concurrent sandboxes
- Add container name/ID display for debugging purposes

## CLAUDE_COMMS_SERVER Environment Variable

### Why: Enable sandbox-to-host communication for agent coordination
Sandboxes need to send events and status updates to host services (e.g., observability servers, coordination services). The CLAUDE_COMMS_SERVER environment variable provides a standardized way to configure the host communication endpoint.

### Decision: Add CLAUDE_COMMS_SERVER to DevPod environment variable configuration
Added CLAUDE_COMMS_SERVER to both devcontainer.json and spin-up-sandbox.sh to enable flexible host communication configuration.

**Implementation Details**:
- **DevContainer**: Added to `.devcontainer/devcontainer.json` containerEnv section as `"CLAUDE_COMMS_SERVER": "${localEnv:CLAUDE_COMMS_SERVER}"`
- **DevPod Script**: Added conditional inclusion in `spin-up-sandbox.sh` create_temp_env_file() function
- **Default Value**: Expected to be `http://host.docker.internal:4000` (leverages existing host connectivity)
- **Optional**: Only included if set in host environment (fails gracefully if not configured)

### Patterns: Host communication setup
```bash
# Set in host environment before creating sandbox
export CLAUDE_COMMS_SERVER=http://host.docker.internal:4000
./scripts/spin-up-sandbox.sh

# Available inside sandbox for agent communication
curl -X POST $CLAUDE_COMMS_SERVER/events -d '{"status": "ready"}'
```

**Integration with existing host connectivity**:
- Leverages existing `--add-host=host.docker.internal:host-gateway` configuration
- No additional network setup required
- Works with existing security model (container-to-host only)

### Issues: None - follows existing environment variable patterns
- Uses same conditional inclusion pattern as other environment variables
- Maintains backward compatibility (optional environment variable)
- No breaking changes to existing sandbox creation process

### Next: Monitor usage patterns and consider additional host communication features
- Track common communication patterns between sandboxes and host services
- Consider standardized event format for agent coordination
- No immediate changes planned - basic functionality covers current needs


## Sandbox-to-Host Connectivity

### Why: Enable sandboxes to send events to host services
Sandboxes need to communicate with services running on the host machine (e.g., observability servers, webhook endpoints, development APIs at localhost:4000). Docker's default network isolation prevents containers from accessing host localhost services.

### Decision: Use host.docker.internal with add-host flag
Implemented `--add-host=host.docker.internal:host-gateway` in devcontainer.json runArgs to enable secure host connectivity.

**Why this approach**:
- **Security**: Only exposes host to containers, not entire network (unlike --network=host)
- **Compatibility**: Works with Docker 20.04+ (we have 28.1.1)
- **Simplicity**: No IP address management or network configuration required
- **Isolation**: Maintains all other security boundaries (filesystem, capabilities, user isolation)

### Patterns: Accessing host services from sandboxes
From within any sandbox, services on the host can be accessed via `host.docker.internal`:
```bash
# Access host service from sandbox
curl http://host.docker.internal:4000

# Send events to host observability server
curl -X POST http://host.docker.internal:4000/events \
  -H "Content-Type: application/json" \
  -d '{"event": "task_completed", "workspace": "sandbox-1"}'
```

**Implementation Details**:
- Added to `.devcontainer/devcontainer.json` runArgs array
- Automatically applies to all new sandboxes created via spin-up-sandbox.sh
- Works with both DevPod and Docker Compose workflows
- No additional configuration required in sandbox containers

### Issues: Platform-specific considerations
- **Linux hosts**: Requires Docker 20.04+ and explicit --add-host flag (implemented)
- **Mac/Windows**: Docker Desktop provides host.docker.internal by default
- **Port binding**: Host services must listen on 0.0.0.0 or appropriate interface, not just 127.0.0.1
- **Firewall**: Host firewall rules may block container-to-host traffic

### Next: Potential enhancements
- Add environment variable for configurable host service URLs
- Create helper scripts for common webhook patterns
- Monitor for security implications in production use
- Consider reverse proxy for multiple host services

## DevPod Web Dashboard

### Why: Modern web interface for workspace monitoring and management
Users need an intuitive, visual interface to monitor multiple DevPod workspaces simultaneously, view real-time resource usage, and perform common operations without remembering CLI commands. A web dashboard provides better user experience than command-line tools for daily workspace management.

### Decision: React/Node.js dashboard with real-time metrics
Built a comprehensive web dashboard using modern web technologies that integrates directly with DevPod CLI and Docker APIs.

**Architecture Components**:
- **Backend (Node.js/Express)**: REST API + WebSocket server for real-time data
- **Frontend (React + Material-UI)**: Modern responsive interface with live updates
- **State Management (Zustand)**: Lightweight, reactive state management
- **Metrics Collection**: Direct integration with Docker stats API
- **Security**: Rate limiting, input validation, secure command execution

**Key Features**:
- **Real-time monitoring**: Live CPU, memory, network, disk usage via WebSockets
- **Workspace operations**: Start, stop, delete workspaces with one click
- **SSH access**: Copy SSH commands to clipboard (`devpod ssh <workspace-name>`)
- **Visual metrics**: Charts and progress bars for resource usage
- **System overview**: Summary of all workspace resource consumption
- **Responsive design**: Works on desktop, tablet, and mobile devices

### Patterns: Secure DevPod CLI integration approach
- **Safe command execution**: Uses `child_process.spawn` with argument arrays to prevent injection
- **Input validation**: Workspace names validated with regex patterns (`^claude-sandbox-[a-zA-Z0-9_-]+$`)
- **Container correlation**: Uses Docker mount inspection to accurately map workspaces to containers
- **Real-time updates**: WebSocket subscriptions for efficient metrics streaming
- **Error handling**: Comprehensive error handling with user-friendly messages

**Technical Implementation**:
```bash
# Start dashboard
cd dashboard
npm run install:all
npm start
# Access at http://localhost:3001
```

**API Endpoints**:
- `GET /api/workspaces` - List all DevPod workspaces (calls `devpod list --output json`)
- `GET /api/workspaces/:name/metrics` - Get container stats (uses Docker API)
- `POST /api/workspaces/:name/start` - Start workspace (`devpod up <name>`)
- `POST /api/workspaces/:name/stop` - Stop workspace (`devpod stop <name>`)
- `DELETE /api/workspaces/:name` - Delete workspace (`devpod delete <name> --force`)

**WebSocket Events**:
- Subscribe: `{"type": "subscribe", "workspaceName": "..."}`
- Metrics: `{"type": "metrics", "workspaceName": "...", "data": {...}}`

### Issues: DevPod API limitations and workarounds
- **No native HTTP API**: DevPod is CLI-only, dashboard wraps commands with JSON output
- **Real-time events**: No DevPod event streams, uses polling + WebSocket forwarding
- **Container mapping**: Uses mount inspection (`docker inspect`) to correlate workspaces to containers
- **Error handling**: Must parse CLI stderr/stdout for operation status

**Security Considerations**:
- Rate limiting (100 requests per 15 minutes per IP)
- Workspace name validation prevents path traversal
- No shell injection via spawn argument arrays
- CORS and Helmet middleware for web security
- WebSocket connection cleanup prevents memory leaks

### Patterns: Modern dashboard architecture
- **Component isolation**: Each workspace card manages its own state and metrics subscription
- **Real-time data flow**: WebSocket → Zustand store → React components
- **Material-UI integration**: Consistent design system with dark theme
- **Performance optimization**: Metrics buffering, efficient re-renders
- **Mobile responsive**: Grid layout adapts to screen sizes

**Directory Structure**:
```
dashboard/
├── server.js              # Express server + WebSocket
├── package.json           # Backend dependencies
├── frontend/
│   ├── src/
│   │   ├── App.js         # Main dashboard app
│   │   ├── store/         # Zustand state management
│   │   └── components/    # React components
│   └── package.json       # Frontend dependencies
└── README.md              # Setup and usage docs
```

### Next: Enhancement opportunities
- **Historical metrics**: Store time-series data for workspace performance trends
- **Alerts system**: Notifications for high resource usage or workspace failures
- **Batch operations**: Multi-select for bulk start/stop/delete operations
- **Custom metrics**: Integration with application-specific monitoring
- **User authentication**: Multi-user access with role-based permissions
- **GitOps integration**: Automatic workspace creation from repository webhooks