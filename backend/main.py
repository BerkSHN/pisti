from datetime import datetime, timedelta, timezone
import os
from uuid import uuid4

import bcrypt
import jwt
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.middleware.cors import CORSMiddleware
from bson import ObjectId

from database import events_collection, revoked_tokens_collection, users_collection
from models import Event, LoginRequest, RegisterRequest

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
async def create_event(event: Event):

    result = await events_collection.insert_one(
        event.model_dump()
    )

    created = await events_collection.find_one(
        {"_id": result.inserted_id}
    )

    return event_serializer(created)

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
