# IntelliCAD Technology Consortium AI Plugins Marketplace

The marketplace repository contains plugins that can be installed locally in AI agent application to automate various tasks. Each plugin has its own README.md file.

## Install

Execute `install.ps1` script to detect already installed AI agents (Claude Code, Gemini CLI, Codex, OpenCode, Google Antigravity) and install the plugin for each. Skips what you don't have. Safe to re-run. Note it doesn't install an AI agent app - you will need to install a preferred one first. 
Installation command for Windows (PowerShell):
```bash
irm https://raw.githubusercontent.com/IntelliCAD-Official/intellicad-ai/master/install.ps1 | iex
```

| Flag | What |
|---|---|
| `-DryRun` | Preview, write nothing |
| `-Only <agent>` | One target only (repeatable) |
| `-List` | Print supported agents matrix and exit |
| `-Force` | Re-run even if already installed |
| `-Uninstall` | Remove the plugin from all detected agents instead of installing |
| `-Detect` | Check whether all supported agents (or those in -Only) are installed. Exits 0 if all are detected, 1 if any are missing. Does not install or modify anything |

`install.ps1 -Help` for the full reference.

**Manual install:**

| Agent | Command |
|---|---|
| **Claude Code** | `claude plugin marketplace add https://github.com/IntelliCAD-Official/intellicad-ai.git ; claude plugin install intellicad-ai@intellicad-ai` |
| **Gemini CLI** | `gemini extensions install https://github.com/IntelliCAD-Official/intellicad-ai` |
| **Codex** | `codex plugin marketplace add https://github.com/IntelliCAD-Official/intellicad-ai.git ; codex plugin install intellicad-ai@intellicad-ai` |
| **OpenCode** | `codex plugin marketplace add https://github.com/IntelliCAD-Official/intellicad-ai.git ; codex plugin install intellicad-ai@intellicad-ai` |
| **Google Antigravity** | `codex plugin marketplace add https://github.com/IntelliCAD-Official/intellicad-ai.git ; codex plugin install intellicad-ai@intellicad-ai` |

## Author

Dmitry Kulikov (dmitry.kulikov@intellicad.org)

## Version

1.0.0
