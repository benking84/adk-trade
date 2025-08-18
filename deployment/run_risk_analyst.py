import uvicorn
from fastapi import FastAPI
from financial_advisor.sub_agents.risk_analyst.agent import risk_analyst_agent
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

@app.post("/")
def run_agent(prompt: str):
    result = risk_analyst_agent.run(prompt=prompt)
    return {"result": result}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
