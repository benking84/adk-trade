
FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml poetry.lock ./

RUN pip install poetry
RUN poetry install --no-dev

COPY . .

CMD ["poetry", "run", "python", "run_trade_scanner.py"]
