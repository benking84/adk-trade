variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "us-central1"
}

variable "agents" {
  description = "A list of agents to deploy."
  type        = list(string)
  default     = ["data_analyst", "execution_analyst", "portfolio_manager", "risk_analyst", "trading_analyst", "trade_scanner_agent"]
}

