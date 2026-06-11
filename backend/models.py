from pydantic import BaseModel
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