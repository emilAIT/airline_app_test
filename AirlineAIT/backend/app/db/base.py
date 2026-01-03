"""
SQLAlchemy declarative base class.

All model classes inherit from Base to enable ORM mapping.
Used by session.py for table creation.

Part of: Backend Core / Database
"""
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

