from pydantic import BaseModel
from datetime import date

class PassengerProfileBase(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    passport_number: str | None = None
    nationality: str | None = None
    date_of_birth: date | None = None

class PassengerProfileOut(PassengerProfileBase):
    class Config:
        from_attributes = True

class UserMeResponse(BaseModel):
    id: int
    email: str
    role: str
    profile: PassengerProfileOut | None

    class Config:
        from_attributes = True

# from pydantic import BaseModel, EmailStr, Field
# from datetime import datetime


# class UserBase(BaseModel):
#     email: EmailStr
#     role: str
#     is_active: bool

# class UserCreate(BaseModel):
#     email: EmailStr
#     password: str = Field(min_length=6)

# class UserStatusUpdate(BaseModel):
#     is_active: bool

# class UserResponse(UserBase):
#     id: int
#     created_at: datetime

#     class Config:
#         from_attributes = True

# class Token(BaseModel):
#     access_token: str
#     token_type: str = "bearer"

# class UserMe(BaseModel):
#     id: int
#     email: EmailStr
#     role: str

# class StaffCreate(BaseModel):
#     email: EmailStr
#     password: str = Field(min_length=6)

# class StaffResponse(BaseModel):
#     id: int
#     email: EmailStr
#     role: str
#     is_active: bool

#     class Config:
#         from_attributes = True
