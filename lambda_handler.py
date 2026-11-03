"""AWS Lambda Function URL adapter for the existing Tidewater Tours Flask API.

Used only for the LocalStack Hobby demo. The ordinary Docker entrypoint remains
app.py / gunicorn, so this does not change how the container is built.
"""
import base64
from urllib.parse import urlencode

from app import app


def handler(event, context):
    """Forward an AWS Lambda Function URL (or API Gateway) event into Flask."""
    event = event or {}
    request_context = event.get("requestContext") or {}
    method = (
        (request_context.get("http") or {}).get("method")
        or event.get("httpMethod")
        or "GET"
    )
    path = event.get("rawPath") or event.get("path") or "/"
    query = event.get("rawQueryString")
    if query is None:
        query = urlencode(event.get("queryStringParameters") or {})
    if query:
        path = f"{path}?{query}"

    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        body = base64.b64decode(body)

    with app.test_client() as client:
        response = client.open(
            path=path,
            method=method,
            headers=event.get("headers") or {},
            data=body,
        )
    return {
        "statusCode": response.status_code,
        "headers": {"content-type": response.content_type},
        "body": response.get_data(as_text=True),
        "isBase64Encoded": False,
    }
