#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define the Google Container Registry (GCR) host
GCR_HOST="gcr.io"

# Define the base directory where your Dockerfiles are located
DOCKERFILES_DIR="./deployment/dockerfiles"

# Array of Dockerfile names and their corresponding image names
# The image name will be used as the tag after the project ID
declare -A docker_images=(
    ["Dockerfile.data_analyst"]="data-analyst-agent"
    ["Dockerfile.execution_analyst"]="execution-analyst-agent"
    ["Dockerfile.portfolio_manager"]="portfolio-manager-agent"
    ["Dockerfile.risk_analyst"]="risk-analyst-agent"
    ["Dockerfile.trade_scanner_agent"]="trade-scanner-agent"
    ["Dockerfile.trading_analyst"]="trading-analyst-agent"
)

# Loop through the docker_images array and build each image
for dockerfile in "${!docker_images[@]}"; do
    IMAGE_NAME="${docker_images[$dockerfile]}"
    FULL_IMAGE_NAME="${GCR_HOST}/${PROJECT_ID}/${IMAGE_NAME}"
    DOCKERFILE_PATH="${DOCKERFILES_DIR}/${dockerfile}"

    echo "Building image: ${FULL_IMAGE_NAME} from Dockerfile: ${DOCKERFILE_PATH}"

    # Build the Docker image
    docker build -f "${DOCKERFILE_PATH}" -t "${FULL_IMAGE_NAME}" .

    echo "Pushing image: ${FULL_IMAGE_NAME}"
    # Push the Docker image to Google Container Registry
    docker push "${FULL_IMAGE_NAME}"
done

echo "All Docker images built and pushed successfully."
