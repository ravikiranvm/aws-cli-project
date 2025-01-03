import boto3
import os

def lambda_handler(event, context):
    try:
        # Initialize EC2 client
        ec2_client = boto3.client('ec2', region_name='ap-south-1')

        # Fetch instance ID from environment variable
        instance_id = event.get('instance_id')
        if not instance_id:
            raise ValueError("Instance ID is missing from the event payload")

        # Stop the instance
        ec2_client.stop_instances(InstanceIds=[instance_id])

        return {
            "statusCode": 200,
            "body": f"Instance {instance_id} stopped successfully."
        }

    except Exception as e:
        # Handle errors gracefully
        return {
            "statusCode": 500,
            "body": f"Error: {str(e)}"
        }
