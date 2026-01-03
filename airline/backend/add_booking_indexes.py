import sqlite3
import os
import sys

# Get the database path
db_path = os.path.join(os.path.dirname(__file__), 'airline.db')

if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    sys.exit(1)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("Adding indexes to 'bookings' and 'seat_holds' tables...")

    # 1. idx_bookings_status
    print("Creating index: idx_bookings_status...")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings (status)")
    print("✅ idx_bookings_status created (or already exists)")

    # 2. idx_bookings_hold_until
    print("Creating index: idx_bookings_hold_until...")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_bookings_hold_until ON bookings (status, hold_until)")
    print("✅ idx_bookings_hold_until created (or already exists)")

    # 3. idx_seat_holds_expires_at
    print("Creating index: idx_seat_holds_expires_at...")
    # Note: Column name in DB is 'held_until' based on model
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_seat_holds_expires_at ON seat_holds (held_until)")
    print("✅ idx_seat_holds_expires_at created (or already exists)")

    conn.commit()
    conn.close()
    print("\n✅ Migration completed successfully!")

except Exception as e:
    print(f"\n❌ Error: {e}")
    sys.exit(1)
