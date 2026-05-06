import time
import random
import psycopg2
import os
from prometheus_client import start_http_server, Counter

DB_HOST = os.getenv("DB_HOST", "db")
DB_NAME = os.getenv("DB_NAME", "jobs")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# Déclaration de la métrique Prometheus
JOBS_PROCESSED = Counter('jobs_processed_total', 'Total number of processed jobs')

def connect_db():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )

def generate_job_value():
    return random.randint(1, 1000)

def main():
    # Démarrage du serveur Prometheus sur le port 8000
    start_http_server(8000)
    print("🚀 Prometheus metrics server started on port 8000")
    
    while True:
        try:
            conn = connect_db()
            cur = conn.cursor()

            value = generate_job_value()

            cur.execute(
                "INSERT INTO results(value) VALUES (%s);",
                (value,)
            )

            conn.commit()
            cur.close()
            conn.close()

            print(f"✅ Job processed: {value}")
            JOBS_PROCESSED.inc() # Incrémentation de la métrique Prometheus

            time.sleep(5)

        except Exception as e:
            print(f"❌ Error: {e}")
            time.sleep(5)

if __name__ == "__main__":
    main()
