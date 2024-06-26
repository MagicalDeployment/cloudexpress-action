#!/bin/bash
set -e
BASE_URL="${INPUT_BASE_URL}"
TIMEOUT="${INPUT_TIMEOUT}"
PROJECT_ID="${INPUT_PROJECT_ID}"
COMPONENT_ID="${INPUT_COMPONENT_ID}"
NEW_IMAGE="${INPUT_NEW_IMAGE}"
CHECK_INTERVAL="${INPUT_INTERVAL}"
DEBUG="${INPUT_DEBUG}"

DOCKER_REGISTRY_URL="${INPUT_DOCKER_REGISTRY_URL}"
DOCKER_REGISTRY_USERNAME="${INPUT_DOCKER_REGISTRY_USERNAME}"
DOCKER_REGISTRY_PASSWORD="${INPUT_DOCKER_REGISTRY_PASSWORD}"

[[ "${DEBUG}" == "true" ]] && set -x

# Get current component data
DATA=$(curl -H "X-Service-Account-Id: 007" -H "X-Profile-Id: 007" -XGET "${BASE_URL}/components/${PROJECT_ID}/${COMPONENT_ID}/describe")

# Replace docker image to a new one
UPDATED_DATA=$(echo ${DATA} | jq  ".dockerImage=\"${NEW_IMAGE}\"")

[ -n "${DOCKER_REGISTRY_URL}" ] && UPDATED_DATA=$(echo ${DATA} | jq  ".dockerRegistryUrl=\"${DOCKER_REGISTRY_URL}\"")
[ -n "${DOCKER_REGISTRY_USERNAME}" ] && UPDATED_DATA=$(echo ${DATA} | jq  ".dockerRegistryUsername=\"${DOCKER_REGISTRY_USERNAME}\"")
[ -n "${DOCKER_REGISTRY_PASSWORD}" ] && UPDATED_DATA=$(echo ${DATA} | jq  ".dockerRegistryPassword=\"${DOCKER_REGISTRY_PASSWORD}\"")

# Trigger deploy with updated body
curl \
    -H "Content-Type: application/json" \
    -H "X-Service-Account-Id: 007" \
    -H "X-Profile-Id: 007" \
    -d "${UPDATED_DATA}" \
    -XPOST "${BASE_URL}/components/${PROJECT_ID}/creatupdateanddeploy"

expected_status="READY"
start_time=$(date +%s)
while true; do
    STATUS_URL="${BASE_URL}/components/${PROJECT_ID}/${COMPONENT_ID}/status"
    res=$(curl -s -H "X-Service-Account-Id: 007" -H "X-Profile-Id: 007" "${STATUS_URL}" | tr -d '"')

    if [ ${res} = "${expected_status}" ]; then
        echo "[INFO] Status 'READY' received. Deploy has completed"
        echo "::set-output name=status::ok"
        exit 0
    else
        echo "[INFO] Waiting for status 'READY'. Current status: '${res}'"
        sleep 5
    fi
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [ ${elapsed_time} -ge ${TIMEOUT} ]; then
        echo "::set-output name=status::fail"
        exit 1
    fi
    sleep ${CHECK_INTERVAL}
done


