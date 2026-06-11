from motor.motor_asyncio import AsyncIOMotorClient

MONGO_URL = "mongodb+srv://erenemiremre36:1234@micros.eqsf3m6.mongodb.net/"

client = AsyncIOMotorClient(MONGO_URL)

db = client.pisti

events_collection = db.events