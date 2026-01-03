from sqlalchemy import Column, Integer, ForeignKey, JSON
from sqlalchemy.orm import relationship
from db.base import Base
from typing import List

class SeatMapTemplates(Base):
    __tablename__ = "seat_map_templates"

    id = Column(Integer, primary_key=True, index=True)
    airplane_id = Column(Integer, ForeignKey("airplanes.id"), nullable=False)
    
    # Используем тип JSON. SQLAlchemy автоматически конвертирует его в dict/list
    # Если используете PostgreSQL, это создаст колонку типа JSONB
    seats_json = Column(JSON, nullable=False)

    airplane = relationship("Airplane", back_populates="seat_map_templates")
    
    ALLOWED_CATEGORIES = ["STANDARD", "EXTRA_LEGROOM"]

    def get_seat_map(self) -> List[dict]:
        """Возвращает карту мест (уже в виде списка благодаря типу JSON)"""
        return self.seats_json

    @property
    def total_seats_count(self) -> int:
        """Считает общее количество мест в шаблоне"""
        return len(self.seats_json) if self.seats_json else 0

    def preview_map(self) -> str:
        """Визуальное текстовое отображение карты мест"""
        seat_map = self.get_seat_map()
        if not seat_map:
            return "Empty Map"

        rows = {}
        for seat in seat_map:
            row = seat.get("row")
            label = seat.get("label")
            category = seat.get("category", "STANDARD").upper()
            
            if category not in self.ALLOWED_CATEGORIES:
                category = "STANDARD"
                
            if row not in rows:
                rows[row] = []
            rows[row].append(f"{label}({category[0]})")
            
        preview = ""
        for row_num in sorted(rows.keys()):
            preview += f"Row {row_num}: " + " ".join(sorted(rows[row_num])) + "\n"
        return preview