"""Script to add missing ticket_number column to tickets table"""
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
    cursor.execute("PRAGMA table_info(tickets)")
    columns = [row[1] for row in cursor.fetchall()]
    
    print(f"Current columns in tickets table: {columns}")
    
    # Add ticket_number column if it doesn't exist
    if 'ticket_number' not in columns:
        print("Adding 'ticket_number' column...")
        cursor.execute("ALTER TABLE tickets ADD COLUMN ticket_number VARCHAR")
        print("✅ Added 'ticket_number' column")
    else:
        print("✅ 'ticket_number' column already exists")
    
    conn.commit()
    conn.close()
    
    print("\n✅ Database schema updated successfully!")
    print("You can now create bookings.")
    
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)

