#!/bin/bash

# Exit on errors
set -e

# Add debuggin mode
set -x

# File contianing resources details
RESOURCE_FILE="resources.json"

# Function to extract values from json file
function get_from_json() {
    local key=$1

    jq -r --arg key "$key" '.[$key]' "$RESOURCE_FILE"
}

# Function to write json to the resources file
function write_to_json() {
    local key=$1
    local value=$2

    if [ ! -f "$RESOURCE_FILE" ]; then
        echo "{}" > $RESOURCE_FILE
    fi

    jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$RESOURCE_FILE" > tmp.$$.json && mv tmp.$$.json "$RESOURCE_FILE"
}

# Retrieve resource ids from resources.json file
VPC_ID=$(get_from_json "vpc_id")
SUBNET_ID=$(get_from_json "subnet_id")
SECURITY_GROUP_ID=$(get_from_json "security_group_id")

# Check if required resources exist
if [[ -z "$VPC_ID" || -z "$SUBNET_ID" || -z "$SECURITY_GROUP_ID" ]]; then
    echo "Error: Required resources are missing for ec2 creation in $RESOURCE_FILE"
    exit 1
fi 

# Key-pair configuration
KEY_NAME="ec2-keypair"
KEY_FILE="${KEY_NAME}.pem"

echo "Creating a new key-pair..."
aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "$KEY_FILE"
chmod 400 "$KEY_FILE"
echo "Key pair created and saved to $KEY_FILE"
write_to_json "key_name" "$KEY_NAME"
write_to_json "key_file" "$KEY_FILE"

# Launch ec2 instance
AMI_ID="ami-0fd05997b4dff7aac"
INSTANCE_TYPE="t2.micro"

# Ensure user_data.sh file is readable.
chmod 644 ./templates/user_data.sh

echo "Creating ec2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --subnet-id "$SUBNET_ID" \
    --associate-public-ip-address \
    --user-data file://./templates/user_data.sh \
    --query "Instances[0].InstanceId" \
    --output text)

echo "ec2 instance launched: $INSTANCE_ID"
write_to_json "ec2_instance_id" "$INSTANCE_ID"

# Outputting instance ip
echo "Fetching instance details..."
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo "Instance public IP: $PUBLIC_IP"
write_to_json "ec2_public_ip" "$PUBLIC_IP"

echo "ec2 instance setup complete. Resource details saved to $RESOURCE_FILE"