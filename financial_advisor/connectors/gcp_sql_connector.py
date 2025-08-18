import os
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError
from google.cloud import secretmanager

def _get_secret(secret_id: str, version: str = "latest") -> str:
    """Retrieves a secret from Google Secret Manager."""
    project_id = os.environ["GOOGLE_CLOUD_PROJECT"]
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/{version}"
    response = client.access_secret_version(name=name)
    return response.payload.data.decode("UTF-8")

def get_gcp_sql_engine():
    """Creates a SQLAlchemy engine for GCP SQL."""
    # These values match the resources created in Terraform
    db_user = "db_user"
    db_name = "adk-trade"
    db_pass = _get_secret("db-password")
    db_host = _get_secret("db-host")

    # Connection string for a public IP connection
    db_uri = f"mysql+mysqlconnector://{db_user}:{db_pass}@{db_host}/{db_name}"

    return create_engine(db_uri)

def create_portfolio_table(engine):
    """Creates the portfolio table if it doesn't exist."""
    with engine.connect() as connection:
        connection.execute(text("""
            CREATE TABLE IF NOT EXISTS portfolio (
                symbol VARCHAR(255) PRIMARY KEY,
                quantity INTEGER,
                market_price FLOAT,
                market_value FLOAT,
                average_cost FLOAT,
                unrealized_pnl FLOAT,
                realized_pnl FLOAT,
                account_name VARCHAR(255)
            )
        """))

def upsert_portfolio(engine, portfolio):
    """Inserts or updates the portfolio data."""
    with engine.connect() as connection:
        trans = connection.begin()
        for position in portfolio:
            stmt = text("""
                INSERT INTO portfolio (symbol, quantity, market_price, market_value, average_cost, unrealized_pnl, realized_pnl, account_name)
                VALUES (:symbol, :quantity, :market_price, :market_value, :average_cost, :unrealized_pnl, :realized_pnl, :account_name)
                ON DUPLICATE KEY UPDATE
                    quantity = VALUES(quantity),
                    market_price = VALUES(market_price),
                    market_value = VALUES(market_value),
                    average_cost = VALUES(average_cost),
                    unrealized_pnl = VALUES(unrealized_pnl),
                    realized_pnl = VALUES(realized_pnl),
                    account_name = VALUES(account_name)
            """)
            connection.execute(stmt, **position)
        trans.commit()

def create_insider_trades_table(engine):
    """Creates the insider_trades table if it doesn't exist."""
    with engine.connect() as connection:
        connection.execute(text("""
            CREATE TABLE IF NOT EXISTS insider_trades (
                id INT AUTO_INCREMENT PRIMARY KEY,
                ticker VARCHAR(255),
                insider_name VARCHAR(255),
                relationship VARCHAR(255),
                transaction_date DATE,
                transaction_type VARCHAR(255),
                transaction_value BIGINT,
                shares BIGINT,
                price_per_share FLOAT,
                UNIQUE KEY `idx_unique_trade` (`ticker`, `insider_name`, `transaction_date`, `transaction_type`, `shares`)
            )
        """))

def upsert_insider_trades(engine, trades):
    """Inserts or updates the insider trades data."""
    with engine.connect() as connection:
        trans = connection.begin()
        for trade in trades:
            stmt = text("""
                INSERT INTO insider_trades (ticker, insider_name, relationship, transaction_date, transaction_type, transaction_value, shares, price_per_share)
                VALUES (:ticker, :insider_name, :relationship, :transaction_date, :transaction_type, :transaction_value, :shares, :price_per_share)
                ON DUPLICATE KEY UPDATE
                    insider_name = VALUES(insider_name),
                    relationship = VALUES(relationship),
                    transaction_date = VALUES(transaction_date),
                    transaction_type = VALUES(transaction_type),
                    transaction_value = VALUES(transaction_value),
                    shares = VALUES(shares),
                    price_per_share = VALUES(price_per_share)
            """)
            connection.execute(stmt, **trade)
        trans.commit()

if __name__ == "__main__":
    # For testing purposes
    from dotenv import load_dotenv

    load_dotenv()
    engine = get_gcp_sql_engine()
    try:
        create_portfolio_table(engine)
        create_insider_trades_table(engine)
        print("Successfully connected to the database and created the tables.")
    except OperationalError as e:
        print(f"Failed to connect to the database: {e}")