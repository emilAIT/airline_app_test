@echo off

REM Activate virtual environment if it exists
if exist venv\Scripts\activate.bat (
    call venv\Scripts\activate.bat
)

pip install -r requirements.txt
REM Run seed data
echo Seeding database...
python seed_data.py
    REM Create virtual environment if it doesn't exist
    if not exist venv (
        echo Creating virtual environment...
        python -m venv venv
    )

    REM Activate virtual environment if it exists
    if exist venv\Scripts\activate.bat (
        call venv\Scripts\activate.bat
    )

    pip install -r requirements.txt
    REM Run seed data
    echo Seeding database...
    python seed_data.py

REM Start the server
echo Starting FastAPI server...
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

