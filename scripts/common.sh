#!/bin/bash

RESOURCE_FILE="resources.json"

# Function to write to resources.json file
function write_to_json() {
    local key=$1
    local value=$2

    if [ ! -f "$RESOURCE_FILE" ]; then
        echo "{}" > $RESOURCE_FILE
    fi

    jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$RESOURCE_FILE" > tmp.$$.json && mv tmp.$$.json "$RESOURCE_FILE"
}

# Function to retrieve resource details from the resources.json file
function get_from_json() {
    local key=$1
    jq -r --arg key "$key" '.[$key]' "$RESOURCE_FILE"
}

# Function to delete the resource entry from the resources.json file
function delete_from_json() {
    local key=$1
    jq "del(.test)" "$RESOURCE_FILE" > "$RESOURCE_FILE.tmp" && mv "$RESOURCE_FILE.tmp" "$RESOURCE_FILE"
}
