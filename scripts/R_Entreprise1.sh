#!/bin/bash
echo "Configuring R_Entreprise1..."

# Activation des interfaces (Base)
docker exec --privileged R_Entreprise1 ip link set up dev eth0
docker exec --privileged R_Entreprise1 ip link set up dev eth1

# --- AUTOMATISATION DES RÈGLES DE SURVIE ---

# 1. Route de retour vers Internet (Indispensable)
docker exec --privileged R_Entreprise1 ip route add default via 120.0.34.1

# 2. Port Forwarding (DNAT) : TCP 9999 -> Serveur VPN
docker exec --privileged R_Entreprise1 iptables -t nat -A PREROUTING -d 120.0.34.2 -p tcp --dport 9999 -j DNAT --to-destination 10.10.10.3

# 3. Masquerade (SNAT) : Force le retour du paquet par le routeur
docker exec --privileged R_Entreprise1 iptables -t nat -A POSTROUTING -d 10.10.10.3 -p tcp --dport 9999 -j MASQUERADE

echo "✅ TOUT EST PRÊT : Route + NAT + Masquerade appliqués."
