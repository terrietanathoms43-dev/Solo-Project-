#!/usr/bin/env bash
# LocalStack Hobby-compatible deployment proof, not a Docker-image deployment.
# Emulates Lambda Function URL serving the existing Flask API, then rolls
# the Lambda alias back to the previously published version.
set -Eeuo pipefail

FUNCTION_NAME="tidewater-tours-hobby"
FUNCTION_ALIAS="live"
COMMIT_SHORT="${GITHUB_SHA:0:12}"
VERSION_ONE="${COMMIT_SHORT}-v1"
VERSION_TWO="${COMMIT_SHORT}-v2"
AWS="aws --profile localstack"

echo "::group::Package Flask for AWS Lambda ZIP"
mkdir -p build/lambda
python -m pip install --no-cache-dir -r requirements.txt --target build/lambda
cp app.py lambda_handler.py build/lambda/
(cd build/lambda && zip -q -r ../../tidewater-lambda.zip .)
echo "::endgroup::"

echo "::group::Deploy first Lambda version"
V1=$($AWS lambda create-function \
  --function-name "$FUNCTION_NAME" \
  --runtime python3.12 \
  --handler lambda_handler.handler \
  --role arn:aws:iam::000000000000:role/lambda-role \
  --zip-file fileb://tidewater-lambda.zip \
  --environment "Variables={APP_VERSION=$VERSION_ONE}" \
  --publish \
  --query Version --output text)
echo "Published Lambda version $V1 ($VERSION_ONE)"

$AWS lambda wait function-active --function-name "$FUNCTION_NAME"
$AWS lambda create-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$FUNCTION_ALIAS" \
  --function-version "$V1" >/dev/null

FUNCTION_URL=$($AWS lambda create-function-url-config \
  --function-name "$FUNCTION_NAME" \
  --qualifier "$FUNCTION_ALIAS" \
  --auth-type NONE \
  --query FunctionUrl --output text)

[ -n "$FUNCTION_URL" ] && [ "$FUNCTION_URL" != "None" ]
echo "Emulated Function URL: $FUNCTION_URL"
echo "::endgroup::"

check_health() {
  local expected="$1"
  local response
  for attempt in $(seq 1 15); do
    if response=$(curl --noproxy '*' --fail --silent --show-error --max-time 10 "${FUNCTION_URL%/}/health"); then
      if RESPONSE="$response" EXPECTED="$expected" python -c 'import os, json; x=json.loads(os.environ["RESPONSE"]); assert x["status"]=="ok" and x["version"]==os.environ["EXPECTED"]'; then
        echo "Health check passed for $expected: $response"
        return 0
      fi
    fi
    sleep 3
  done
  echo "::error::Health check never returned expected version $expected"
  return 1
}

echo "::group::Validate original HTTP API"
check_health "$VERSION_ONE"
TOURS=$(curl --noproxy '*' --fail --silent --show-error --max-time 10 "${FUNCTION_URL%/}/tours")
RESPONSE="$TOURS" python -c 'import os,json; d=json.loads(os.environ["RESPONSE"]); assert d["count"] == 3'
echo "Tours endpoint passed: $TOURS"
echo "::endgroup::"

echo "::group::Deploy second Lambda version"
$AWS lambda update-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --environment "Variables={APP_VERSION=$VERSION_TWO}" >/dev/null
$AWS lambda wait function-updated --function-name "$FUNCTION_NAME"
V2=$($AWS lambda publish-version --function-name "$FUNCTION_NAME" --query Version --output text)
[ "$V1" != "$V2" ]
$AWS lambda update-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$FUNCTION_ALIAS" \
  --function-version "$V2" >/dev/null
echo "Live alias now on Lambda version $V2 ($VERSION_TWO)"
check_health "$VERSION_TWO"
echo "::endgroup::"

echo "::group::One-command Lambda rollback"
# This is a Lambda version rollback, NOT rollback of a Docker image.
$AWS lambda update-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$FUNCTION_ALIAS" \
  --function-version "$V1" >/dev/null
echo "Rolled back live alias to Lambda version $V1"
check_health "$VERSION_ONE"
echo "::endgroup::"

echo "### LocalStack Hobby deployment demonstration" >> "$GITHUB_STEP_SUMMARY"
echo "- Flask API deployed to an emulated AWS Lambda Function URL." >> "$GITHUB_STEP_SUMMARY"
echo "- Health check v1: success; tours endpoint: success." >> "$GITHUB_STEP_SUMMARY"
echo "- Promoted Lambda version $V2 and health checked v2." >> "$GITHUB_STEP_SUMMARY"
echo "- Rolled back to Lambda version $V1 and health checked v1." >> "$GITHUB_STEP_SUMMARY"
echo "- NOTE: This is a Lambda ZIP deployment, not Docker-image deployment/rollback." >> "$GITHUB_STEP_SUMMARY"
echo "- LocalStack runs only for the duration of this GitHub Actions job." >> "$GITHUB_STEP_SUMMARY"
