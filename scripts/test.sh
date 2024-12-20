#!/bin/bash

source ./scripts/common.sh

set -e
set -x

jq "del(.test)" "$RESOURCE_FILE" > "$RESOURCE_FILE.tmp" && mv "$RESOURCE_FILE.tmp" "$RESOURCE_FILE"