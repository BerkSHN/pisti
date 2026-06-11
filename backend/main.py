from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from bson import ObjectId

from database import events_collection
from models import Event

app = FastAPI()

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