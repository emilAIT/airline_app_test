# tests/utils/user.py

from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.config import settings


def _login_access_token(client: TestClient, email: str, password: str) -> str:
    r = client.post(
        f"{settings.API_V1_STR}/login/access-token",
        data={
            "username": email,
            "password": password,
        },
    )
    assert r.status_code == 200, r.text
    data = r.json()
    assert "access_token" in data
    return data["access_token"]


def authentication_token_from_email(
    *,
    client: TestClient,
    email: str,
    db: Session | None = None,
    password: str | None = None,
) -> dict[str, str]:
    """
    Используется в tests/conftest.py.
    Возвращает Authorization headers по email.
    """

    if password is None:
        if hasattr(settings, "EMAIL_TEST_USER") and email == settings.EMAIL_TEST_USER:
            if hasattr(settings, "EMAIL_TEST_USER_PASSWORD"):
                password = settings.EMAIL_TEST_USER_PASSWORD
            elif hasattr(settings, "FIRST_SUPERUSER_PASSWORD"):
                password = settings.FIRST_SUPERUSER_PASSWORD
            else:
                raise AssertionError(
                    "No password available in settings for test user"
                )
        else:
            raise AssertionError(
                "Password must be provided for non default test user"
            )

    token = _login_access_token(client, email, password)
    return {"Authorization": f"Bearer {token}"}


def user_authentication_headers(
    *,
    client: TestClient,
    email: str,
    password: str,
) -> dict[str, str]:
    token = _login_access_token(client, email, password)
    return {"Authorization": f"Bearer {token}"}
