#!/bin/bash
# maintenance.sh - Performs basic maintenance and health checks
# Designed to run hourly via cron job

# Ensure logs directory exists
mkdir -p "/home/opstech/signage/logs"

LOG_FILE="/home/opstech/signage/logs/maintenance.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running maintenance" >> "$LOG_FILE"

# Change to signage directory
cd /home/opstech/signage || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Could not change to signage directory" >> "$LOG_FILE"
    exit 1
}

# Check if browser is running, restart if not
if ! pgrep -f epiphany > /dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Browser not running, restarting" >> "$LOG_FILE"
    export DISPLAY=:0
    epiphany-browser -a --profile=/home/opstech/.config --display=:0 file:///home/opstech/signage/index.html &
fi

# Pull latest from GitHub (only once a day at 2 AM)
CURRENT_HOUR=$(date +%H)
if [ "$CURRENT_HOUR" -eq 2 ]; then  # 2 AM
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Performing scheduled Git pull" >> "$LOG_FILE"
    git pull >> "$LOG_FILE" 2>&1
fi

# Check disk space
DISK_SPACE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_SPACE" -gt 85 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Disk space critical: $DISK_SPACE%" >> "$LOG_FILE"

    # Clean up old logs and backups if space is low
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up old files to free space" >> "$LOG_FILE"
    find /home/opstech/signage/backup -type f -mtime +30 -delete
    find /home/opstech/signage/logs -type f -mtime +30 -delete
fi

# Rotate logs if they get too big
for log_file in /home/opstech/signage/logs/*.log; do
    if [ -f "$log_file" ] && [ $(stat -c%s "$log_file") -gt 10485760 ]; then # 10MB
        mv "$log_file" "${log_file}.$(date +%Y%m%d)"
        touch "$log_file"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rotated log file: $log_file" >> "$LOG_FILE"
    fi
done

# Check memory usage
FREE_MEM=$(free -m | awk 'NR==2 {print $4}')
if [ "$FREE_MEM" -lt 100 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Low memory: ${FREE_MEM}MB free" >> "$LOG_FILE"

    # Attempt to free up some memory
    sync && echo 3 > /proc/sys/vm/drop_caches
fi

# Restart browser once per day to prevent memory leaks
if [ "$CURRENT_HOUR" -eq 3 ]; then  # 3 AM
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Performing scheduled browser restart" >> "$LOG_FILE"
    export DISPLAY=:0
    pkill -f epiphany || true
    sleep 5
    epiphany-browser -a --profile=/home/opstech/.config --display=:0 file:///home/opstech/signage/index.html &
fi

# Check internet connectivity
if ! ping -c 1 -W 5 8.8.8.8 > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: Internet connection appears to be down" >> "$LOG_FILE"
else
    # Only check for updates if we have internet
    # Check for system updates (but don't install automatically)
    if [ "$CURRENT_HOUR" -eq 4 ]; then  # 4 AM
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Checking for system updates" >> "$LOG_FILE"
        sudo apt update > /dev/null
        UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable")
        if [ "$UPDATES" -gt 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] $UPDATES system updates available" >> "$LOG_FILE"
        fi
    fi
fi

# Report system uptime
UPTIME=$(uptime -p)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] System uptime: $UPTIME" >> "$LOG_FILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Maintenance completed" >> "$LOG_FILE"
