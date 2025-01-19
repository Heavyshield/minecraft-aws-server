import boto3
import os

def lambda_handler(event, context):
    # Initialize EC2 client
    ec2 = boto3.client('ec2')
    
    # Getinstance ID from Env variables
    action = event.get('action', '').lower()
    instance_id = os.environ.get('INSTANCE_ID')
    
    if not instance_id:
        return {
            'statusCode': 400,
            'body': 'instance_id is required'
        }
    
    try:

        ec2.stop_instances(InstanceIds=[instance_id])
        message = f'Stopped instance {instance_id}'
        return {
            'statusCode': 200,
            'body': message
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': str(e)
        }