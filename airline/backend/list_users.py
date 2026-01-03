from app.database import SessionLocal
from app.models.all_models import User

db = SessionLocal()
users = db.query(User).all()

print(f"Found {len(users)} users:")
for u in users:
    print(f"ID: {u.id}, Email: {u.email}, Role: {u.role}")
