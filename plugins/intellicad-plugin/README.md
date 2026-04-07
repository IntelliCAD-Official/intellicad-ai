# IntelliCAD Assistance Plugin

Claude plugin to access IntelliCAD functionality and knowledge basics.

## Overview

The plugin provides AI agent an ability to perform following tasks in context of a running IntelliCAD:
- Answer questions based on documentation
- Selection based on natural language prompt
- Ability to query drawing for information, such as layers list, block usage, etc.

## MCP Servers

### `intellicad-documentation-server`
The plugin uses tools from the IntelliCAD documentation server to retrieve information while answering questions.
More information is available at the MCP server repository `https://mercurial.intellicad.org/ICAD-AI/mcp-documentation-server`

## Installation

### Claude Code
1. Add ITC plugins marketplace:
`/plugin marketplace add https://mercurial.intellicad.org/ICAD-AI/itc-plugins.git`
2. Install IntelliCAD plugin:
`/plugin install intellicad-plugin@itc-plugins`

### Claude Cowork
1. Open Claude Desktop and switch to the Cowork tab.
2. Click Customize in the left sidebar.
3. Click Browse plugins and navigate to the Personal tab.
4. Click the "+" (Add) button and select Add marketplace from Git.
5. Enter the repository path `https://mercurial.intellicad.org/ICAD-AI/itc-plugins.git`.
6. Once synced, find `intellicad-plugin` plugin in the list and click Install.

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
