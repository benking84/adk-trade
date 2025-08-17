
import os
from financial_advisor.connectors import web_scraper_connector, gcp_sql_connector

class TradeScannerAgent:
    def __init__(self):
        self.name = "trade_scanner"
        self.description = "Scans for insider trades and stores them in the database."

    def scan_and_store_trades(self):
        """Fetches insider trades and stores them in the database."""
        print("Fetching insider trades...")
        insider_trades = web_scraper_connector.get_insider_trades()
        print(f"Found {len(insider_trades)} insider trades.")

        print("Connecting to GCP SQL database...")
        engine = gcp_sql_connector.get_gcp_sql_engine()
        print("Connected to GCP SQL database successfully.")

        print("Creating tables if they don't exist...")
        gcp_sql_connector.create_insider_trades_table(engine)
        print("Tables created successfully.")

        if insider_trades:
            print("Upserting insider trades...")
            gcp_sql_connector.upsert_insider_trades(engine, insider_trades)
            print("Insider trades upserted successfully.")

        return "Trade scanning and storing completed successfully."
