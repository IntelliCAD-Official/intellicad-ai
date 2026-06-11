# IntelliCAD Assistance Plugin

Claude plugin to access IntelliCAD functionality and knowledge basics.

## Overview

The plugin provides AI agent an ability to perform following tasks in context of a running IntelliCAD:
- Answer questions based on documentation.
- Selection based on natural language prompt.
- Ability to query drawing for information, such as layers list, block usage, etc.
- Generate and run a LISP program based on natural language prompt.

## MCP Servers

### `intellicad-application-server`
The plugin uses tools exposed by the IntelliCAD application server to query a running IntelliCAD application via COM interface. An AI agent starts the server as a local subprocess and provides a running IntelliCAD process name as the first launch argument.

### `intellicad-documentation-server`
The plugin uses tools from the IntelliCAD documentation server to retrieve information while answering questions.
More information is available at the [MCP server repository](https://mercurial.intellicad.org/ICAD-AI/mcp-documentation-server).

## Customizing & Branding

- The skill files (`SKILL.md` files in a subdirectory of `skills/`) contain direct instructions for an AI agent, that includes the name of a specific product (e.g. `IntelliCAD`). This product name can be referenced by the agent when answering user questions. Please replace `IntelliCAD` with your own product name in these files. Include in the product overview a statement that your product is built on the IntelliCAD platform. This will help the AI agent to semantically link your product with IntelliCAD and solve issues related to the core IntelliCAD.
- The file `.mcp.json` contains information required for an AI agent to connect to MCP servers. If you have already replaced `IntelliCAD` in the skill definition with your own product name as suggested above (f.i. `MyCAD`), then update the MCP documentation server name in `.mcp.json` so it's as bellow (note, `intellicad` is replaced with `mycad`):
```json
    "mycad-documentation-server": {
      "type": "http",
      "url": "https://hostname_or_ipaddress:port_number/mcp"
    }
```
Note `intellicad-application-server` server's the first launch argument is running IntelliCAD process name. Change it respectively if the product executable file name is not `icad.exe`.

## Author

Dmitry Kulikov (dmitry.kulikov@intellicad.org)

## Version

1.0.0
