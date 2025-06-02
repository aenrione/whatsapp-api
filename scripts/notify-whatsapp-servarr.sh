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
  SEASON_NUMBER="$sonarr_release_seasonnumber"
  EPISODE_NUMBERS="$sonarr_release_absoluteepisodenumbers"
  IMDB_ID="$sonarr_series_imdbid"
elif [ -n "$radarr_eventtype" ]; then
  EVENT_TYPE="$radarr_eventtype"
  APP="radarr"
  MOVIE_TITLE="$radarr_movie_title"
  MOVIE_YEAR="$radarr_movie_year"
  IMDB_ID="$radarr_movie_imdbid"
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

# if imdb_id is set, append url
if [ -n "$IMDB_ID" ]; then
  url="https://www.imdb.com/title/$IMDB_ID"
else
  url=""
fi

# Helper to escape strings safely for JSON
json_escape() {
  printf '%s' "$1" | jq -Rs .
}

if [ "$APP" == "sonarr" ]; then
  MESSAGE=$(jq -n --arg template "$TEMPLATE" \
                   --arg series_title "$(json_escape "$SERIES_TITLE")" \
                   --arg season_number "$(json_escape "$SEASON_NUMBER")" \
                   --arg episode_numbers "$(json_escape "$EPISODE_NUMBERS")" \
                   --arg imdb_link "$url" \
      '$template
        | gsub("\\{series_title\\}"; $series_title)
        | gsub("\\{season_number\\}"; $season_number)
        | gsub("\\{episode_numbers\\}"; $episode_numbers)
        | gsub("\\{imdb_link\\}"; $imdb_link)
      ')
elif [ "$APP" == "radarr" ]; then
  MESSAGE=$(jq -n --arg template "$TEMPLATE" \
                   --arg movie_title "$(json_escape "$MOVIE_TITLE")" \
                   --arg movie_year "$MOVIE_YEAR" \
                   --arg imdb_link "$url" \
      '$template
        | gsub("\\{movie_title\\}"; $movie_title)
        | gsub("\\{movie_year\\}"; $movie_year)
        | gsub("\\{imdb_link\\}"; $imdb_link)
      ')
fi

# Send the message via WhatsApp API
curl -s -X POST "$API_URL/send" \
  -H "Content-Type: application/json" \
  -d "{\"number\": \"$JID\", \"message\": $MESSAGE}"

