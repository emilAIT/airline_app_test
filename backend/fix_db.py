import sqlite3
import os
import json

db_path = 'airline.db'
if not os.path.exists(db_path):
    print(f"Database {db_path} not found!")
    exit(1)

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# 1. Get available airplanes
cur.execute("SELECT id FROM airplanes LIMIT 1")
row = cur.fetchone()
if not row:
    print("No airplanes found! Creating a default one.")
    cur.execute("INSERT INTO airplanes (model) VALUES ('Boeing 737')")
    airplane_id = cur.lastrowid
    print(f"Created airplane with ID {airplane_id}")
    
    # Create a simple seat map JSON
    seats = []
    for r in range(1, 11):
        for l in ['A', 'B', 'C', 'D', 'E', 'F']:
            seats.append({
                "row": r,
                "label": f"{r}{l}",
                "category": "STANDARD"
            })
    
    cur.execute("INSERT INTO seat_map_templates (airplane_id, seats_json) VALUES (?, ?)", 
                (airplane_id, json.dumps(seats)))
    print(f"Created seat map template for airplane {airplane_id}")
else:
    airplane_id = row[0]
    print(f"Found existing airplane with ID {airplane_id}")

# 2. Assign this airplane to all flights that don't have one
cur.execute("UPDATE flights SET airplane_id = ? WHERE airplane_id IS NULL", (airplane_id,))
print(f"Updated {cur.rowcount} flights with airplane ID {airplane_id}")

conn.commit()
conn.close()
print("Done!")
