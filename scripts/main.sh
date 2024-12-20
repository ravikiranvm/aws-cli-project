#!/bin/bash

set -e 
set -o pipefail

# Colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No color

# Deploy Network stack
echo -e "${GREEN}Running Networking stack...${NC}"
./scripts/networking.sh
echo -e "${GREEN}Networking stack deployed successfully${NC}"
echo -e "${YELLOW}Please wait..."
sleep 10

# Deploy EC2 instance
echo -e "${GREEN}Running EC2 stack...${NC}"
./scripts/ec2_setup.sh
echo -e "${GREEN}EC2 stack deployed successfully${NC}"
echo -e "${YELLOW}Please wait..."
sleep 10

# Deploy Lambda stack
echo -e "${GREEN}Running Lambda stack...${NC}"
./scripts/lambda.sh
echo -e "${GREEN}Lambda stack deployed successfully${NC}"
echo -e "${YELLOW}Please wait..."
sleep 10

# Deploy EventBridge
echo -e "${GREEN}Running Event Bridge stack...${NC}"
./scripts/events.sh
echo -e "${GREEN}Event Bridge stack deployed successfully${NC}"
echo -e "${GREEN}Deployment Complete!!!"
