"""
Скрипт для добавления недостающих колонок в таблицу ticket
"""
from sqlmodel import Session, text
from app.database import engine

def migrate_ticket_table():
    """Добавляет недостающие колонки в таблицу ticket"""
    with Session(engine) as session:
        try:
            # Проверяем, существуют ли колонки
            result = session.exec(text("PRAGMA table_info(ticket)")).all()
            existing_columns = [row[1] for row in result]
            
            print("Existing columns in ticket table:", existing_columns)
            
            # Добавляем недостающие колонки
            if 'passenger_phone' not in existing_columns:
                print("Adding column passenger_phone...")
                session.exec(text("ALTER TABLE ticket ADD COLUMN passenger_phone TEXT"))
                session.commit()
                print("OK: Column passenger_phone added")
            
            if 'passenger_passport_number' not in existing_columns:
                print("Adding column passenger_passport_number...")
                session.exec(text("ALTER TABLE ticket ADD COLUMN passenger_passport_number TEXT"))
                session.commit()
                print("OK: Column passenger_passport_number added")
            
            if 'passenger_nationality' not in existing_columns:
                print("Adding column passenger_nationality...")
                session.exec(text("ALTER TABLE ticket ADD COLUMN passenger_nationality TEXT"))
                session.commit()
                print("OK: Column passenger_nationality added")
            
            print("\nMigration completed successfully!")
            
        except Exception as e:
            print(f"ERROR during migration: {e}")
            session.rollback()
            raise

if __name__ == "__main__":
    print("Starting migration of ticket table...")
    migrate_ticket_table()

