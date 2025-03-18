#!/bin/bash
# setup.sh - Initial setup script for a Raspberry Pi digital signage device
# This script is designed to be part of the Git repository
# Run after cloning the repository to /home/opstech/signage

# Log output
LOG_FILE="setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting digital signage setup at $(date)"
echo "---------------------------------------------"

# Verify we're in the right directory
if [ ! -f "setup.sh" ]; then
    echo "ERROR: This script must be run from the repository root directory"
    echo "Please cd to the repository directory and try again"
    exit 1
fi

# Create backup directory if it doesn't exist
echo "Creating backup directory..."
mkdir -p backup

# Install necessary packages
echo "Updating package lists and installing required packages..."
sudo apt update
sudo apt install -y epiphany-browser x11-xserver-utils unclutter scrot

# Configure Git
echo "Configuring Git..."
git config user.name "Digital Signage System"
git config user.email "no-reply@yourdistrict.edu"

# Create autostart directory if it doesn't exist
echo "Setting up browser autostart..."
mkdir -p /home/opstech/.config/autostart

# Create autostart file for browser
cat > /home/opstech/.config/autostart/signage.desktop << EOF
[Desktop Entry]
Type=Application
Name=Digital Signage
Exec=epiphany-browser -a --profile=/home/opstech/.config --display=:0 file:///home/opstech/signage/index.html
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# Disable screen blanking
echo "Disabling screen blanking..."
cat > /home/opstech/.xprofile << EOF
#!/bin/bash
xset s off
xset -dpms
xset s noblank
EOF
chmod +x /home/opstech/.xprofile

# Make scripts executable
echo "Setting execute permissions on scripts..."
chmod +x scripts/deploy.sh
chmod +x scripts/maintenance.sh

# Set up crontab for maintenance script
echo "Setting up scheduled maintenance..."
(crontab -l 2>/dev/null; echo "0 * * * * /home/opstech/signage/scripts/maintenance.sh") | crontab -

# Create a basic placeholder HTML file until first deployment
echo "Creating placeholder HTML file..."
cat > index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Digital Signage</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f0f0f0;
        }
        .message {
            text-align: center;
            padding: 2rem;
            background-color: white;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
        }
    </style>
</head>
<body>
    <div class="message">
        <h1>Digital Signage System</h1>
        <p>Setup complete. Waiting for first content deployment.</p>
        <p>Current time: <span id="time"></span></p>
    </div>
    <script>
        function updateTime() {
            document.getElementById('time').textContent = new Date().toLocaleTimeString();
        }
        setInterval(updateTime, 1000);
        updateTime();
    </script>
</body>
</html>
EOF

# Ensure proper ownership of all files
echo "Setting file ownership..."
sudo chown -R opstech:opstech .
sudo chown -R opstech:opstech /home/opstech/.config/autostart
sudo chown -R opstech:opstech /home/opstech/.xprofile

echo "---------------------------------------------"
echo "Setup completed successfully at $(date)"
echo "Log file available at: $LOG_FILE"
echo "The system is ready for the first deployment"
echo "To deploy content, run the deployment script from RDM"