#!/bin/bash

# Exit on error
set -e

# Import functions from common.sh file
source ./scripts/common.sh

# Function to create EventBridge rules
create_event_rule() {
    local rule_name=$1
    local schedule=$2
    local lambda_function=$3
    local instance_id=$4

    echo "Creating EventBridge Rule: $rule_name..."
    aws events put-rule --name "$rule_name" --schedule-expression "$schedule" --region "ap-south-1"

    echo "Adding lambda function target to the $rule_name..." 
    aws events put-targets --rule "$rule_name" \
        --targets "Id=1,Arn=$(aws lambda get-function --function-name "$lambda_function" --query "Configuration.FunctionArn" --output text --region "ap-south-1"),Input='{\"instance_id\":\"$instance_id\"}'"
}

# Schedule ec2 start and stop rule in the eventbridge

INSTANCE_ID=$(get_from_json "ec2_instance_id")

create_event_rule "StartEC2InstanceRule" "cron(30 2 * * ? *)" "StartEC2Instance" "$INSTANCE_ID"
create_event_rule "StopEC2InstanceRule" "cron(30 14 * * ? *)" "StopEC2Instance" "$INSTANCE_ID"