from app.database import SessionLocal
from app.models.all_models import User
from app.auth.auth_handler import hash_password

db = SessionLocal()
user = db.query(User).filter(User.email == "test@example.com").first()

if user:
    print(f"Resetting password for {user.email}...")
    user.hashed_password = hash_password("password123")
    db.commit()
    print("Password reset to 'password123' successful.")
else:
    print("User not found.")
