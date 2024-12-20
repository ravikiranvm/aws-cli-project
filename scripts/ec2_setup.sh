#!/bin/bash

# Exit on errors
set -e

# Import functions from common.sh file
source ./scripts/common.sh

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

# Check if the key pair exists
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" > /dev/null 2>&1; then
    echo "Key pair '$KEY_NAME' already exists. Skipping creation."
else
    echo "Creating a new key pair..."
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query "KeyMaterial" --output text > "$KEY_FILE"
    chmod 400 ec2-keypair.pem
    echo "Key pair created and saved to $KEY_FILE"
fi
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