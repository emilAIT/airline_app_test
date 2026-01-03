from collections.abc import Generator
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jwt.exceptions import InvalidTokenError
from pydantic import ValidationError
from sqlmodel import Session, select

from app.core import security
from app.core.config import settings
from app.db import engine
from app.models import TokenPayload, User, UserRole

reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/login/access-token"
)


def get_db() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session


SessionDep = Annotated[Session, Depends(get_db)]
TokenDep = Annotated[str, Depends(reusable_oauth2)]


def get_current_user(session: SessionDep, token: TokenDep) -> User:
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[security.ALGORITHM],
        )
        token_data = TokenPayload(**payload)
    except (InvalidTokenError, ValidationError) as e:
        print(f"deps.py: Token decode error - {e}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )

    if token_data.sub is None:
        print("deps.py: Token sub is None")
        raise HTTPException(status_code=403, detail="Invalid token")

    print(f"deps.py: Looking for user with ID: {token_data.sub}, Type: {type(token_data.sub)}")
    user = session.get(User, token_data.sub)
    if not user:
        print(f"deps.py: User not found with ID: {token_data.sub}")
        # Try to find user by email as fallback (for debugging)
        all_users = session.exec(select(User)).all()
        print(f"deps.py: Total users in database: {len(all_users)}")
        if all_users:
            print(f"deps.py: Sample user IDs: {[u.id for u in all_users[:3]]}")
            print(f"deps.py: Sample user ID types: {[type(u.id) for u in all_users[:3]]}")
            # Try to find user by email
            user_by_email = session.exec(select(User).where(User.email == settings.FIRST_SUPERUSER)).first()
            if user_by_email:
                print(f"deps.py: Found user by email - ID: {user_by_email.id}, Type: {type(user_by_email.id)}")
                print(f"deps.py: Token ID matches user ID? {token_data.sub == user_by_email.id}")
                print(f"deps.py: Token ID == user ID? {token_data.sub == str(user_by_email.id)}")
        raise HTTPException(status_code=404, detail="User not found")

    if not user.is_active:
        print(f"deps.py: User {user.id} is inactive")
        raise HTTPException(status_code=400, detail="Inactive user")

    print(f"deps.py: User found - ID: {user.id}, Email: {user.email}")
    return user

CurrentUser = Annotated[User, Depends(get_current_user)]

def get_current_staff_user(current_user: CurrentUser) -> User:
    if current_user.role != UserRole.STAFF:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions",
        )
    return current_user

CurrentStaffUser = Annotated[User, Depends(get_current_staff_user)]
