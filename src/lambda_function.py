import json
import os
from datetime import datetime

import boto3

log_group = os.environ['RDS_EVENT_LOG_GROUP']
cloudwatch_logs_client = boto3.client('logs')


def lambda_handler(event, _):
    next_sequence_token = None
    for event in event['Records']:
        message_source = event.get('EventSource')
        if message_source == 'aws:sns':
            rds_event = json.loads(event['Sns']['Message'])
            stream_name = rds_event['Event Source']
            event_time = datetime.strptime(rds_event['Event Time'], "%Y-%m-%d %H:%M:%S.%f")
            _remove_space_from_keys(rds_event)

            put_log_events_payload = {
                'logGroupName': os.environ['RDS_EVENT_LOG_GROUP'],
                'logStreamName': stream_name,
                'logEvents': [{
                    'timestamp': int(event_time.timestamp() * 1000),
                    'message':  json.dumps(rds_event),
                }],
            }

            if not next_sequence_token:
                streams = cloudwatch_logs_client.describe_log_streams(
                    logGroupName=log_group,
                )['logStreams']
                filtered_streams = list(filter(lambda s: s['logStreamName'] == stream_name, streams))
                if filtered_streams and 'uploadSequenceToken' in filtered_streams[0]:
                    put_log_events_payload['sequenceToken'] = filtered_streams[0]['uploadSequenceToken']
                else:
                    cloudwatch_logs_client.create_log_stream(logGroupName=log_group, logStreamName=stream_name)

            put_log_events_response = cloudwatch_logs_client.put_log_events(**put_log_events_payload)

            next_sequence_token = put_log_events_response['nextSequenceToken']


def _remove_space_from_keys(dict_input):
    old_keys = list(dict_input.keys())
    for old_key in old_keys:
        new_key = old_key.replace(' ', '')
        dict_input[new_key] = dict_input.pop(old_key)
