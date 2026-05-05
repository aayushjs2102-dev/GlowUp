"""
GlowUp – SQLAlchemy database models.

Defines the User table and provides helpers for creating / connecting
to the SQLite database.
"""

from sqlalchemy import Column, Integer, Float, String, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

SQLALCHEMY_DATABASE_URL = "sqlite:///./glowup.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},  # required for SQLite
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


# ──────────────────────────────────────────────
# User model
# ──────────────────────────────────────────────
class User(Base):
    """Represents a registered user of the GlowUp app."""

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    age = Column(Integer, nullable=True)
    height_cm = Column(Float, nullable=True)
    weight_kg = Column(Float, nullable=True)
    preferred_language = Column(String, default="en", nullable=False)

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r}>"
