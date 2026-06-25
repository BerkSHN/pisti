from pydantic import BaseModel, Field
from typing import List, Optional

class Event(BaseModel):
    emoji: str
    title: str
    location: str
    time: str
    date: str 
    joined: int
    max: int
    category: str
    creator: str
    owner_id: str
    avatar: str
    avatarColor: str
    desc: str
    tags: List[str]
    likes: List[str]
    comments: List[str]
    shares: int
    imageUrl: Optional[str] = None
    categoryColor: str


# 1. KAYIT OLMA ŞEMASI (Mevcut yapın, opsiyonel yeni alanlar eklendi)
class RegisterRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=80)
    email: str = Field(min_length=5, max_length=120)
    username: str = Field(min_length=3, max_length=30)
    password: str = Field(min_length=6, max_length=72)
    joined_events: List[str] = Field(default=[])
    # 🎯 Veritabanına varsayılan değerlerle yazılması için ekledik:
    bio: Optional[str] = Field(default="", max_length=300)
    profile_image: Optional[str] = Field(default=None) # Base64 String tutacak

# 2. PROFİL GÜNCELLEME ŞEMASI (ProfileUpdateScreen'den gelen istekleri yakalar)
class UserUpdateModel(BaseModel):
    full_name: Optional[str] = Field(None, min_length=2, max_length=80)
    username: str = Field(min_length=3, max_length=30)
    email: Optional[str] = Field(None, min_length=5, max_length=120)
    bio: Optional[str] = Field(None, max_length=300)
    profile_image: Optional[str] = Field(None) # Seçilen yeni resmin Base64 kodu
    old_password: Optional[str] = Field(None, min_length=6, max_length=72)
    new_password: Optional[str] = Field(None, min_length=6, max_length=72)

# 3. VERİTABANINDAN ÖN YÜZE (FLUTTER) DÖNÜŞ ŞEMASI
class UserResponse(BaseModel):
    id: str
    full_name: str
    username: str
    email: str
    bio: str
    profile_image: Optional[str] = None
    joined_events: List[str]


class LoginRequest(BaseModel):
    email: str
    password: str
