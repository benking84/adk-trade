
from financial_advisor.connectors import ibkr_connector, gcp_sql_connector

class PortfolioManagerAgent:
    def __init__(self):
        self.name = "portfolio_manager"
        self.description = "Manages the user's portfolio by fetching data from IBKR and storing it in a GCP SQL database."

    def update_portfolio(self):
        """Fetches the portfolio from IBKR and stores it in the GCP SQL database."""
        print("Fetching portfolio from IBKR...")
        portfolio = ibkr_connector.get_ibkr_portfolio()
        print("Portfolio fetched successfully.")

        print("Connecting to GCP SQL database...")
        engine = gcp_sql_connector.get_gcp_sql_engine()
        print("Connected to GCP SQL database successfully.")

        print("Creating portfolio table if it doesn't exist...")
        gcp_sql_connector.create_portfolio_table(engine)
        print("Portfolio table created successfully.")

        print("Upserting portfolio data...")
        gcp_sql_connector.upsert_portfolio(engine, portfolio)
        print("Portfolio data upserted successfully.")

        return "Portfolio updated successfully."
