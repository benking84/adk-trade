from financial_advisor.sub_agents.trade_scanner_agent import TradeScannerAgent
from dotenv import load_dotenv

def main():
    load_dotenv()
    agent = TradeScannerAgent()
    result = agent.scan_and_store_trades()
    print(result)

if __name__ == "__main__":
    main()