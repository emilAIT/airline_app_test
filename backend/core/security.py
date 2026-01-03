from datetime import datetime, timedelta, timezone
import hashlib

from jose import jwt
from passlib.context import CryptContext

from core.config import settings


# ---------------- PASSWORD HASHING ----------------

pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)


import hashlib
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def _normalize_password(password: str) -> str:
    """
    SHA-256 → hex string (строка <= 64 символа)
    Bcrypt теперь никогда не получит >72 байт
    """
    return hashlib.sha256(password.encode("utf-8")).hexdigest()

def hash_password(password: str) -> str:
    normalized = _normalize_password(password)
    return pwd_context.hash(normalized)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    normalized = _normalize_password(plain_password)
    return pwd_context.verify(normalized, hashed_password)


# ---------------- JWT TOKENS ----------------

def create_access_token(
    subject: str | int,
    expires_delta: timedelta | None = None,
) -> str:
    """
    Create JWT access token.
    """
    expire = datetime.now(timezone.utc) + (
        expires_delta
        or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    payload = {
        "sub": str(subject),
        "exp": expire,
        "iat": datetime.now(timezone.utc),
    }

    return jwt.encode(
        payload,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM,
    )
