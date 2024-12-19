#!/bin/bash

# Exit on error
set -e

# Enable debug mode
set -x

RESOURCE_FILE="resources.json"

# Function to create EventBridge rules
create_event_rule() {
    local rule_name=$1
    local schedule=$2
    local lambda_function=$3

    echo "Creating EventBridge Rule: $rule_name..."
    aws events put-rule --schedule-expression "$schedule" --name "$rule_name" --region "ap-south-1"

    echo "Adding lambda function target to the $rule_name..." 
    aws events put-targets --rule "$rule_name" \
        --targets "Id"="1","Arn"="$(aws lambda get-function --function-name "$lambda_function" --query "Configuration.FunctionArn" --output text --region "ap-south-1")"        
}

# Schedule ec2 start and stop rule in the eventbridge

create_event_rule "StartEC2InstanceRule" "cron(30 2 * * ? *)" "StartEC2Instance" 
create_event_rule "StopEC2InstanceRule" "cron(30 14 * * ? *)" "StopEC2Instance"