from motor.motor_asyncio import AsyncIOMotorClient

MONGO_URL = "mongodb+srv://damlakoca839_db_user:1234@micros.eqsf3m6.mongodb.net/?appName=MICROS"
#MONGO_URL = "mongodb+srv://berksahin2331_db_user:1234@micros.eqsf3m6.mongodb.net/?appName=MICROS"
client = AsyncIOMotorClient(MONGO_URL)

db = client.pisti

events_collection = db.events
users_collection = db.users
revoked_tokens_collection = db.revoked_tokens
