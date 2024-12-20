import requests
import os

def send_slack_notification(message):
    webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    payload = {
        "text": message
    }
    response = requests.post(webhook_url, json=payload)
    if response.status_code != 200:
        print(f"Failed to send Slack notification: {response.status_code} {response.text}")