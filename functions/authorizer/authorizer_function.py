import os

def lambda_handler(event, context):
    headers = event.get('headers', {}) or {}
    api_key = headers.get('x-api-key') or headers.get('X-Api-Key')

    expected_key = os.environ.get('API_KEY')

    is_authorized = api_key is not None and api_key == expected_key

    return {
        "isAuthorized": is_authorized
    }