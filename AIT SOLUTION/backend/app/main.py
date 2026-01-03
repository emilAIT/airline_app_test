from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.api import airports, airplanes, auth, notifications, flights, bookings, staff_mgmt, automation, users
from app.core.scheduler import scheduler
import logging
import sys
import asyncio

# Настраиваем логирование
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Управление жизненным циклом приложения"""
    # Startup
    logger.info("🚀 Запуск AIT Airlines API...")
    print("🚀 Запуск AIT Airlines API...", flush=True)
    logger.info("📅 Запуск планировщика автоматизации рейсов...")
    print("📅 Запуск планировщика автоматизации рейсов...", flush=True)
    try:
        await scheduler.start()
        logger.info("✅ Планировщик автоматизации рейсов запущен")
        print("✅ Планировщик автоматизации рейсов запущен", flush=True)
    except Exception as e:
        logger.error(f"❌ Ошибка при запуске планировщика: {e}", exc_info=True)
        print(f"❌ Ошибка при запуске планировщика: {e}", flush=True)
        raise
    
    yield
    
    # Shutdown
    logger.info("🛑 Остановка AIT Airlines API...")
    print("🛑 Остановка AIT Airlines API...", flush=True)
    logger.info("📅 Остановка планировщика автоматизации рейсов...")
    print("📅 Остановка планировщика автоматизации рейсов...", flush=True)
    try:
        await scheduler.stop()
        logger.info("✅ Планировщик автоматизации рейсов остановлен")
        print("✅ Планировщик автоматизации рейсов остановлен", flush=True)
    except Exception as e:
        logger.error(f"❌ Ошибка при остановке планировщика: {e}", exc_info=True)
        print(f"❌ Ошибка при остановке планировщика: {e}", flush=True)

app = FastAPI(title="AIT Airlines API", lifespan=lifespan)

# Middleware для логирования всех запросов
@app.middleware("http")
async def log_requests(request: Request, call_next):
    # Используем print для гарантированного вывода (uvicorn может перехватывать logging)
    print(f"\n{'='*60}")
    print(f"🔵 INCOMING REQUEST: {request.method} {request.url.path}")
    print(f"   Query params: {dict(request.query_params)}")
    logger.info(f"🔵 INCOMING REQUEST: {request.method} {request.url.path}")
    try:
        response = await call_next(request)
        print(f"🟢 RESPONSE: {request.method} {request.url.path} - Status: {response.status_code}")
        logger.info(f"🟢 RESPONSE: {request.method} {request.url.path} - Status: {response.status_code}")
        print(f"{'='*60}\n")
        return response
    except Exception as e:
        print(f"🔴 ERROR in {request.method} {request.url.path}: {type(e).__name__}: {e}")
        import traceback
        traceback.print_exc()
        logger.error(f"🔴 ERROR in {request.method} {request.url.path}: {type(e).__name__}: {e}", exc_info=True)
        print(f"{'='*60}\n")
        raise

origins = [
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:3003",
    "http://127.0.0.1:3003",
    "http://10.0.2.2:8000",  # Android эмулятор
    "*",  # Для разработки разрешаем все origins
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Для разработки разрешаем все origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(airports.router)
app.include_router(airplanes.router)
app.include_router(notifications.router)
app.include_router(flights.router)
app.include_router(bookings.router)
app.include_router(staff_mgmt.router)
app.include_router(automation.router)

@app.get("/")
def health_check():
    logger.info("Проверка работоспособности API")
    return {"message": "AIT Airlines API работает"}

@app.get("/test-logging")
def test_logging():
    import sys
    print("\n" + "="*60, flush=True)
    print("ТЕСТОВЫЙ ЭНДПОИНТ ЛОГИРОВАНИЯ ВЫЗВАН!!!", flush=True)
    print("Если вы видите это, эндпоинт работает!", flush=True)
    print("="*60 + "\n", flush=True)
    sys.stdout.flush()
    logger.info("ТЕСТОВЫЙ ЭНДПОИНТ ЛОГИРОВАНИЯ ВЫЗВАН - Если вы видите это, логирование работает!")
    return {"test": "логирование работает", "message": "Проверьте терминал бэкенда для логов"}
