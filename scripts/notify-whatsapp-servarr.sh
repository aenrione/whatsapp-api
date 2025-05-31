#!/bin/bash

# Enable debug mode and log everything to a file
LOG_FILE="/tmp/script_debug.log"
exec > >(tee -a "$LOG_FILE") 2>&1
set -x  # Enable script debugging (prints each command)

# Load environment variables from .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
  export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)
else
  echo "Environment file not found. Exiting."
  exit 1
fi

# Check if required environment variables are set
if [ -z "$API_URL" ] || [ -z "$JID" ]; then
  echo "API_URL or JID is not set. Exiting."
  exit 1
fi

# Determine if the script is triggered by Sonarr or Radarr
if [ -n "$sonarr_eventtype" ]; then
  EVENT_TYPE="$sonarr_eventtype"
  APP="sonarr"
  SERIES_TITLE="$sonarr_series_title"
  SEASON_NUMBER="$sonarr_episodefile_seasonnumber"
  EPISODE_NUMBERS="$sonarr_episodefile_episodenumbers"
  EPISODE_TITLE="$sonarr_episodefile_episodetitles"
elif [ -n "$radarr_eventtype" ]; then
  EVENT_TYPE="$radarr_eventtype"
  APP="radarr"
  MOVIE_TITLE="$radarr_movie_title"
  MOVIE_YEAR="$radarr_movie_year"
else
  echo "No event type detected. Exiting."
  exit 1
fi

# Load the JSON configuration
TEMPLATE_FILE="$SCRIPT_DIR/event_templates.json"
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Template file not found. Exiting."
  exit 1
fi

# Extract the appropriate message template using jq
TEMPLATE=$(jq -r --arg app "$APP" --arg event "$EVENT_TYPE" '.[$app][$event]' "$TEMPLATE_FILE")

if [ "$TEMPLATE" == "null" ]; then
  echo "No template found for app: $APP and event: $EVENT_TYPE. Exiting."
  exit 1
fi

# Replace placeholders with actual values
if [ "$APP" == "sonarr" ]; then
  MESSAGE=$(echo "$TEMPLATE" | sed \
    -e "s/{series_title}/$SERIES_TITLE/g" \
    -e "s/{season_number}/$SEASON_NUMBER/g" \
    -e "s/{episode_numbers}/$EPISODE_NUMBERS/g" \
    -e "s/{episode_title}/$EPISODE_TITLE/g")
elif [ "$APP" == "radarr" ]; then
  MESSAGE=$(echo "$TEMPLATE" | sed \
    -e "s/{movie_title}/$MOVIE_TITLE/g" \
    -e "s/{movie_year}/$MOVIE_YEAR/g" )
fi

# Send the message via WhatsApp API
curl -s -X POST "$API_URL/send" \
  -H "Content-Type: application/json" \
  -d "{\"number\": \"$JID\", \"message\": \"$MESSAGE\"}"

