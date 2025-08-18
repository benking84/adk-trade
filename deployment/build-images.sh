#!/bin/bash
set -e

GCR_HOST="gcr.io"
DOCKERFILES_DIR="./deployment/dockerfiles"

# Get PROJECT_ID from the first argument
PROJECT_ID="$1"

if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID is not set."
    exit 1
fi

declare -A docker_images=(
    ["Dockerfile.data_analyst"]="data-analyst-agent"
    ["Dockerfile.execution_analyst"]="execution-analyst-agent"
    ["Dockerfile.portfolio_manager"]="portfolio-manager-agent"
    ["Dockerfile.risk_analyst"]="risk-analyst-agent"
    ["Dockerfile.trade_scanner_agent"]="trade-scanner-agent"
    ["Dockerfile.trading_analyst"]="trading-analyst-agent"
)

for dockerfile in "${!docker_images[@]}"; do
    IMAGE_NAME="${docker_images[$dockerfile]}"
    FULL_IMAGE_NAME="${GCR_HOST}/${PROJECT_ID}/${IMAGE_NAME}"
    DOCKERFILE_PATH="${DOCKERFILES_DIR}/${dockerfile}"

    echo "Building image: ${FULL_IMAGE_NAME} from Dockerfile: ${DOCKERFILE_PATH}"
    docker build -f "${DOCKERFILE_PATH}" -t "${FULL_IMAGE_NAME}" .

    echo "Pushing image: ${FULL_IMAGE_NAME}"
    docker push "${FULL_IMAGE_NAME}"
done

echo "All Docker images built and pushed successfully."
