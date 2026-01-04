"""
Планировщик задач для автоматизации системы
"""

import asyncio
import logging
from datetime import datetime
from sqlmodel import Session
from app.database import get_session
from app.services.flight_automation_service import FlightAutomationService

logger = logging.getLogger(__name__)

class TaskScheduler:
    def __init__(self):
        self.running = False
        self.task = None

    async def start(self):
        """Запускает планировщик задач"""
        if self.running:
            logger.warning("Планировщик уже запущен")
            print("⚠️ Планировщик уже запущен", flush=True)
            return
        
        self.running = True
        self.task = asyncio.create_task(self._run_scheduler())
        logger.info("📅 Планировщик задач запущен")
        print("📅 Планировщик задач запущен", flush=True)

    async def stop(self):
        """Останавливает планировщик задач"""
        if not self.running:
            return
        
        self.running = False
        if self.task:
            self.task.cancel()
            try:
                await self.task
            except asyncio.CancelledError:
                pass
        
        logger.info("📅 Планировщик задач остановлен")

    async def _run_scheduler(self):
        """Основной цикл планировщика"""
        logger.info("🔄 Запуск основного цикла планировщика автоматизации рейсов")
        print("🔄 Запуск основного цикла планировщика автоматизации рейсов", flush=True)
        
        # Сразу запускаем автоматизацию при старте
        logger.info("🚀 Первый запуск автоматизации при старте...")
        print("🚀 Первый запуск автоматизации при старте...", flush=True)
        await self._run_flight_automation()
        logger.info("✅ Первый запуск автоматизации завершен")
        print("✅ Первый запуск автоматизации завершен", flush=True)
        
        iteration = 0
        while self.running:
            try:
                iteration += 1
                # Выполняем автоматизацию рейсов каждые 10 секунд для более оперативного обновления
                await asyncio.sleep(10)  # 10 секунд для быстрой реакции
                
                if iteration % 6 == 0:  # Каждую минуту (6 * 10 секунд)
                    logger.info(f"🔄 Автоматизация работает... (итерация {iteration})")
                    print(f"🔄 Автоматизация работает... (итерация {iteration})", flush=True)
                
                await self._run_flight_automation()
                
            except asyncio.CancelledError:
                logger.info("⏹️ Планировщик задач отменен")
                break
            except Exception as e:
                logger.error(f"❌ Ошибка в планировщике задач: {e}", exc_info=True)
                # Ждем 10 секунд перед повторной попыткой при ошибке
                await asyncio.sleep(10)

    async def _run_flight_automation(self):
        """Выполняет автоматизацию управления рейсами"""
        try:
            # Получаем сессию базы данных
            session_gen = get_session()
            session = next(session_gen)
            
            try:
                # Создаем сервис автоматизации
                automation_service = FlightAutomationService(session)
                
                # Выполняем обновления статусов
                automation_service.process_flight_status_updates()
                
            finally:
                session.close()
                
        except Exception as e:
            logger.error(f"❌ Ошибка при выполнении автоматизации рейсов: {e}", exc_info=True)

# Глобальный экземпляр планировщика
scheduler = TaskScheduler()