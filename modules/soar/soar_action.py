import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("SOAR EVENT TRIGGERED")
    logger.info(json.dumps(event))
    
    return {
        'statusCode': 200,
        'body': json.dumps('SOAR automated response logged and executed successfully.')
    }