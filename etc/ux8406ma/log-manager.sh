#!/bin/bash

LOG_FILE="/var/log/ux8406ma.log"
MAX_LINES=30

# Limit log file to the last N lines
limit_log_file() {
    if [[ -f "$LOG_FILE" ]]; then
        tail -n "$MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

# Append a message to the log
log_message() {
    local message=$1
    echo "$(date '+%Y/%m/%d %H:%M:%S'): $message" >> "$LOG_FILE"
    limit_log_file
}

# Ensure correct usage
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <message>"
    exit 1
fi

# Log the message
log_message "$1"
