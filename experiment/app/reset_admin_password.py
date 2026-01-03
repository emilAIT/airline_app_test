"""
Скрипт для сброса пароля администратора
Запустите этот скрипт, если забыли пароль админа или не можете войти
"""
import sys
import os

# Добавляем текущую директорию в путь
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal
from app.models import user as user_model
from app.core import security

def reset_admin_password():
    """Сбрасывает пароль администратора на 'admin123'"""
    STAFF_EMAIL = "admin@airline.com"
    STAFF_PASSWORD = "admin123"
    STAFF_FULL_NAME = "System Administrator"
    
    db = SessionLocal()
    try:
        # Ищем существующего пользователя
        user = db.query(user_model.User).filter(
            user_model.User.email == STAFF_EMAIL
        ).first()
        
        if user:
            # Обновляем пароль и роль
            user.hashed_password = security.get_password_hash(STAFF_PASSWORD)
            user.role = user_model.UserRole.STAFF
            user.full_name = STAFF_FULL_NAME
            user.is_active = True
            db.commit()
            print(f"[OK] Password reset for administrator!")
            print(f"   Email: {STAFF_EMAIL}")
            print(f"   Password: {STAFF_PASSWORD}")
        else:
            # Создаем нового пользователя
            user = user_model.User(
                email=STAFF_EMAIL,
                hashed_password=security.get_password_hash(STAFF_PASSWORD),
                full_name=STAFF_FULL_NAME,
                role=user_model.UserRole.STAFF,
                is_active=True,
            )
            db.add(user)
            db.commit()
            print(f"[OK] Administrator created!")
            print(f"   Email: {STAFF_EMAIL}")
            print(f"   Password: {STAFF_PASSWORD}")
        
        # Проверяем результат
        db.refresh(user)
        print(f"\nVerification:")
        print(f"   ID: {user.id}")
        print(f"   Email: {user.email}")
        print(f"   Role: {user.role}")
        print(f"   Active: {user.is_active}")
        print(f"   Full Name: {user.full_name}")
        
        # Проверяем пароль
        if security.verify_password(STAFF_PASSWORD, user.hashed_password):
            print(f"\n[OK] Password verified successfully!")
        else:
            print(f"\n[ERROR] Password verification failed!")
            
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    print("=" * 50)
    print("Reset Administrator Password")
    print("=" * 50)
    reset_admin_password()
    print("=" * 50)

