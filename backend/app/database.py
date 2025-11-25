from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional
import os
from dotenv import load_dotenv

load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "careflowai")


class Database:
    client: Optional[AsyncIOMotorClient] = None


db = Database()


async def get_database():
    return db.client[DATABASE_NAME]


async def connect_to_mongo():
    """Connect to MongoDB"""
    db.client = AsyncIOMotorClient(MONGODB_URL)
    print(f"Connected to MongoDB at {MONGODB_URL}")
    print(f"Using database: {DATABASE_NAME}")


async def close_mongo_connection():
    """Close MongoDB connection"""
    if db.client:
        db.client.close()
        print("Closed MongoDB connection")


async def get_db():
    """Dependency for getting database instance"""
    database = await get_database()
    try:
        yield database
    finally:
        pass
