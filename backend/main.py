from datetime import datetime, timedelta, timezone
import os
from uuid import uuid4
from typing import Optional, List
import bcrypt
import jwt
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.middleware.cors import CORSMiddleware
from bson import ObjectId
from pydantic import BaseModel

from database import events_collection, revoked_tokens_collection, users_collection
from models import Event, LoginRequest, RegisterRequest, UserUpdateModel

app = FastAPI()

JWT_SECRET = os.getenv("JWT_SECRET", "development-secret-change-me")
JWT_ALGORITHM = "HS256"
bearer_scheme = HTTPBearer()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class CommentCreate(BaseModel):
    user_id: str
    username: str
    text: str
    avatar: Optional[str] = None

class LikeToggle(BaseModel):
    user_id: str

class EventImageUpdate(BaseModel):
    imageUrl: str

class UpdateProfileRequest(BaseModel):
    username: Optional[str] = None
    email: Optional[str] = None
    bio: Optional[str] = None
    old_password: Optional[str] = None
    new_password: Optional[str] = None

def event_serializer(event):
    return {
        "id": str(event["_id"]),
        "emoji": event["emoji"],
        "title": event["title"],
        "location": event["location"],
        "time": event["time"],
        "city": event.get("city", "Edirne"), 
        "date": event.get("date", ""),
        "joined": event["joined"],
        "max": event["max"],
        "category": event["category"],
        "creator": event["creator"],
        "owner_id": event["owner_id"],
        "avatar": event["avatar"],
        "avatarColor": event["avatarColor"],
        "desc": event["desc"],
        "tags": event["tags"],
        "likes": event["likes"],
        "comments": event["comments"],
        "shares": event["shares"],
        "imageUrl": event.get("imageUrl"),
        "categoryColor": event["categoryColor"]
    }


def user_serializer(user):
    return {
        "id": str(user["_id"]),
        "full_name": user["full_name"],
        "email": user["email"],
        "username": user["username"],
        "bio": user.get("bio", ""), # 🎯 Serializer'a eklendi
        "profile_image": user.get("profile_image", None), # 🎯 Serializer'a eklendi
        "joined_events": user.get("joined_events", [])
    }


def create_access_token(user_id: str):
    expires_at = datetime.now(timezone.utc) + timedelta(days=7)
    return jwt.encode(
        {"sub": user_id, "jti": str(uuid4()), "exp": expires_at},
        JWT_SECRET,
        algorithm=JWT_ALGORITHM,
    )


def password_is_valid(password: str, password_hash: str):
    try:
        return bcrypt.checkpw(
            password.encode("utf-8"),
            password_hash.encode("utf-8"),
        )
    except ValueError:
        return False
    
class JoinEventRequest(BaseModel):
    user_id: str   
    event_id: str  


@app.post("/auth/register", status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest):
    email = request.email.strip().lower()
    username = request.username.strip().lower()

    if "@" not in email:
        raise HTTPException(status_code=422, detail="Geçerli bir e-posta girin")

    if len(request.password.encode("utf-8")) > 72:
        raise HTTPException(status_code=422, detail="Şifre çok uzun")

    existing_user = await users_collection.find_one(
        {"$or": [{"email": email}, {"username": username}]}
    )
    if existing_user:
        detail = (
            "Bu e-posta zaten kayıtlı"
            if existing_user["email"] == email
            else "Bu kullanıcı adı zaten alınmış"
        )
        raise HTTPException(status_code=409, detail=detail)

    password_hash = bcrypt.hashpw(
        request.password.encode("utf-8"),
        bcrypt.gensalt(),
    ).decode("utf-8")

    result = await users_collection.insert_one(
        {
            "full_name": request.full_name.strip(),
            "email": email,
            "username": username,
            "password_hash": password_hash,
            "bio": "", # 🎯 Yeni kayıtlar varsayılan boş bio ile başlar
            "profile_image": None, # 🎯 Yeni kayıtlar varsayılan fotoğrafsız başlar
            "created_at": datetime.now(timezone.utc),
        }
    )
    user = await users_collection.find_one({"_id": result.inserted_id})

    return {
        "access_token": create_access_token(str(result.inserted_id)),
        "token_type": "bearer",
        "user": user_serializer(user),
    }


