#!/bin/bash

# Exit on errors
set -e

# Import functions from common.sh file
source ./scripts/common.sh

# Create VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
# Enable DNS support & hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"
echo "VPC Created: $VPC_ID"
write_to_json "vpc_id" "$VPC_ID"

# Create Subnet
echo "Creating public subnet..."
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)
echo "Subnet created: $SUBNET_ID"
write_to_json "subnet_id" "$SUBNET_ID"

# Create Internet Gateway
echo "Creating IGW"
IGW_ID=$(aws ec2 create-internet-gateway --query "InternetGateway.InternetGatewayId" --output text)
# Attach the IGW to VPC
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "IGW Created: $IGW_ID"
write_to_json "igw_id" "$IGW_ID"

# Create a route table
echo "Creating route table"
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query "RouteTable.RouteTableId" --output text)
# Create a route
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
# Associate the route table to subnet
ROUTE_TABLE_ASSOCIATION_ID=$(aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID --query "AssociationId" --output text)
echo "Route Table Created: $ROUTE_TABLE_ID"
write_to_json "route_table_id" "$ROUTE_TABLE_ID"
write_to_json "route_table_association_id" "$ROUTE_TABLE_ASSOCIATION_ID"

# Create security group
echo "Creating security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name web-sg --description "SG for Web Server" --vpc-id $VPC_ID --query "GroupId" --output text)
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr "49.205.105.182/32" # For SSH Access
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr "0.0.0.0/0" #HTTP Access
echo "Security group created: $SECURITY_GROUP_ID"
write_to_json "security_group_id" "$SECURITY_GROUP_ID"

echo "Networking setup completed. Resources are saved in $RESOURCE_FILE"