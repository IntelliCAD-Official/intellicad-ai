# IntelliCAD Technology Consortium Public Claude Plugins Marketplace

The marketplace repository contains plugins for Claude that can be installed locally in the Claude agent application to automate various tasks. Each plugin has its own README.md file.

## Installation

### Claude Code
1. Add ITC plugins marketplace:
`/plugin marketplace add https://github.com/IntelliCAD-Official/itc-public-claude-plugins.git`
2. Install a plugin (e.g. IntelliCAD plugin):
`/plugin install intellicad-plugin@itc-public-claude-plugins`

### Claude Desktop
1. Open Claude Desktop and switch to the Cowork tab.
2. Click Customize in the left sidebar.
3. Click Browse plugins and navigate to the Personal tab.
4. Click the "+" (Add) button and select Add marketplace from Git.
5. Enter the repository path `https://github.com/IntelliCAD-Official/itc-public-claude-plugins.git`.
6. Once synced, find a plugin in the list and click Install.
7. Enable Auto-Sync: In the marketplace menu (three dots), toggle "Sync automatically" on.

## Update

### Claude Code
To update ITC plugins:
1. `/plugin marketplace update itc-public-claude-plugins`.
2. Restart Claude Code: `/exit`, then `claude`. 

## Author

Dmitry Kulikov (dmitry.kulikov@intellicad.org)

## Version

1.0.0
