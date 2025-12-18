#!/bin/bash
# Format date range for 3P updates
# Usage: format-date.sh [weeks_ago]

weeks_ago=${1:-1}
end_date=$(date +"%b %d")
start_date=$(date -v-${weeks_ago}w +"%b %d" 2>/dev/null || date -d "-${weeks_ago} week" +"%b %d")

echo "${start_date} - ${end_date}"
