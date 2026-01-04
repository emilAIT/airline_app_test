"""
API для управления и мониторинга автоматизации рейсов
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session
from datetime import datetime
from app.database import get_session
from app.models import User, UserRole
from app.core.deps import get_current_user
from app.core.scheduler import scheduler
from app.services.flight_automation_service import FlightAutomationService

router = APIRouter(prefix="/automation", tags=["automation"])

@router.get("/status")
def get_automation_status(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """
    Получить статус автоматизации рейсов
    Доступно только для администраторов и персонала
    """
    if current_user.role not in [UserRole.ADMIN, UserRole.STAFF]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    automation_service = FlightAutomationService(session)
    return automation_service.get_automation_status()

@router.post("/run-now")
def run_automation_now(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user)
):
    """
    Запустить автоматизацию рейсов немедленно
    Доступно только для администраторов
    """
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin access required")
    
    try:
        automation_service = FlightAutomationService(session)
        automation_service.process_flight_status_updates()
        
        return {
            "success": True,
            "message": "Flight automation executed successfully",
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Automation failed: {str(e)}")

@router.get("/scheduler-status")
def get_scheduler_status(
    current_user: User = Depends(get_current_user)
):
    """
    Получить статус планировщика задач
    Доступно только для администраторов и персонала
    """
    if current_user.role not in [UserRole.ADMIN, UserRole.STAFF]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return {
        "scheduler_running": scheduler.running,
        "has_task": scheduler.task is not None,
        "timestamp": datetime.now().isoformat()
    }