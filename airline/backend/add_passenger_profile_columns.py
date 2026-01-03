"""Script to add missing columns to passenger_profiles table"""
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
    cursor.execute("PRAGMA table_info(passenger_profiles)")
    columns = [row[1] for row in cursor.fetchall()]
    
    print(f"Current columns in passenger_profiles table: {columns}")
    
    # Add nationality column if it doesn't exist
    if 'nationality' not in columns:
        print("Adding 'nationality' column...")
        cursor.execute("ALTER TABLE passenger_profiles ADD COLUMN nationality VARCHAR")
        print("✅ Added 'nationality' column")
    else:
        print("✅ 'nationality' column already exists")
    
    # Add date_of_birth column if it doesn't exist
    if 'date_of_birth' not in columns:
        print("Adding 'date_of_birth' column...")
        cursor.execute("ALTER TABLE passenger_profiles ADD COLUMN date_of_birth DATE")
        print("✅ Added 'date_of_birth' column")
    else:
        print("✅ 'date_of_birth' column already exists")
    
    conn.commit()
    conn.close()
    
    print("\n✅ Database schema updated successfully!")
    print("You can now create bookings.")
    
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)

