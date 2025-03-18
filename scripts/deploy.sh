#!/bin/bash
# deploy.sh - Interactive deployment script for digital signage

# Log file
LOG_FILE="/home/opstech/signage/logs/deploy.log"

# Make sure logs directory exists
mkdir -p "/home/opstech/signage/logs"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Campus-wide constants (same for all displays)
DISTRICT_NAME="Orono Public Schools"
LATITUDE="44.991117"  # Set this to your campus coordinates
LONGITUDE="-93.596173"  # Set this to your campus coordinates

# Interactive prompt if variables aren't set
if [ -z "$CUSTOM_FIELD1" ] || [ "$CUSTOM_FIELD1" = '$CUSTOM_FIELD1$' ]; then
    # Prompt for location
    echo -n "Enter location (e.g., Main Office): "
    read LOCATION
else
    LOCATION="$CUSTOM_FIELD1"
fi

if [ -z "$CUSTOM_FIELD2" ] || [ "$CUSTOM_FIELD2" = '$CUSTOM_FIELD2$' ]; then
    # Prompt for presentation ID
    echo -n "Enter Google Slides presentation ID: "
    read PRESENTATION_ID
else
    PRESENTATION_ID="$CUSTOM_FIELD2"
fi

if [ -z "$CUSTOM_FIELD3" ] || [ "$CUSTOM_FIELD3" = '$CUSTOM_FIELD3$' ]; then
    # Prompt for template type with a default
    echo -n "Enter template type (standard, weather, calendar) [standard]: "
    read TEMPLATE_TYPE
    TEMPLATE_TYPE=${TEMPLATE_TYPE:-standard}
else
    TEMPLATE_TYPE="$CUSTOM_FIELD3"
fi

# Ensure location has been specified
if [ -z "$LOCATION" ]; then
    log_message "ERROR: Location not specified"
    echo "ERROR: Location cannot be empty. Exiting."
    exit 1
fi

# Ensure presentation ID has been specified
if [ -z "$PRESENTATION_ID" ]; then
    log_message "ERROR: Presentation ID not specified"
    echo "ERROR: Presentation ID cannot be empty. Exiting."
    exit 1
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
pkill -f chromium || true
pkill -f epiphany || true
sleep 2

# Launch Chromium in kiosk mode
chromium-browser --kiosk --incognito --noerrdialogs --disable-translate file:///home/opstech/signage/index.html &

# Check if browser started successfully
sleep 5
if ! pgrep -f chromium > /dev/null; then
    log_message "ERROR: Browser failed to start"
    echo "ERROR: Browser failed to start. Check the log for details."
else
    log_message "Browser started successfully"
fi

log_message "Deployment completed"
echo "DEPLOYMENT_STATUS: SUCCESS for $LOCATION"
