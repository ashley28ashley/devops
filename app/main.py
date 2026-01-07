import time
import random
import psycopg2
import os

DB_HOST = os.getenv("DB_HOST", "db")
DB_NAME = os.getenv("DB_NAME", "jobs")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

def connect_db():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

while True:
    try:
        conn = connect_db()
        cur = conn.cursor()

        value = random.randint(1, 1000)

        cur.execute(
            "INSERT INTO results(value) VALUES (%s);",
            (value,)
        )

        conn.commit()
        cur.close()
        conn.close()

        print(f"✅ Job processed: {value}")

        time.sleep(5)

    except Exception as e:
        print(f"❌ Error: {e}")
        time.sleep(5)
