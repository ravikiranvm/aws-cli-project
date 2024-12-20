#!/bin/bash

set -e

# Import functions from common.sh file
source ./scripts/common.sh

# Retrieve resourcese details
INSTANCE_ID=$(get_from_json "ec2_instance_id")
ROLE_NAME="LambdaEC2SchedulerRole"

# Check if instance exists.
if [[ -z "$INSTANCE_ID" ]]; then
    echo "Error: Instance ID is missing in the $RESOURCE_FILE"
    exit 1
fi 

# Check if IAM role exists.
ROLE_EXISTS=$(aws iam get-role --role-name "$ROLE_NAME" --query Role.RoleName --output text 2>/dev/null || echo "")

if [[ -z "$ROLE_EXISTS" ]]; then
    echo "Creating IAM Role..."
    aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://./templates/role_assume_policy.json
    aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "EC2AccessPolicy" --policy-document file://./templates/ec2_access_policy.json 
fi 

sleep 30 # Let the role be available for the lambda function

# Create a function to deploy lambda functions
deploy_lambda() {
    local function_name=$1
    local handler_file=$2
    local description=$3

    echo "Deploying lambda function: $function_name..."

    #Check if the function exists.
    FUNCTION_EXISTS=$(aws lambda get-function --function-name "$function_name" --query "Configuration.FunctionName" --output text 2>/dev/null || echo "")

    if [[ -z "$FUNCTION_EXISTS" ]]; then
        zip "$handler_file.zip" "$handler_file"
        aws lambda create-function \
            --function-name "$function_name" \
            --runtime python3.9 \
            --role "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$ROLE_NAME" \
            --handler "$(basename "$handler_file" .py).lambda_handler" \
            --timeout 10 \
            --region "ap-south-1" \
            --zip-file "fileb://$handler_file.zip" \
            --description "$description" > /dev/null 2>&1
        rm -f "$handler_file.zip"
        echo "Function: $function_name created"
    else
        echo "$function_name already exists. Skipping creation."
    fi
}

# Deploy lambda functions
deploy_lambda "StartEC2Instance" "start_ec2.py" "Starts the EC2 instance."
deploy_lambda "StopEC2Instance" "stop_ec2.py" "Stops the EC2 instance."

# Create a function to add permission to eventbridge to invoke lambda
add_permission() {
    local function_name=$1
    local rule_name=$2

    echo "Adding permission for EventBridge to invoke $function_name..."

    # Check if the EventBridge rule exists
    RULE_EXISTS=$(aws events list-rules --name-prefix "$rule_name" --query "Rules[?Name=='$rule_name']" --output text)

    # If the rule doesn't exist, create it
    if [[ -z "$RULE_EXISTS" ]]; then
        echo "EventBridge rule $rule_name does not exist. Creating rule..."
        
        # Create the EventBridge rule (adjust cron schedule or event pattern as needed)
        aws events put-rule \
            --name "$rule_name" \
            --schedule-expression "cron(0 10 * * ? *)"  # Example cron expression, change it as needed

        echo "EventBridge rule $rule_name created."
    fi

    # Add permission for EventBridge to invoke the Lambda function
    aws lambda add-permission \
        --function-name "$function_name" \
        --principal events.amazonaws.com \
        --statement-id "EventBridgeInvokePermission" \
        --action "lambda:InvokeFunction" \
        --source-arn "arn:aws:events:ap-south-1:$(aws sts get-caller-identity --query Account --output text):rule/$rule_name"
}


add_permission "StartEC2Instance" "StartEC2InstanceRule"
add_permission "StopEC2Instance" "StopEC2InstanceRule"

echo "Lambda functions successfully deployed."