@app.post("/auth/login")
async def login(request: LoginRequest):
    email = request.email.strip().lower()
    user = await users_collection.find_one({"email": email})

    if not user or not password_is_valid(request.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="E-posta veya şifre hatalı")

    return {
        "access_token": create_access_token(str(user["_id"])),
        "token_type": "bearer",
        "user": user_serializer(user),
    }


@app.post("/auth/logout")
async def logout(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
):
    try:
        payload = jwt.decode(
            credentials.credentials,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
        )
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Geçersiz oturum")

    token_id = payload.get("jti")
    expires_at = payload.get("exp")
    if not token_id or not expires_at:
        raise HTTPException(status_code=401, detail="Geçersiz oturum")

    await revoked_tokens_collection.update_one(
        {"jti": token_id},
        {
            "$set": {
                "jti": token_id,
                "user_id": payload.get("sub"),
                "expires_at": datetime.fromtimestamp(expires_at, timezone.utc),
                "revoked_at": datetime.now(timezone.utc),
            }
        },
        upsert=True,
    )

    return {"message": "Çıkış başarılı"}

@app.post("/events")
async def create_event(event: Event, user_id: str):
    try:
        event_dict = event.model_dump()

        event_dict.setdefault("date", "")
        event_dict.setdefault("time", "")
        
        event_dict["datetime"] = f"{event_dict['date']} {event_dict['time']}".strip()
        
        event_dict["joined"] = 1 
        event_dict["owner_id"] = user_id
        
        result = await events_collection.insert_one(event_dict)
        event_id_str = str(result.inserted_id)
        
        await users_collection.update_one(
            {"_id": ObjectId(user_id)},
            {"$addToSet": {"joined_events": event_id_str}}
        )
        
        created = await events_collection.find_one({"_id": result.inserted_id})
        return event_serializer(created)
        
    except Exception as e:
        print(f"Etkinlik Oluşturma Hatası: {str(e)}")
        raise HTTPException(status_code=400, detail=f"İşlem başarısız: {str(e)}")

@app.get("/events")
async def get_events():
    events = []
    async for event in events_collection.find():
        events.append(event_serializer(event))
    return events

@app.get("/events/{event_id}")
async def get_event(event_id: str):
    event = await events_collection.find_one({"_id": ObjectId(event_id)})
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    return event_serializer(event)

@app.put("/events/{event_id}")
async def update_event(event_id: str, updated_event: Event):
    event_dict = updated_event.model_dump()
    event_dict.setdefault("date", "")
    event_dict.setdefault("time", "")
    event_dict["datetime"] = f"{event_dict['date']} {event_dict['time']}".strip()
    
    result = await events_collection.update_one(
        {"_id": ObjectId(event_id)},
        {"$set": event_dict}
    )

    if result.modified_count == 0:
        raise HTTPException(status_code=404, detail="Event not found")

    event = await events_collection.find_one({"_id": ObjectId(event_id)})
    return event_serializer(event)

