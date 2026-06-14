from datetime import datetime, timedelta, timezone
import os

import bcrypt
import jwt
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from bson import ObjectId
from pydantic import BaseModel

from database import events_collection, users_collection
from models import Event, LoginRequest, RegisterRequest

app = FastAPI()

JWT_SECRET = os.getenv("JWT_SECRET", "development-secret-change-me")
JWT_ALGORITHM = "HS256"

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def event_serializer(event):
    return {
        "id": str(event["_id"]),
        "emoji": event["emoji"],
        "title": event["title"],
        "location": event["location"],
        "time": event["time"],
        "joined": event["joined"],
        "max": event["max"],
        "category": event["category"],
        "creator": event["creator"],
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
        "joined_events": user.get("joined_events", [])
    }


def create_access_token(user_id: str):
    expires_at = datetime.now(timezone.utc) + timedelta(days=7)
    return jwt.encode(
        {"sub": user_id, "exp": expires_at},
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

@app.post("/events")
async def create_event(event: Event, user_id: str):
    try:
        event_dict = event.model_dump()
        
        # Etkinlik ilk başta kesinlikle 1 katılımcı (oluşturan kişi) ile başlasın
        event_dict["joined"] = 1 
        event_dict["owner_id"] = user_id
        
        # 1. Etkinliği veritabanına kaydet
        result = await events_collection.insert_one(event_dict)
        event_id_str = str(result.inserted_id)
        
        # 2. Kullanıcının katıldığı etkinlikler listesine BU etkinliğin string ID'sini ekle
        # Burada modified_count kontrolü yapmadan doğrudan push/addToSet atıyoruz
        await users_collection.update_one(
            {"_id": ObjectId(user_id)},
            {"$addToSet": {"joined_events": event_id_str}}
        )
        
        # 3. Güncel dökümanı bul ve sarmalayıcıdan (serializer) geçirerek dön
        created = await events_collection.find_one({"_id": result.inserted_id})
        return event_serializer(created)
        
    except Exception as e:
        print(f"Etkinlik Oluşturma Hatası: {str(e)}")
        raise HTTPException(status_code=400, detail=f"İşlem başarısız: {str(e)}")

@app.get("/events")
async def get_events():

    events = []

    async for event in events_collection.find():
        events.append(
            event_serializer(event)
        )

    return events

@app.get("/events/{event_id}")
async def get_event(event_id: str):

    event = await events_collection.find_one(
        {"_id": ObjectId(event_id)}
    )

    if not event:
        raise HTTPException(
            status_code=404,
            detail="Event not found"
        )

    return event_serializer(event)

@app.put("/events/{event_id}")
async def update_event(
    event_id: str,
    updated_event: Event
):

    result = await events_collection.update_one(
        {"_id": ObjectId(event_id)},
        {"$set": updated_event.model_dump()}
    )

    if result.modified_count == 0:
        raise HTTPException(
            status_code=404,
            detail="Event not found"
        )

    event = await events_collection.find_one(
        {"_id": ObjectId(event_id)}
    )

    return event_serializer(event)

@app.delete("/events/{event_id}")
async def delete_event(event_id: str):

    result = await events_collection.delete_one(
        {"_id": ObjectId(event_id)}
    )

    if result.deleted_count == 0:
        raise HTTPException(
            status_code=404,
            detail="Event not found"
        )

    return {
        "message": "Event deleted successfully"
    }

@app.post("/join_event")
async def join_event(request: JoinEventRequest):
    try:
        user_oid = ObjectId(request.user_id)
        
        # 1. Kullanıcının listesine etkinliği ekle
        user_result = await users_collection.update_one(
            {"_id": user_oid},
            {"$addToSet": {"joined_events": request.event_id}}
        )
        
        # Eğer kullanıcı zaten katılmışsa (modified_count == 0), etkinlik sayacını boşuna artırma
        if user_result.modified_count > 0:
            # 2. Etkinliğin joined sayısını veritabanında 1 ARTIR
            await events_collection.update_one(
                {"_id": ObjectId(request.event_id)},
                {"$inc": {"joined": 1}} # MongoDB'nin artırma operatörü
            )
            
        return {"success": True, "message": "Etkinliğe başarıyla katıldınız."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/leave_event")
async def leave_event(request: JoinEventRequest):
    try:
        user_oid = ObjectId(request.user_id)
        
        # 1. Kullanıcının listesinden etkinliği sil
        user_result = await users_collection.update_one(
            {"_id": user_oid},
            {"$pull": {"joined_events": request.event_id}}
        )
        
        # Eğer kullanıcı gerçekten listeden silindiyse sayacı azalt
        if user_result.modified_count > 0:
            # 2. Etkinliğin joined sayısını veritabanında 1 AZALT
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
        
        # Kullanıcının sadece joined_events listesini dönmemiz yeterli
        return {
        "full_name": user.get("full_name", "İsimsiz Kullanıcı"),
        "username": user.get("username", ""),
        "email": user.get("email", ""),
        "joined_events": user.get("joined_events", [])
    }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/users/{user_id}/joined_events_details")
async def get_user_joined_events_details(user_id: str):
    try:
        # 1. Kullanıcıyı bul
        user = await users_collection.find_one({"_id": ObjectId(user_id)})
        if not user:
            raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        
        # 2. Kullanıcının katıldığı etkinliklerin ID listesini al
        joined_ids = user.get("joined_events", [])
        
        # 3. Bu ID'lere sahip tüm etkinlikleri veritabanından sorgula
        object_ids = [ObjectId(eid) for eid in joined_ids if eid]
        events_cursor = events_collection.find({"_id": {"$in": object_ids}})
        events = await events_cursor.to_list(length=100)
        
        # 4. Serileştirip listeyi dön (Varsayılan durum olarak hepsine 'Katıldın' basabiliriz)
        serialized_events = []
        for e in events:
            s_event = event_serializer(e)
            s_event["status"] = "Katıldın" # Sayfa tasarımı için statü ekliyoruz
            serialized_events.append(s_event)
            
        return serialized_events
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
# FastAPI (main.py veya ilgili router dosyası)

@app.get("/users/{user_id}/created-events")
async def get_user_created_events(user_id: str):
    # 🎯 Şimdilik boş liste dönüyoruz ki Flutter 404 almasın, 
    # ekran pürüzsüzce açılsın ve "Henüz bir etkinlik oluşturmadın" desin.
    return []