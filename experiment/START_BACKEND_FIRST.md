# ⚠️ Backend Not Running

## Problem
Connection error because **backend server is not running**.

## Solution: Start Backend

1. **Open Command Prompt or PowerShell**

2. **Navigate to project directory:**
   ```bash
   cd C:\Users\TechLine\Desktop\backend2
   ```

3. **Start backend:**
   ```bash
   start_backend.bat
   ```
   
   OR manually:
   ```bash
   python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

4. **Wait for startup:**
   ```
   INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
   INFO:     Started reloader process
   INFO:     Started server process
   INFO:     Waiting for application startup.
   INFO:     Application startup complete.
   ```

5. **Verify backend is running:**
   ```bash
   netstat -an | findstr ":8000"
   ```
   Should show: `TCP    0.0.0.0:8000           0.0.0.0:0              LISTENING`

6. **Test from browser (on laptop):**
   ```
   http://localhost:8000/docs
   ```
   Should open Swagger UI

7. **Test from phone browser:**
   ```
   http://192.168.68.66:8000/docs
   ```
   Should open Swagger UI (if firewall is configured)

8. **Then try login in the app again**

## Important Notes

- ✅ Keep backend running while using the app
- ✅ Backend must be on same Wi-Fi network as phone
- ✅ Backend must be accessible from phone (check firewall)
- ⚠️ If you close the terminal, backend stops

## Troubleshooting

If backend won't start:
- Check if port 8000 is already in use
- Check Python is installed: `python --version`
- Check dependencies: `pip install -r app/requirements.txt`
- Check you're in the correct directory

