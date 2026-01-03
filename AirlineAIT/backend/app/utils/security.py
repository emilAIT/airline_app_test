from datetime import datetime, timedelta
from typing import Optional
from zoneinfo import ZoneInfo
from jose import JWTError, jwt
import bcrypt
from hashlib import sha256
from app.core.config import settings


def _pre_hash_password(password: str) -> str:
    """
    Pre-hash password with SHA-256 to handle passwords longer than 72 bytes.
    Bcrypt has a 72-byte limit, so we hash with SHA-256 first (produces 32 bytes),
    then hash that result with bcrypt.
    """
    return sha256(password.encode('utf-8')).hexdigest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify password by pre-hashing with SHA-256, then verifying with bcrypt.
    """
    try:
        pre_hashed = _pre_hash_password(plain_password)
        # Convert pre_hashed string to bytes for bcrypt
        pre_hashed_bytes = pre_hashed.encode('utf-8')
        # Verify with bcrypt
        return bcrypt.checkpw(pre_hashed_bytes, hashed_password.encode('utf-8'))
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    """
    Hash password by pre-hashing with SHA-256, then hashing with bcrypt.
    This allows passwords of any length while using bcrypt for security.
    """
    # Pre-hash with SHA-256 to handle passwords longer than 72 bytes
    # SHA-256 produces 64 hex characters = 32 bytes, well under bcrypt's 72 byte limit
    pre_hashed = _pre_hash_password(password)
    # Convert to bytes for bcrypt
    pre_hashed_bytes = pre_hashed.encode('utf-8')
    # Generate salt and hash with bcrypt
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(pre_hashed_bytes, salt)
    # Return as string
    return hashed.decode('utf-8')


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    kyrgyz_tz = ZoneInfo("Asia/Bishkek")
    now = datetime.now(kyrgyz_tz).replace(tzinfo=None)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def decode_access_token(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        return None