@app.delete("/events/{event_id}")
async def delete_event(event_id: str):
    result = await events_collection.delete_one({"_id": ObjectId(event_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Event not found")
    return {"message": "Event deleted successfully"}

@app.post("/join_event")
async def join_event(request: JoinEventRequest):
    try:
        user_oid = ObjectId(request.user_id)
        user_result = await users_collection.update_one(
            {"_id": user_oid},
            {"$addToSet": {"joined_events": request.event_id}}
        )
        
        if user_result.modified_count > 0:
            await events_collection.update_one(
                {"_id": ObjectId(request.event_id)},
                {"$inc": {"joined": 1}}
            )
            
        return {"success": True, "message": "Etkinliğe başarıyla katıldınız."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/leave_event")
async def leave_event(request: JoinEventRequest):
    try:
        user_oid = ObjectId(request.user_id)
        user_result = await users_collection.update_one(
            {"_id": user_oid},
            {"$pull": {"joined_events": request.event_id}}
        )
        
        if user_result.modified_count > 0:
            await events_collection.update_one(
                {"_id": ObjectId(request.event_id)},
                {"$inc": {"joined": -1}}
            )
            
        return {"success": True, "message": "Etkinlikten başarıyla ayrıldınız."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/users/{user_id}")
async def get_user_profile(user_id: str):
    try:
        user = await users_collection.find_one({"_id": ObjectId(user_id)})
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        
        return {
            "id": str(user["_id"]),
            "full_name": user.get("full_name", "İsimsiz Kullanıcı"),
            "username": user.get("username", ""),
            "email": user.get("email", ""),
            "bio": user.get("bio", ""),              
            "profile_image": user.get("profile_image", None),
            "joined_events": user.get("joined_events", [])
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/users/{user_id}/joined_events_details")
async def get_user_joined_events_details(user_id: str):
    try:
        user = await users_collection.find_one({"_id": ObjectId(user_id)})
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        
        joined_ids = user.get("joined_events", [])
        object_ids = [ObjectId(eid) for eid in joined_ids if eid]
        events_cursor = events_collection.find({"_id": {"$in": object_ids}})
        events = await events_cursor.to_list(length=100)
        
        serialized_events = []
        for e in events:
            s_event = event_serializer(e)
            s_event["status"] = "Katıldın" 
            serialized_events.append(s_event)
            
        return serialized_events
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/users/{user_id}/created-events")
async def get_user_created_events(user_id: str):
    return []


@app.put("/users/{user_id}")
async def update_profile(user_id: str, update_data: UserUpdateModel):
    try:
        user = await users_collection.find_one({"_id": ObjectId(user_id)})
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        
        update_dict = {}
        
        if update_data.new_password:
            if not update_data.old_password:
                raise HTTPException(status_code=400, detail="Şifre değiştirmek için mevcut şifrenizi girmelisiniz.")
            if not password_is_valid(update_data.old_password, user["password_hash"]):
                raise HTTPException(status_code=400, detail="Mevcut şifreniz hatalı.")
            update_dict["password_hash"] = bcrypt.hashpw(update_data.new_password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
        
        if update_data.full_name is not None:
            update_dict["full_name"] = update_data.full_name
            
        if update_data.username is not None:
            update_dict["username"] = update_data.username.strip().lower().replace(" ", "")
            
        if update_data.email is not None:
            update_dict["email"] = update_data.email
            
        if update_data.bio is not None:
            update_dict["bio"] = update_data.bio
            
        if update_data.profile_image is not None:
            update_dict["profile_image"] = update_data.profile_image 

        if update_dict:
            # 1. Önce kullanıcının kendi profil bilgilerini veritabanında güncelliyoruz
            await users_collection.update_one(
                {"_id": ObjectId(user_id)},
                {"$set": update_dict}
            )
            
            # 2. 🎯 YENİ KONTROL: Geçmiş yorumları otomatik senkronize etme alanı
            # Eğer güncellenen bilgiler arasında kullanıcı adı veya profil fotoğrafı varsa devreye giriyor
            if "username" in update_dict or "profile_image" in update_dict:
                # Eğer kullanıcı o esnada değiştirmediyse, veritabanındaki mevcut (eski) değerini koru diyoruz:
                current_username = update_dict.get("username", user.get("username"))
                current_avatar = update_dict.get("profile_image", user.get("profile_image"))
                
                # Tek bir update_many sorgusuyla tüm etkinliklerdeki yorumları güncelliyoruz:
                await events_collection.update_many(
                    {"comments.user_id": str(user_id)}, # Bu kullanıcının yorum yaptığı etkinlikleri bul
                    {
                        "$set": {
                            "comments.$[elem].username": current_username, # İsmini taze değerle değiştir
                            "comments.$[elem].avatar": current_avatar       # Fotosunu taze değerle değiştir
                        }
                    },
                    array_filters=[{"elem.user_id": str(user_id)}] # Sadece bu kullanıcının yorum kutularını hedef al
                )
            
        return {"success": True, "message": "Profil başarıyla güncellendi ✨"}
        
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    
@app.put("/events/update-creator/{user_id}")
async def update_event_creator(user_id: str, payload: dict):
    try:
        creator_name = payload.get("creator")
        avatar_image = payload.get("avatar")
        
        if not creator_name:
            raise HTTPException(status_code=400, detail="Kullanıcı adı alanı zorunludur.")
            
        # MongoDB'de owner_id'si (veya etkinliklerde tuttuğun yapıya göre userId) 
        # bu user_id olan tüm etkinlik dokümanlarını bulup toplu güncelliyoruz.
        # Not: create_event fonksiyonunda 'owner_id' olarak kaydettiğin için sorguyu 'owner_id' ye göre yapıyoruz.
        result = await events_collection.update_many(
            {"owner_id": user_id},
            {"$set": {
                "creator": creator_name,
                "avatar": avatar_image
            }}
        )
        
        return {
            "success": True, 
            "message": f"{result.modified_count} etkinlik başarıyla güncellendi."
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    
@app.put("/events/update-image/{event_id}")
async def update_event_image(event_id: str, data: EventImageUpdate):
    try:
        # 🎯 Senin veritabanı yapına uygun olarak events_collection kullanıyoruz:
        result = await events_collection.update_one(
            {"_id": ObjectId(event_id)},
            {"$set": {"imageUrl": data.imageUrl}}
        )

        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Etkinlik bulunamadı")

        return {"success": True, "message": "Etkinlik fotoğrafı başarıyla güncellendi"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/events/{event_id}/comment")
async def add_comment(event_id: str, data: CommentCreate):
    try:
        comment_data = {
            "user_id": str(data.user_id),
            "username": data.username,
            "text": data.text,
            "avatar": data.avatar, # 🎯 YENİ: Profil resmini de yorumun içine kaydediyoruz
            "created_at": datetime.utcnow().isoformat()
        }
        
        result = await events_collection.update_one(
            {"_id": ObjectId(event_id)},
            {"$push": {"comments": comment_data}}
        )
        
        if result.matched_count == 0:
            raise HTTPException(status_code=404, detail="Etkinlik bulunamadı")
            
        return {"success": True, "comment": comment_data}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/events/{event_id}/toggle-like")
async def toggle_like(event_id: str, data: LikeToggle):
    try:
        # Etkinliği buluyoruz
        event = await events_collection.find_one({"_id": ObjectId(event_id)})
        if not event:
            raise HTTPException(status_code=404, detail="Etkinlik bulunamadı")
            
        # 'likes' artık bir liste
        likes_list = event.get("likes", [])
        user_str_id = str(data.user_id)
        
        if user_str_id in likes_list:
            # Kullanıcı zaten beğenmiş, ID'sini listeden siliyoruz
            await events_collection.update_one(
                {"_id": ObjectId(event_id)},
                {"$pull": {"likes": user_str_id}}
            )
            liked = False
        else:
            # Kullanıcı ilk defa beğeniyor, ID'sini listeye ekliyoruz
            await events_collection.update_one(
                {"_id": ObjectId(event_id)},
                {"$push": {"likes": user_str_id}}
            )
            liked = True
            
        # Güncellenmiş etkinliği çekip yeni listenin eleman sayısını buluyoruz
        updated_event = await events_collection.find_one({"_id": ObjectId(event_id)})
        updated_likes_list = updated_event.get("likes", [])
        
        return {
            "success": True, 
            "liked": liked, 
            # 🎯 Beğeni sayısını front-end'e listenin uzunluğu olarak veriyoruz:
            "likes_count": len(updated_likes_list),
            "likes_list": updated_likes_list
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))