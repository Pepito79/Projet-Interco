FROM python:3.9-slim
ENV PYTHONUNBUFFERED=1

# On ajoute iptables (pour le serveur) et curl (pour tester) + cryptography
RUN apt-get update && apt-get install -y iproute2 iputils-ping netcat-openbsd iptables curl && pip install cryptography

RUN apt-get update && apt-get install -y iproute2 iputils-ping netcat-openbsd iptables curl ethtool && pip install cryptography

RUN apt-get update && apt-get install -y iproute2 iputils-ping netcat-openbsd iptables curl ethtool procps && pip install cryptography

RUN apt-get update && apt-get install -y iproute2 iputils-ping netcat-openbsd iptables curl ethtool procps tcpdump && pip install cryptography

RUN apt-get update && apt-get install -y iproute2 iputils-ping netcat-openbsd iptables curl ethtool procps tcpdump tinyproxy && pip install cryptography

# Créer le répertoire de l'application
WORKDIR /app

# Copier les scripts Python
COPY vpn_server.py .
COPY vpn_client.py .

# Copier les scripts de démarrage (Nouveau !)
COPY start_server.sh .
COPY start_client.sh .

# Rendre les scripts exécutables
RUN chmod +x start_server.sh start_client.sh

# Par défaut, on lance le serveur (sera écrasé par le docker-compose)
CMD ["./start_server.sh"]