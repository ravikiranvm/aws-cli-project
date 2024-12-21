#!/bin/bash

set +e # Script continues to run despite any resource deletion fails.

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

source ./scripts/common.sh

ec2_id=$(get_from_json "ec2_instance_id")
igw=$(get_from_json "igw_id")
vpc=$(get_from_json "vpc_id")
rtable=$(get_from_json "route_table_id")
subnet=$(get_from_json "subnet_id")
sg=$(get_from_json "security_group_id")
rtable_ass_id=$(get_from_json "route_table_association_id")

echo -e "${GREEN}Destroying resources started...${NC}"

# Deleting Functions 
echo -e "${GREEN}Deleteing function: ${RED}StopEC2Instance...${NC}"
aws lambda delete-function \
    --function-name "StopEC2Instance" \
    --region "ap-south-1"

echo -e "${GREEN}Deleteing function: ${RED}StartEC2Instance...${NC}"
aws lambda delete-function \
    --function-name "StartEC2Instance" \
    --region "ap-south-1"

#Terminating EC2 instance
echo -e "${GREEN}Stopping EC2 instance: ${RED}$ec2_id...${NC}"
aws ec2 stop-instances --instance-ids $ec2_id --region ap-south-1
echo "${YELLOW}Please wait...${NC}"

sleep 60 # Let the EC2 move to stopped state

echo -e "${GREEN}Terminating EC2 instance: ${RED}$ec2_id...${NC}"
aws ec2 terminate-instances --instance-ids $ec2_id --region ap-south-1
delete_from_json "ec2_instance_id"
delete_from_json "ec2_public_ip"
echo "${YELLOW}Please wait...${NC}"

sleep 60 # Let the EC2 move to termintaed state

# Deleting IGW
echo -e "${GREEN}Detaching IGW: ${RED}$igw...${NC}"
aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc

echo -e "${GREEN}Deleting IGW: ${RED}$igw...${NC}"
aws ec2 delete-internet-gateway --internet-gateway-id $igw

delete_from_json "igw_id"

# Deleting Route Table
echo -e "${GREEN}Detaching Route Table: ${RED}$rtable...${NC}"
aws ec2 disassociate-route-table --association-id $rtable_ass_id
aws ec2 delete-route-table --route-table-id $rtable

delete_from_json "route_table_association_id"
delete_from_json "route_table_id"

# Deleting Subnet
echo -e "${GREEN}Deleting Subnet: ${RED}$subnet...${NC}"
aws ec2 delete-subnet --subnet-id $subnet

delete_from_json "subnet_id"
sleep 10 #Wait for subnet to be deleted

# Deleting VPC
echo -e "${GREEN}Deleting VPC: ${RED}$vpc...${NC}"
aws ec2 delete-vpc --vpc-id $vpc

delete_from_json "vpc_id"

# Deleting Security Groups
echo -e "${GREEN}Deleting Security Groups: ${RED}$sg...${NC}"
aws ec2 delete-security-group --group-id $sg

delete_from_json "security_group_id"

# Delete EventBridge Rules
echo -e "${GREEN}Deleting EventBridge Rules...${NC}"
aws events remove-targets --rule "StartEC2InstanceRule" --ids "1"
aws events delete-rule --name "StartEC2InstanceRule"

aws events remove-targets --rule "StopEC2InstanceRule" --ids "1"
aws events delete-rule --name "StopEC2InstanceRule"

# Dleting IAM Role
echo -e "${GREEN}Deleting IAM Role...${NC}"
aws iam delete-role-policy --role-name LambdaEC2SchedulerRole --policy-name EC2AccessPolicy # Deleting the inline policy
aws iam delete-role --role-name LambdaEC2SchedulerRole

echo -e "${GREEN}All resources destroyed!${NC}"



