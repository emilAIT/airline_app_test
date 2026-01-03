@echo off
echo ========================================
echo FastAPI Backend Server
echo ========================================
echo.

echo Activating virtual environment...
call venv\Scripts\activate.bat

if errorlevel 1 (
    echo ERROR: Failed to activate virtual environment!
    echo Make sure you are in the backend directory.
    pause
    exit /b 1
)

echo.
echo Installing/updating dependencies...
python -m pip install -q -r requirements.txt

if errorlevel 1 (
    echo ERROR: Failed to install dependencies!
    pause
    exit /b 1
)

echo.
echo Starting FastAPI server...
echo Server will be available at: http://localhost:8000
echo API Documentation: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo ========================================
echo.

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

