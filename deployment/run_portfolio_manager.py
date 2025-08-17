import uvicorn
from fastapi import FastAPI
from financial_advisor.sub_agents.portfolio_manager.agent import PortfolioManagerAgent
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

@app.post("/")
def run_agent():
    agent = PortfolioManagerAgent()
    result = agent.update_portfolio()
    return {"result": result}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
