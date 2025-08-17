#!/bin/bash
set -e

AGENTS=("data_analyst" "execution_analyst" "portfolio_manager" "risk_analyst" "trading_analyst" "trade_scanner_agent")

for AGENT in "${AGENTS[@]}"
do
  echo "Building image for agent: $AGENT"
  docker build -t "gcr.io/$PROJECT_ID/adk-trade-$AGENT" -f "deployment/dockerfiles/Dockerfile.$AGENT" .
  docker push "gcr.io/$PROJECT_ID/adk-trade-$AGENT"
  echo "Image for agent $AGENT built and pushed successfully"
done
