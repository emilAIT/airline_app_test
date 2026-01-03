from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, status, Request
from sqlalchemy.orm import Session
from typing import List, Optional
from app.database import get_db
from app.auth.auth_handler import get_current_staff_user
from app.models.media import Photo
from app.models.all_models import User
from app.schemas import schemas
import shutil
import os
from uuid import uuid4
from datetime import datetime

router = APIRouter(
    prefix="/photos",
    tags=["photos"],
)

# Ensure static directory exists
os.makedirs("media/photos", exist_ok=True)

@router.post("/", response_model=schemas.PhotoOut, status_code=status.HTTP_201_CREATED)
@router.post("", response_model=schemas.PhotoOut, status_code=status.HTTP_201_CREATED)
def upload_photo(
    request: Request,
    file: UploadFile = File(...),
    category: str = Form(...),
    entity_type: Optional[str] = Form(None),
    entity_id: Optional[int] = Form(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff_user),
):
    # Generate unique filename
    filename = f"{uuid4()}_{file.filename}"
    file_path = f"media/photos/{filename}"
    
    # Save file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Create DB entry
    # URL should be absolute public URL
    base_url = str(request.base_url)[:-1]  # Remove trailing slash
    photo = Photo(
        url=f"{base_url}/media/photos/{filename}",
        category=category,
        entity_type=entity_type,
        entity_id=entity_id,
        created_at=datetime.utcnow()
    )
    
    db.add(photo)
    db.commit()
    db.refresh(photo)
    
    return photo

@router.get("/", response_model=List[schemas.PhotoOut])
@router.get("", response_model=List[schemas.PhotoOut])
def get_photos(
    category: Optional[str] = None,
    entity_type: Optional[str] = None,
    entity_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Photo).filter(Photo.is_active == True)
    
    if category:
        query = query.filter(Photo.category == category)
    if entity_type:
        query = query.filter(Photo.entity_type == entity_type)
    if entity_id:
        query = query.filter(Photo.entity_id == entity_id)
        
    return query.order_by(Photo.display_order).all()

@router.delete("/{photo_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_photo(
    photo_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_staff_user),
):
    photo = db.query(Photo).filter(Photo.id == photo_id).first()
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
        
    # Effectively delete from DB
    db.delete(photo)
    db.commit()
    
    # Optional: Delete file from disk (omitted for safety/simplicity, can be added)
    return None
