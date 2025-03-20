# OPSsign - Digital Signage System

A lightweight digital signage system for Raspberry Pi devices that displays Google Slides presentations with additional information like weather and time.

## Overview

This repository contains everything needed to set up and manage a fleet of Raspberry Pi digital signage displays. The system is designed to:

- Display Google Slides presentations
- Show current weather conditions and time
- Be easily configurable through a simple command-line utility
- Support custom themes and layouts
- Automatically update and maintain itself

## Repository Structure

```
digital-signage/
├── opssign                    # Main management utility
├── templates/                 # Layout templates
│   ├── standard/              # Basic template with footer
│   │   └── index.html.template
│   ├── sidebar/               # Template with sidebar layout
│   │   └── index.html.template
│   └── weather/               # Template with detailed weather
│       └── index.html.template
├── themes/                    # Visual styling themes
│   ├── default.css            # Default blue theme
│   ├── dark.css               # Dark mode theme
│   └── custom themes...       # Your custom themes
├── assets/                    # Images and other static assets
│   └── ops-torch.png          # School logo
├── config/                    # Configuration files (not in git)
│   └── settings.yaml          # Device-specific settings
├── backup/                    # Automatic backups (not in git)
├── logs/                      # Log files (not in git)
└── README.md                  # This documentation
```

## Initial Setup

### 1. Prepare the Raspberry Pi

1. Install Raspberry Pi OS
2. Create an 'opstech' user account (instead of using the default 'pi' user)
3. Configure Wi-Fi or Ethernet connection
4. Enable SSH access

### 2. Clone Repository and Run Setup

```bash
# Log in as the opstech user
# Clone this repository
git clone https://github.com/your-organization/digital-signage.git /home/opstech/signage

# Navigate to the repository
cd /home/opstech/signage

# Make the utility executable
chmod +x opssign

# Run the setup process
./opssign setup
```

The setup utility will:
- Install necessary software
- Configure the system for kiosk display
- Set up maintenance tasks
- Guide you through initial configuration
- Create a settings.yaml file with your preferences

## Using the OPSsign Utility

OPSsign provides a unified command-line interface for managing your digital signage:

```bash
./opssign [command]
```

Available commands:

- `setup` - Perform initial installation and configuration
- `config` - Update configuration settings
- `start` - Deploy and start the digital signage display
- `stop` - Stop the display
- `status` - Check system status and health
- `update` - Update from GitHub repository
- `theme` - Theme management (create, list)
- `help` - Show help information

### Configuration

The `config` command lets you update various settings:
- District name
- Location name
- Google Slides presentation ID
- Template selection (layout)
- Theme selection (visual style)
- Geographic coordinates for weather

All settings are stored in `config/settings.yaml` for easy manual editing if needed.

### Templates and Themes

OPSsign separates the layout (templates) from the visual styling (themes):

**Templates** define the structure and layout:
- **standard**: Simple presentation with time/date footer
- **sidebar**: Presentation with weather/time sidebar (best for widescreen displays)
- **weather**: Detailed weather information with Google Slides

**Themes** define colors and visual styling:
- **default**: Standard blue theme
- **dark**: Dark mode theme

You can create custom themes with:
```bash
./opssign theme create
```

This interactive tool will let you customize colors for your theme.

## Maintenance

The system performs automatic maintenance through scheduled cron jobs:
- Hourly checks for browser crashes
- Automatic browser restart if needed
- Daily updates from GitHub repository
- Log rotation and disk space management

You can manually check system status with:
```bash
./opssign status
```

## Customization

### Adding New Templates

1. Create a new directory under `templates/`
2. Add an `index.html.template` file
3. Focus on layout, structure, and functionality
4. Include `<link rel="stylesheet" href="{THEME_PATH}">` in the head
5. Use placeholders like `{LOCATION}`, `{PRESENTATION_ID}`, etc.
6. Test with `./opssign config` and select your new template

### Creating New Themes

1. Run `./opssign theme create`
2. Follow the prompts to select colors
3. Deploy with `./opssign config` and select your theme

## Troubleshooting

Check the log files in `/home/opstech/signage/logs/`:
- `opssign.log`: Main application log

Common commands for troubleshooting:
```bash
# Check system status
./opssign status

# Stop and restart the display
./opssign stop
./opssign start

# Update configuration
./opssign config

# Update from GitHub
./opssign update
```

## Contributing

When contributing to this repository:
- Device-specific configurations are not included in git (see .gitignore)
- Focus on improving templates and the core utility
- Maintain the separation between templates (layout) and themes (styling)
- Test changes on a development Pi before pushing to the main repository
