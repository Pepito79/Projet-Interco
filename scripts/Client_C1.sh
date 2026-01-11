#!/bin/sh
echo "--- Config Client C1 (VPN Python) ---"

# === 1. INSTALLATION DES OUTILS (C'est ce qui manquait !) ===
echo "Installation de Python et des outils réseau..."
apk add --no-cache python3 py3-pip iproute2

# === 2. Config Réseau de base ===
ip link set dev eth0 up
# Reset de la route par défaut (au cas où)
ip route del default 2>/dev/null || true
ip route add default via 192.168.2.1

# === 3. Préparation du VPN ===
export VPN_SERVER_IP="120.0.34.2"
GW_PHYSIQUE="192.168.2.1"

echo "🚀 Démarrage du VPN vers $VPN_SERVER_IP..."

# === 4. ROUTAGE DE SÉCURITÉ (Anti-Boucle) ===
# Le trafic chiffré vers l'IP publique DOIT passer par la vraie passerelle
ip route add $VPN_SERVER_IP via $GW_PHYSIQUE dev eth0

# === 5. Lancement du code Python ===
cd /app
python3 vpn_client.py &

# === 6. Attente de l'interface tun0 ===
echo "⏳ Attente de la création de tun0 par le script Python..."
while ! ip link show tun0 > /dev/null 2>&1; do 
    sleep 0.5
done
echo "✅ Interface tun0 détectée !"

# === 7. Config IP et Split Tunneling ===
ip addr flush dev tun0 2>/dev/null
ip addr add 10.0.0.2/24 dev tun0
ip link set tun0 up
ip link set tun0 mtu 1200

# On dirige vers le tunnel UNIQUEMENT le trafic pour l'entreprise
echo "🛣️ Ajout de la route vers le LAN Entreprise..."
ip route add 10.10.0.0/16 via 10.0.0.1 dev tun0

echo "✅ CONFIGURATION TERMINÉE."
tail -f /dev/null