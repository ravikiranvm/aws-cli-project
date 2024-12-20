# AWS CLI Automation Project

This project automates the provisioning and management of AWS resources using Bash scripts and AWS CLI. It includes networking, EC2 setup, Lambda functions, EventBridge rules, and cleanup scripts.

## Project Architecture

![alt text](architecture_diagram.jpeg)

## Project Structure

```plaintext
.
├── LICENSE
├── README.md
├── ec2-keypair.pem
├── resources.json
├── scripts
│   ├── common.sh
│   ├── destroy.sh
│   ├── ec2_setup.sh
│   ├── events.sh
│   ├── lambda.sh
│   ├── main.sh
│   ├── networking.sh
├── start_ec2.py
├── stop_ec2.py
├── templates
│   ├── ec2_access_policy.json
│   ├── role_assume_policy.json
│   └── user_data.sh
```

### Key Files and Directories
- **scripts/**: Contains all automation scripts.
- **templates/**: Stores JSON templates for IAM policies and EC2 instance initialization.
- **resources.json**: Tracks created AWS resource IDs for easier cleanup.

## Prerequisites

1. Install the AWS CLI.
2. Configure your AWS CLI by running:
   ```bash
   aws configure
   ```
   Provide your AWS Access Key, Secret Access Key, Default Region, and Output Format.
3. Ensure you have the necessary IAM permissions to manage EC2, IAM, Lambda, and EventBridge resources.
4. Install `jq` for JSON parsing in the scripts.
5. Grant execute permissions to all scripts by running:
   ```bash
   chmod +x scripts/*.sh
   ```

## Usage Instructions

### Step 1: Clone the Repository
Clone the project repository to your local machine:
```bash
git clone https://github.com/ravikiranvm/aws-cli-project
cd aws-cli-project
```

### Step 2: Run the Automation Scripts

Run the scripts sequentially to set up the infrastructure. **Always execute the scripts from the project's root directory**.

#### Option 1: Run All Scripts Automatically
To deploy the entire stack in one step, run:
```bash
./scripts/main.sh
```
This script sequentially executes all necessary setup scripts.

#### Option 2: Run Scripts Individually

1. **Networking Setup**:
   ```bash
   ./scripts/networking.sh
   ```
   Sets up the VPC, Subnet, Internet Gateway, Route Table, and Security Group.

2. **EC2 Setup**:
   ```bash
   ./scripts/ec2_setup.sh
   ```
   Creates an EC2 key pair and launches an instance in the configured network.

3. **Lambda Functions Deployment**:
   ```bash
   ./scripts/lambda.sh
   ```
   Deploys Lambda functions for starting and stopping the EC2 instance.

4. **EventBridge Rules Configuration**:
   ```bash
   ./scripts/events.sh
   ```
   Sets up EventBridge rules to trigger the Lambda functions on a schedule.

### Step 3: Cleanup Resources
To delete all created AWS resources, run:
```bash
./scripts/destroy.sh
```
This script reads `resources.json` to identify and remove the resources.

## Notes
- Ensure the `ec2-keypair.pem` file is securely stored. It is used to SSH into the EC2 instance.
- Modify scripts as needed to customize resource configurations.
- If any script fails, debug using the output messages or logs.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

