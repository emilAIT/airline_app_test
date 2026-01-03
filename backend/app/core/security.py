"""Security utilities - password hashing and JWT token management.

Why not passlib?
- `passlib==1.7.4` + newer `bcrypt` can crash at runtime (and spam
    "error reading bcrypt version") which turns auth into 500s.
- Newer `bcrypt` versions also enforce the 72-byte limit with an exception.

We implement hashing/verification directly with `bcrypt` and use a SHA-256
pre-hash fallback to safely support long passwords.
"""

from datetime import datetime, timedelta
from typing import Optional
import hashlib

import bcrypt
from jose import JWTError, jwt

from app.config import settings


def _pw_bytes(password: str) -> bytes:
        return password.encode('utf-8')


def _pw_prehash(password: str) -> bytes:
        # Fixed-size (32 bytes) pre-hash so bcrypt never sees >72 bytes.
        return hashlib.sha256(_pw_bytes(password)).digest()


def hash_password(password: str) -> str:
    """
    Hash a plain password using bcrypt.
    
    Args:
        password: Plain text password
        
    Returns:
        Hashed password string
    """
    # Always hash the pre-hash to avoid bcrypt 72-byte errors.
    # Use rounds=4 for dev (fast), default 12 for production (slow but secure)
    rounds = 4 if settings.debug else 12
    hashed = bcrypt.hashpw(_pw_prehash(password), bcrypt.gensalt(rounds=rounds))
    return hashed.decode('utf-8')


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain password against a hashed password.
    
    Args:
        plain_password: Plain text password from user
        hashed_password: Hashed password from database
        
    Returns:
        True if password matches, False otherwise
    """
    try:
        hashed = hashed_password.encode('utf-8')
    except Exception:
        return False

    # Backward compatible:
    # 1) Try raw password (works for legacy hashes created without pre-hash).
    # 2) Fall back to SHA-256 pre-hash (works for new hashes).
    try:
        if bcrypt.checkpw(_pw_bytes(plain_password), hashed):
            return True
    except ValueError:
        # Likely >72 bytes on newer bcrypt.
        pass
    except Exception:
        return False

    try:
        return bcrypt.checkpw(_pw_prehash(plain_password), hashed)
    except Exception:
        return False


def create_access_token(user_id: int, role: str, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create JWT access token with user_id and role in payload.
    
    Args:
        user_id: User's database ID
        role: User's role (PASSENGER or STAFF)
        expires_delta: Optional expiration time delta (default: 24 hours)
        
    Returns:
        Encoded JWT token string
    """
    if expires_delta is None:
        expires_delta = timedelta(minutes=settings.access_token_expire_minutes)
    
    expire = datetime.utcnow() + expires_delta
    
    # JWT payload
    payload = {
        "sub": str(user_id),  # subject = user_id
        "role": role,         # PASSENGER or STAFF
        "exp": expire         # expiration time
    }
    
    encoded_jwt = jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)
    return encoded_jwt


def decode_access_token(token: str) -> dict:
    """
    Decode and verify JWT token.
    
    Args:
        token: JWT token string
        
    Returns:
        Decoded payload dict with 'sub' (user_id) and 'role'
        
    Raises:
        JWTError: If token is invalid or expired
    """
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        return payload
    except JWTError:
        raise JWTError("Could not validate token")
