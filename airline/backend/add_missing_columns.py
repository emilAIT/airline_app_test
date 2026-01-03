"""Script to add missing gate and terminal columns to flights table"""
import sqlite3
import sys
import os

# Get the database path
db_path = os.path.join(os.path.dirname(__file__), 'airline.db')

if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    sys.exit(1)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Check if columns exist
    cursor.execute("PRAGMA table_info(flights)")
    columns = [row[1] for row in cursor.fetchall()]

    print(f"Current columns in flights table: {columns}")

    # Add gate column if it doesn't exist
    if 'gate' not in columns:
        print("Adding 'gate' column...")
        cursor.execute("ALTER TABLE flights ADD COLUMN gate VARCHAR")
        print("✅ Added 'gate' column")
    else:
        print("✅ 'gate' column already exists")

    # Add terminal column if it doesn't exist
    if 'terminal' not in columns:
        print("Adding 'terminal' column...")
        cursor.execute("ALTER TABLE flights ADD COLUMN terminal VARCHAR")
        print("✅ Added 'terminal' column")
    else:
        print("✅ 'terminal' column already exists")

    conn.commit()
    conn.close()

    print("\n✅ Database schema updated successfully!")
    print("You can now restart the backend server.")

except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
