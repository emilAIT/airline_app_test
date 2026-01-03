#!/bin/bash

# Activate virtual environment if it exists
if [ -d ".venv" ]; then
    source .venv/bin/activate
else
    python -m venv .venv
    source .venv/bin/activate
fi

pip install -r requirements.txt
# Run seed data
echo "Seeding database..."
python seed_data.py

# Start the server
echo "Starting FastAPI server..."
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

