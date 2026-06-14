#!/bin/bash
set -e

# Allow runner user to access Docker socket
if [ -S /var/run/docker.sock ]; then
    sudo chmod 666 /var/run/docker.sock
fi

REGISTRATION_TOKEN=$(curl -sX POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${ACCESS_TOKEN}" \
    "https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token" \
    | jq -r .token)

./config.sh \
    --url "https://github.com/${ORGANIZATION}" \
    --token "${REGISTRATION_TOKEN}" \
    --name "${RUNNER_NAME:-$(hostname)}" \
    --labels "${RUNNER_LABELS:-self-hosted}" \
    --unattended \
    --replace

cleanup() {
    ./config.sh remove --unattended --token "${REGISTRATION_TOKEN}"
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh &
wait $!
