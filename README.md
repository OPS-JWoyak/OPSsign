# OPSsign

A lightweight, Edu-focused, Google Slides centric digital signage system.
Made with the help of AI, by Orono Public Schools Technology

## Overview

This repository contains everything needed to set up and manage a fleet of Raspberry Pi digital signage displays. The system is designed to:

- Display Google Slides presentations
- Show current weather conditions
- Display time and date
- Be centrally managed through Devolutions Remote Desktop Manager
- Automatically update and maintain itself

## Repository Structure

```
digital-signage/
├── setup.sh                   # Initial setup script
├── templates/                 # HTML templates
│   ├── standard/              # Basic template
│   │   └── index.html.template
│   ├── weather/               # Template with weather
│   │   └── index.html.template
│   └── calendar/              # Template with calendar integration
│       └── index.html.template
├── scripts/                   # Management scripts
│   ├── deploy.sh              # Content deployment script
│   └── maintenance.sh         # Health check script
├── backup/                    # Automatic backups (created by scripts)
├── logs/                      # Log files (created by scripts)
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
git clone git@github.com:OPS-JWoyak/OPSsign.git /home/opstech/signage

# Navigate to the repository
cd /home/opstech/signage

# Run the setup script
./setup.sh
```

The setup script will:
- Install necessary software
- Configure the system for kiosk display
- Set up maintenance tasks
- Prepare for content deployment

## Managing Content with RDM

### Setting Up Sessions in Devolutions Remote Desktop Manager

1. Create a template SSH session with these variables:
   - CUSTOM_FIELD1 = Location name (e.g., "Main Office", "Library")
   - CUSTOM_FIELD2 = Google Slides Presentation ID
   - CUSTOM_FIELD3 = Template type (optional, defaults to "standard")

2. Duplicate this template for each display, updating the variables as needed

3. Deploy content by running this command through RDM:
   ```bash
   /home/opstech/signage/scripts/deploy.sh
   ```

### Template Types

- **standard**: Basic Google Slides presentation
- **weather**: Google Slides with weather and time display
- **calendar**: Google Slides with calendar events (if implemented)

## Maintenance

The system performs automatic maintenance through the scheduled cron job:
- Hourly checks for browser crashes
- Automatic browser restart if needed
- Daily pull of latest templates from GitHub
- Log rotation and disk space management
- Memory management

## Customization

### District-Wide Settings

Edit the `deploy.sh` script to update these values:
- `DISTRICT_NAME`: Your school district name
- `LATITUDE` and `LONGITUDE`: Your campus coordinates

### Adding New Templates

1. Create a new directory under `templates/`
2. Add an `index.html.template` file
3. Use placeholders like `{LOCATION}`, `{PRESENTATION_ID}`, etc.

## Troubleshooting

Check the log files in `/home/opstech/signage/logs/`:
- `deploy.log`: Deployment issues
- `maintenance.log`: System health information

Common commands to run through RDM:
```bash
# Check system status
uptime && echo "Memory:" && free -h && echo "Disk:" && df -h /

# Restart the browser
export DISPLAY=:0 && pkill -f epiphany && sleep 2 && epiphany-browser -a --display=:0 file:///home/opstech/signage/index.html

# Reboot the device
sudo reboot
```
