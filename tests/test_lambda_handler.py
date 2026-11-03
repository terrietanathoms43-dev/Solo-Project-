"""Unit checks for the LocalStack Hobby Lambda adapter."""
import json

from lambda_handler import handler


def http_event(path="/health", method="GET"):
    return {"rawPath": path, "requestContext": {"http": {"method": method}}}


def test_lambda_health():
    response = handler(http_event(), None)
    assert response["statusCode"] == 200
    assert json.loads(response["body"])["status"] == "ok"


def test_lambda_tours():
    response = handler(http_event("/tours"), None)
    assert response["statusCode"] == 200
    assert json.loads(response["body"])["count"] == 3


def test_lambda_unknown_tour():
    response = handler(http_event("/tours/999"), None)
    assert response["statusCode"] == 404
