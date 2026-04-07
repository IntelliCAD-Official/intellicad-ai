# IntelliCAD Assistance Plugin

Claude plugin to access IntelliCAD functionality and knowledge basics.

## Overview

The plugin provides AI agent an ability to perform following tasks in context of a running IntelliCAD:
- Answer questions based on documentation
- Selection based on natural language prompt
- Ability to query drawing for information, such as layers list, block usage, etc.

## MCP Servers

### `intellicad-documentation-server`

## Installation

This plugin is included in the Claude Code repository. The command is automatically available when using Claude Code.

## Customizing & Branding

- The file `skills/documentation-assistant/SKILL.md` contains direct instructions for an AI agent, that includes the name of a specific product (e.g. `IntelliCAD`). This product name can be referenced by the agent when answering user questions. Please replace `IntelliCAD` with your own product name in the file.
- The file `.mcp.json` contains information required for an AI agent to connect to MCP servers. If you have already replaced `IntelliCAD` in the skill definition with your own product name as suggested above (f.i. `MyCAD`), then update the MCP documentation server name in `.mcp.json` so it's as bellow (note, `intellicad` is replaced with `mycad`):
```json
    "mycad-documentation-server": {
      "type": "http",
      "url": "http://hostaddress:portnumber/mcp"
    }
```

## Author

Dmitry Kulikov (dmitry.kulikov@intellicad.org)

## Version

1.0.0
