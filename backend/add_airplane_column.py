from app.database import engine
from sqlalchemy import text

with engine.connect() as conn:
    conn.execute(text('ALTER TABLE flights ADD COLUMN airplane_id INTEGER'))
    conn.commit()
    print('Column airplane_id added successfully')
