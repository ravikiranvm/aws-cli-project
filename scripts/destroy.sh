#!/bin/bash

set -e

aws lambda delete-function \
    --function-name "StartEC2Instance" \
    --region "ap-south-1"