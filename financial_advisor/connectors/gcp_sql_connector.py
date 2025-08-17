import os
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError

def get_gcp_sql_engine():
    """Creates a SQLAlchemy engine for GCP SQL."""
    db_user = os.environ["GCP_SQL_USER"]
    db_pass = os.environ["GCP_SQL_PASSWORD"]
    db_name = os.environ["GCP_SQL_DB_NAME"]
    instance_connection_name = os.environ["GCP_SQL_INSTANCE_CONNECTION_NAME"]

    engine = create_engine(
        f"mysql+mysqlconnector://{db_user}:{db_pass}@/{db_name}?unix_socket=/cloudsql/{instance_connection_name}"
    )
    return engine

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
                value BIGINT,
                shares BIGINT,
                price_per_share FLOAT
            )
        """))

def upsert_insider_trades(engine, trades):
    """Inserts or updates the insider trades data."""
    with engine.connect() as connection:
        for trade in trades:
            stmt = text("""
                INSERT INTO insider_trades (ticker, insider_name, relationship, transaction_date, transaction_type, value, shares, price_per_share)
                VALUES (:ticker, :insider_name, :relationship, :transaction_date, :transaction_type, :value, :shares, :price_per_share)
                ON DUPLICATE KEY UPDATE
                    insider_name = VALUES(insider_name),
                    relationship = VALUES(relationship),
                    transaction_date = VALUES(transaction_date),
                    transaction_type = VALUES(transaction_type),
                    value = VALUES(value),
                    shares = VALUES(shares),
                    price_per_share = VALUES(price_per_share)
            """)
            connection.execute(stmt, **trade)

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