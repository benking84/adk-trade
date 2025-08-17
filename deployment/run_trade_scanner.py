import uvicorn
from fastapi import FastAPI
from financial_advisor.sub_agents.trade_scanner_agent import TradeScannerAgent
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

@app.post("/")
def run_agent():
    agent = TradeScannerAgent()
    result = agent.scan_and_store_trades()
    return {"result": result}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
