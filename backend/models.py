from pydantic import BaseModel, Field
from typing import List, Optional

class Event(BaseModel):
    emoji: str
    title: str
    location: str
    time: str
    joined: int
    max: int
    category: str
    creator: str
    avatar: str
    avatarColor: str
    desc: str
    tags: List[str]
    likes: int
    comments: int
    shares: int
    imageUrl: Optional[str] = None
    categoryColor: str


class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=80)
    email: str = Field(min_length=5, max_length=120)
    username: str = Field(min_length=3, max_length=30)
    password: str = Field(min_length=6, max_length=72)
    joined_events: List[str] = Field(default=[])


class LoginRequest(BaseModel):
    email: str
    password: str
