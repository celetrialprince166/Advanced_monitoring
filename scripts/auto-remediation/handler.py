import os
import json
import urllib.request
import urllib.error
import boto3
import logging
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs_client = boto3.client('ecs')
logs_client = boto3.client('logs')

def check_idempotency(context, window_minutes=10):
    """
    Check if this Lambda has already executed successfully in the last N minutes.
    This prevents infinite loops if restarted tasks continue to fail.
    """
    log_group = os.environ.get('AWS_LAMBDA_LOG_GROUP_NAME')
    
    if not log_group:
        return False
        
    start_time = int((time.time() - (window_minutes * 60)) * 1000)
    
    try:
        response = logs_client.filter_log_events(
            logGroupName=log_group,
            startTime=start_time,
            filterPattern='"Auto-remediation successful"'
        )
        if response.get('events'):
            logger.info("Idempotency check: Found recent successful execution. Skipping.")
            return True
    except Exception as e:
        logger.warning(f"Idempotency check failed: {str(e)}")
        
    return False

def post_to_slack(webhook_url, message, color="warning"):
    """Post a simple message to Slack."""
    if not webhook_url:
        logger.info("No Slack webhook URL configured, skipping notification.")
        return
        
    payload = {
        "attachments": [
            {
                "color": color,
                "title": "ECS Auto-Remediation Triggered",
                "text": message
            }
        ]
    }
    
    req = urllib.request.Request(
        webhook_url, 
        data=json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    
    try:
        urllib.request.urlopen(req, timeout=5)
    except Exception as e:
        logger.error(f"Failed to post to Slack: {str(e)}")

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    
    cluster = os.environ.get('ECS_CLUSTER')
    service = os.environ.get('ECS_SERVICE')
    slack_url = os.environ.get('SLACK_WEBHOOK_URL')
    
    if not cluster or not service:
        logger.error("Missing required environment variables (ECS_CLUSTER, ECS_SERVICE)")
        return {"statusCode": 500, "body": "Configuration error"}
        
    # Check idempotency to prevent rapid looping
    if check_idempotency(context):
        return {"statusCode": 200, "body": "Skipped (recently executed)"}
        
    try:
        # 1. Find all running tasks for the service
        logger.info(f"Listing tasks for service {service} in cluster {cluster}")
        tasks_response = ecs_client.list_tasks(
            cluster=cluster,
            serviceName=service,
            desiredStatus='RUNNING'
        )
        
        task_arns = tasks_response.get('taskArns', [])
        
        if not task_arns:
            logger.info("No running tasks found to remediate.")
            return {"statusCode": 200, "body": "No tasks to stop"}
            
        # 2. Stop each running task
        logger.info(f"Stopping {len(task_arns)} tasks...")
        stopped_tasks = []
        
        for task_arn in task_arns:
            ecs_client.stop_task(
                cluster=cluster,
                task=task_arn,
                reason="Auto-remediation: Backend returning sustained 5xx errors post-deployment"
            )
            task_id = task_arn.split('/')[-1]
            stopped_tasks.append(task_id)
            logger.info(f"Stopped task: {task_id}")
            
        # 3. Notify success (the text matched by idempotency filter is critical)
        msg = f"Auto-remediation successful: Stopped tasks {', '.join(stopped_tasks)} in service `{service}` due to sustained 5xx errors. ECS will automatically launch replacements."
        logger.info(msg)
        post_to_slack(slack_url, msg, color="#E8A915") # Orange
        
        return {"statusCode": 200, "body": "Remediation successful"}
        
    except Exception as e:
        logger.error(f"Remediation failed: {str(e)}", exc_info=True)
        post_to_slack(slack_url, f"Failed to execute auto-remediation for `{service}`: {str(e)}", color="danger")
        return {"statusCode": 500, "body": "Remediation failed"}
