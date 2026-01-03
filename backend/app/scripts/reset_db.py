"""Database reset utility (development only).

Deletes the local SQLite database file and (optionally) reseeds data.

Usage:
    .\.venv\Scripts\python.exe -m app.scripts.reset_db --yes --seed
    .\.venv\Scripts\python.exe -m app.scripts.reset_db --yes --seed --days 60 --flights-per-day 40

This is intended for local development/testing.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from app.config import settings
from app.database import init_db, SessionLocal


def _sqlite_db_files_from_url(database_url: str) -> list[Path]:
    if not database_url.startswith("sqlite:///"):
        raise ValueError(f"reset_db only supports sqlite URLs, got: {database_url}")

    # Examples:
    # sqlite:///./zaku.db  -> ./zaku.db
    # sqlite:////abs/path  -> /abs/path
    raw_path = database_url.removeprefix("sqlite:///")

    db_path = Path(raw_path)
    # If it's relative, resolve it relative to the current working directory
    # (backend/ is the intended cwd).
    db_path = db_path.resolve()

    # SQLite might also create -wal / -shm files.
    return [
        db_path,
        Path(str(db_path) + "-wal"),
        Path(str(db_path) + "-shm"),
    ]


def reset_db(*, seed: bool, days: int, flights_per_day: int, random_seed: int) -> None:
    db_files = _sqlite_db_files_from_url(settings.database_url)

    deleted_any = False
    for path in db_files:
        if path.exists():
            path.unlink()
            deleted_any = True

    if deleted_any:
        print("Deleted SQLite DB files:")
        for path in db_files:
            print(f"  - {path}")
    else:
        print("ℹ️  No SQLite DB files found to delete.")

    init_db()
    print("Database initialized")

    if seed:
        from app.scripts.seed_data import (
            seed_airports,
            seed_airplanes,
            seed_staff_user,
            seed_flights,
        )

        db = SessionLocal()
        try:
            seed_airports(db)
            seed_airplanes(db)
            seed_staff_user(db)
            seed_flights(
                db,
                days=days,
                flights_per_day=flights_per_day,
                random_seed=random_seed,
            )
        finally:
            db.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Reset local SQLite database (dev only).")
    parser.add_argument("--yes", action="store_true", help="Confirm destructive reset")
    parser.add_argument("--seed", action="store_true", help="Reseed airports/airplanes/flights/staff user")
    parser.add_argument("--days", type=int, default=60, help="How many days of flights to seed")
    parser.add_argument("--flights-per-day", type=int, default=40, help="How many flights per day to seed")
    parser.add_argument("--random-seed", type=int, default=42, help="Deterministic random seed for flight generation")

    args = parser.parse_args()
    if not args.yes:
        parser.error("Refusing to reset without --yes")

    reset_db(seed=args.seed, days=args.days, flights_per_day=args.flights_per_day, random_seed=args.random_seed)


if __name__ == "__main__":
    main()
