"""Script to add created_at column to payments table"""
import sqlite3
import sys
import os

# Get the database path
db_path = os.path.join(os.path.dirname(__file__), 'app', 'airline.db')

if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    print("The payments table will be created automatically when you start the backend.")
    sys.exit(0)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check if table exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='payments'")
    if not cursor.fetchone():
        print("Payments table does not exist yet. It will be created when you start the backend.")
        conn.close()
        sys.exit(0)
    
    # Check if columns exist
    cursor.execute("PRAGMA table_info(payments)")
    columns = [row[1] for row in cursor.fetchall()]
    
    print(f"Current columns in payments table: {columns}")
    
    # Add created_at column if it doesn't exist
    if 'created_at' not in columns:
        print("Adding 'created_at' column...")
        cursor.execute("ALTER TABLE payments ADD COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP")
        print("✅ Added 'created_at' column")
    else:
        print("✅ 'created_at' column already exists")
    
    conn.commit()
    conn.close()
    
    print("\n✅ Database schema updated successfully!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)

