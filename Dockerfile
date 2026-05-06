# ---- Stage 1: Builder ----
FROM python:3.11-alpine AS builder

WORKDIR /app

# Création d'un environnement virtuel pour isoler les dépendances
RUN python -m venv /opt/venv
# Activation de l'environnement virtuel
ENV PATH="/opt/venv/bin:$PATH"

# Copie uniquement du fichier de dépendances (optimisation du cache Docker)
COPY app/requirements.txt .
# Installation des dépendances
RUN pip install --no-cache-dir -r requirements.txt

# ---- Stage 2: Final image ----
FROM python:3.11-alpine

WORKDIR /app

# Création d'un utilisateur non-root pour des raisons de sécurité (Bonne pratique)
RUN addgroup -S workergroup && adduser -S workeruser -G workergroup

# Copie de l'environnement virtuel contenant les dépendances depuis le stage "builder"
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copie du code source de l'application
COPY app/ .

# Attribution des droits du répertoire de travail au nouvel utilisateur
RUN chown -R workeruser:workergroup /app

# Utilisation de l'utilisateur non-root
USER workeruser

# Point d'entrée de l'application
CMD ["python", "main.py"]
