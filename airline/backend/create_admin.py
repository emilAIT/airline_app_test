#!/usr/bin/env python3
"""
Script to create a new admin/staff user
Usage: python create_admin.py
"""

from app.database import SessionLocal
from app.models.all_models import User, UserRole
from app.auth.auth_handler import hash_password

def create_admin():
    db = SessionLocal()
    
    try:
        print("=" * 50)
        print("Create New Admin User")
        print("=" * 50)
        
        # Get user input
        email = input("Enter email: ").strip()
        if not email:
            print("❌ Email cannot be empty!")
            return
        
        # Check if user already exists
        existing_user = db.query(User).filter(User.email == email).first()
        if existing_user:
            print(f"❌ User with email '{email}' already exists!")
            response = input("Do you want to update the password? (y/n): ").strip().lower()
            if response == 'y':
                password = input("Enter new password: ").strip()
                if not password:
                    print("❌ Password cannot be empty!")
                    return
                existing_user.hashed_password = hash_password(password)
                existing_user.role = UserRole.STAFF
                db.commit()
                print(f"✅ User '{email}' password updated and set as STAFF!")
            return
        
        password = input("Enter password: ").strip()
        if not password:
            print("❌ Password cannot be empty!")
            return
        
        full_name = input("Enter full name (optional): ").strip() or "Admin User"
        
        # Create admin user
        admin = User(
            email=email,
            hashed_password=hash_password(password),
            full_name=full_name,
            role=UserRole.STAFF
        )
        
        db.add(admin)
        db.commit()
        
        print("=" * 50)
        print("✅ Admin user created successfully!")
        print("=" * 50)
        print(f"Email: {email}")
        print(f"Full Name: {full_name}")
        print(f"Role: STAFF")
        print("=" * 50)
        
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()

