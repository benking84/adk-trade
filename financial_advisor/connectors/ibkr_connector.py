
import os
from ib_insync import IB, util

def get_ibkr_portfolio():
    """Connects to IBKR and fetches the portfolio."""
    ib = IB()
    try:
        ib.connect(
            os.environ.get("IBKR_HOST", "127.0.0.1"),
            os.environ.get("IBKR_PORT", 7497),
            clientId=os.environ.get("IBKR_CLIENT_ID", 1),
        )
        portfolio = ib.portfolio()
        return portfolio
    finally:
        ib.disconnect()

if __name__ == "__main__":
    # For testing purposes
    from dotenv import load_dotenv

    load_dotenv()
    util.startLoop()
    portfolio = get_ibkr_portfolio()
    print(portfolio)
