#!/bin/bash
echo "🔀 Configuration des redirections (DNAT) sur R_Entreprise1..."

# IP Publique de R_Entreprise1 (côté FAI) : 120.0.34.2
# IP du Serveur Web (DMZ) : 120.0.37.2
# IP du Serveur FTP (DMZ) : 120.0.37.5

# 1. Redirection du trafic HTTP (Port 80) vers le Serveur Web
docker exec --privileged R_Entreprise1 iptables -t nat -A PREROUTING -d 120.0.34.2 -p tcp --dport 80 -j DNAT --to-destination 120.0.37.2:80

# 2. Redirection du trafic FTP (Port 21) vers le Serveur FTP
docker exec --privileged R_Entreprise1 iptables -t nat -A PREROUTING -d 120.0.34.2 -p tcp --dport 21 -j DNAT --to-destination 120.0.37.5:21

# 3. Redirection de la plage de ports passifs FTP (21000-21010)
# Très important pour que le transfert de fichiers lftp fonctionne à travers le NAT
docker exec --privileged R_Entreprise1 iptables -t nat -A PREROUTING -d 120.0.34.2 -p tcp --dport 21000:21010 -j DNAT --to-destination 120.0.37.5

# 4. Masquerading (SNAT) pour permettre au LAN de sortir avec l'IP du routeur
# (Optionnel si tout est en OSPF, mais conseillé pour simuler un vrai routeur Internet)
docker exec --privileged R_Entreprise1 iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "✅ Redirections configurées."