from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.orm import declarative_base

# SQLite URL (позже можно заменить на PostgreSQL)
DATABASE_URL = "sqlite:///./airline.db"

# Engine
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},  # нужно для SQLite + FastAPI
)

# Session factory
SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
)

# Base class for db_models
Base = declarative_base()


def get_db():
    """
    Dependency for FastAPI.
    Creates a new DB session per request and closes it after.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
