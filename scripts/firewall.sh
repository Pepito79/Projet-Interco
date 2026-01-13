#!/bin/bash
echo "🛡️ Configuration du Firewall : Focus DMZ Entreprise (10.10.20.x)..."

# 1. Reset
docker exec --privileged R_Entreprise1 iptables -F
docker exec --privileged R_Entreprise1 iptables -X
docker exec --privileged R_Entreprise1 iptables -t nat -F

# 2. Politique par défaut (DROP)
docker exec --privileged R_Entreprise1 iptables -P FORWARD DROP
docker exec --privileged R_Entreprise1 iptables -P INPUT DROP

# 2b. Autoriser OSPF (Protocol 89)
docker exec --privileged R_Entreprise1 iptables -A INPUT -p ospf -j ACCEPT
docker exec --privileged R_Entreprise1 iptables -A OUTPUT -p ospf -j ACCEPT

# 3. ÉTAT : Autoriser les réponses (Stateful)
docker exec --privileged R_Entreprise1 iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# 3b. DNAT VPN : Rediriger le trafic entrant sur 120.0.34.2:9999 vers 10.10.20.10:9999
docker exec --privileged R_Entreprise1 iptables -t nat -A PREROUTING -d 120.0.34.2 -p udp --dport 9999 -j DNAT --to-destination 10.10.20.10:9999

# 3c. SNAT VPN : Removed (Let Server see real Gateway IP)
# docker exec --privileged R_Entreprise1 iptables -t nat -A POSTROUTING -d 10.10.20.10 -p udp --dport 9999 -j MASQUERADE

# 3d. SNAT Global : Masquerade traffic leaving WAN (eth0) AND DMZ Link (eth1)
docker exec --privileged R_Entreprise1 iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
docker exec --privileged R_Entreprise1 iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
docker exec --privileged R_Entreprise1 iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE

# 4. LAN -> DMZ & INTERNET : Autoriser le LAN (10.10.10.0/24) à sortir
docker exec --privileged R_Entreprise1 iptables -A FORWARD -s 10.10.10.0/24 -j ACCEPT

# 5. INTERNET -> DMZ : Autoriser l'accès externe au serveur Web de l'ENTREPRISE
# C'est ici qu'on utilise l'IP de TA DMZ
docker exec --privileged R_Entreprise1 iptables -A FORWARD -p tcp -d 10.10.20.2 --dport 80 -j ACCEPT

# 6. VPN -> DMZ : Autoriser l'accès VPN (Port 9999 UDP) vers Serveur_VPN_Ent1
docker exec --privileged R_Entreprise1 iptables -A FORWARD -p udp -d 10.10.20.10 --dport 9999 -j ACCEPT

# 6b. VPN (DMZ) -> LAN : Autoriser le trafic déchiffré du VPN vers le LAN
docker exec --privileged R_Entreprise1 iptables -A FORWARD -s 10.10.20.10 -d 10.10.10.0/24 -j ACCEPT

# 6c. VPN Server Output : Allow VPN Server to reply to Internet/Gateway
docker exec --privileged R_Entreprise1 iptables -A FORWARD -s 10.10.20.10 -j ACCEPT

# 7. ICMP (Ping) : Le LAN peut pinger la DMZ et l'extérieur, mais l'inverse est faux
docker exec --privileged R_Entreprise1 iptables -A FORWARD -p icmp -s 10.10.10.0/24 -j ACCEPT

# 8. Access VPN Site-to-Site (20.20.20.0/24)
docker exec --privileged R_Ent_DMZ ip route add 20.20.20.0/24 via 10.10.20.10 2>/dev/null || true
docker exec --privileged R_Entreprise1 iptables -A FORWARD -d 20.20.20.0/24 -j ACCEPT
docker exec --privileged R_Entreprise1 iptables -A FORWARD -s 20.20.20.0/24 -j ACCEPT

echo "✅ Firewall mis à jour pour la DMZ interne (10.10.20.2) et le VPN."