import requests

def send_slack_notification(message):
    webhook_url = "https://hooks.slack.com/services/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"
    payload = {
        "text": message
    }
    response = requests.post(webhook_url, json=payload)
    if response.status_code != 200:
        print(f"Failed to send Slack notification: {response.status_code} {response.text}")