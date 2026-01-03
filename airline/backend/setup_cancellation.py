"""
Script to create the CancellationPolicy and Refund tables and seed default policy.
Run: ./venv/bin/python setup_cancellation.py
"""
import sys
import os

# Required to import from `app`
sys.path.insert(0, os.path.dirname(__file__))

from app.database import engine, SessionLocal
from app.models.all_models import Base, CancellationPolicy, Refund

def main():
    print("Creating CancellationPolicy and Refund tables...")
    
    # Create tables
    CancellationPolicy.__table__.create(bind=engine, checkfirst=True)
    Refund.__table__.create(bind=engine, checkfirst=True)
    
    print("Tables created (if not exist).")
    
    db = SessionLocal()
    
    # Check if a policy already exists
    existing = db.query(CancellationPolicy).filter(CancellationPolicy.is_active == True).first()
    if existing:
        print(f"Active policy already exists (id={existing.id}). Skipping seed.")
        db.close()
        return

    # Seed default policy
    default_policy = CancellationPolicy(
        min_hours_before_departure=24,
        allow_card_refund=True,
        allow_apple_pay_refund=True,
        refund_fee_percent=0,
        is_active=True
    )
    db.add(default_policy)
    db.commit()
    print(f"Default active policy created (id={default_policy.id})")
    
    db.close()
    print("Done.")

if __name__ == "__main__":
    main()
