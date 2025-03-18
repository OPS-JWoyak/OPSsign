#!/bin/bash
# deploy.sh - Deployment script for digital signage
# This script is designed to be run from RDM with custom fields

# Log file
LOG_FILE="/home/opstech/signage/logs/deploy.log"

# Make sure logs directory exists
mkdir -p "/home/opstech/signage/logs"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Campus-wide constants (same for all displays)
DISTRICT_NAME="Your District Name"
LATITUDE="40.7128"  # Set this to your campus coordinates
LONGITUDE="-74.0060"  # Set this to your campus coordinates

# Device-specific variables (from RDM)
LOCATION="$CUSTOM_FIELD1$"  # e.g., "Main Office", "Library"
PRESENTATION_ID="$CUSTOM_FIELD2$"
TEMPLATE_TYPE="$CUSTOM_FIELD3$"  # Optional, defaults to standard if not specified

# Ensure location has been specified
if [ -z "$LOCATION" ]; then
    log_message "ERROR: Location not specified in CUSTOM_FIELD1"
    echo "ERROR: Location not specified. Please set CUSTOM_FIELD1 in RDM."
    exit 1
fi

# Ensure presentation ID has been specified
if [ -z "$PRESENTATION_ID" ]; then
    log_message "ERROR: Presentation ID not specified in CUSTOM_FIELD2"
    echo "ERROR: Presentation ID not specified. Please set CUSTOM_FIELD2 in RDM."
    exit 1
fi

# Use default template if not specified
if [ -z "$TEMPLATE_TYPE" ]; then
    TEMPLATE_TYPE="standard"
    log_message "No template type specified, using standard template"
fi

# Log start of deployment
log_message "Starting deployment for $LOCATION"
log_message "Template type: $TEMPLATE_TYPE"
log_message "Presentation ID: $PRESENTATION_ID"

# Change to signage directory
cd /home/opstech/signage || {
    log_message "ERROR: Could not change to /home/opstech/signage"
    echo "ERROR: Could not access signage directory."
    exit 1
}

# Backup current index.html if it exists
if [ -f index.html ]; then
    cp index.html "backup/index.html.$(date '+%Y%m%d%H%M%S')"
    log_message "Backed up current index.html"
fi

# Pull latest templates from GitHub
log_message "Pulling latest templates from GitHub..."
git pull
if [ $? -ne 0 ]; then
    log_message "WARNING: Git pull failed, attempting to continue with existing files"
fi

# Check if template exists
if [ ! -f "templates/$TEMPLATE_TYPE/index.html.template" ]; then
    log_message "ERROR: Template not found: templates/$TEMPLATE_TYPE/index.html.template"
    # Fall back to standard template
    TEMPLATE_TYPE="standard"
    if [ ! -f "templates/$TEMPLATE_TYPE/index.html.template" ]; then
        log_message "ERROR: Standard template not found either, exiting"
        echo "ERROR: Template files missing. Check repository structure."
        exit 1
    fi
    log_message "Falling back to standard template"
fi

# Copy the template to index.html
cp "templates/$TEMPLATE_TYPE/index.html.template" index.html
log_message "Using template: $TEMPLATE_TYPE"

# Sanitize inputs for sed (escape special characters)
DISTRICT_NAME_ESCAPED=$(echo "$DISTRICT_NAME" | sed 's/[\/&]/\\&/g')
LOCATION_ESCAPED=$(echo "$LOCATION" | sed 's/[\/&]/\\&/g')
PRESENTATION_ID_ESCAPED=$(echo "$PRESENTATION_ID" | sed 's/[\/&]/\\&/g')

# Replace placeholders with specific values
log_message "Customizing template for $DISTRICT_NAME - $LOCATION"
sed -i "s/{DISTRICT_NAME}/$DISTRICT_NAME_ESCAPED/g" index.html
sed -i "s/{LOCATION}/$LOCATION_ESCAPED/g" index.html
sed -i "s/{LATITUDE}/$LATITUDE/g" index.html
sed -i "s/{LONGITUDE}/$LONGITUDE/g" index.html
sed -i "s/{PRESENTATION_ID}/$PRESENTATION_ID_ESCAPED/g" index.html

# Restart browser
log_message "Restarting browser..."
export DISPLAY=:0
pkill -f epiphany || true
sleep 2
epiphany-browser -a --profile=/home/opstech/.config --display=:0 file:///home/opstech/signage/index.html &

# Check if browser started successfully
sleep 5
if ! pgrep -f epiphany > /dev/null; then
    log_message "WARNING: Browser did not start, trying again..."
    epiphany-browser -a --profile=/home/opstech/.config --display=:0 file:///home/opstech/signage/index.html &
    sleep 5
    if ! pgrep -f epiphany > /dev/null; then
        log_message "ERROR: Browser failed to start after retry"
        echo "ERROR: Browser failed to start. Check the log for details."
    else
        log_message "Browser started successfully on second attempt"
    fi
else
    log_message "Browser started successfully"
fi

log_message "Deployment completed"
echo "DEPLOYMENT_STATUS: SUCCESS for $LOCATION"
