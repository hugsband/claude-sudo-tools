# Documentation Schema

> Last updated: 2026-02-19

## Document Registry

| Document | Purpose | Update Triggers |
|----------|---------|-----------------|
| `README.md` | Project overview, installation, usage | Feature changes, install procedure changes |
| `CHANGELOG.md` | Version history | After each release |
| `CONTRIBUTING.md` | Development guidelines | Process changes |
| `docs/ARCHITECTURE.md` | System design, MCP tool structure | New tools, structural changes |
| `docs/SECURITY.md` | Security model, privilege escalation rules | Security changes, new attack surface |
| `docs/TROUBLESHOOTING.md` | Common issues, debugging | New issues discovered |

## Update Triggers

| When you... | Update... |
|-------------|-----------|
| Add a new MCP tool | ARCHITECTURE.md, README (tool list), CHANGELOG |
| Change security model | SECURITY.md, README (security section) |
| Fix a bug | CHANGELOG (Fixed), TROUBLESHOOTING if user-facing |
| Change install procedure | README, CONTRIBUTING |
| Discover new issue pattern | TROUBLESHOOTING.md |

## Conventions

- CHANGELOG uses Keep a Changelog format
- Security changes are HIGH priority for doc updates
