#!/bin/bash

# 1. Vider (flush) les règles existantes
docker exec R_Entreprise1 iptables -F
docker exec R_Entreprise1 iptables -t nat -F
docker exec R_Entreprise1 iptables -t mangle -F

# 2. Définir des politiques par défaut restrictives
# On bloque tout ce qui entre et ce qui transite
docker exec R_Entreprise1 iptables -P INPUT DROP
docker exec R_Entreprise1 iptables -P FORWARD DROP
docker exec R_Entreprise1 iptables -P OUTPUT ACCEPT

# 3. Autoriser les connexions établies et relatives (Stateful inspection)
# Permet au trafic de retour de passer
docker exec R_Entreprise1 iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
docker exec R_Entreprise1 iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 4. Autoriser la boucle locale (localhost)
docker exec R_Entreprise1 iptables -A INPUT -i lo -j ACCEPT

# 5. Autoriser les paquets OSPF (Indispensable pour tes routeurs FRR)
docker exec R_Entreprise1 iptables -A INPUT -p ospf -j ACCEPT
docker exec R_Entreprise1 iptables -A FORWARD -p ospf -j ACCEPT

# 6. Autoriser le ping (ICMP) vers le routeur
docker exec R_Entreprise1 iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Autoriser le LAN de l'entreprise (net_lan) à sortir vers Internet
# Plage : 10.10.10.0/24
docker exec R_Entreprise1 iptables -A FORWARD -s 10.10.10.0/24 -j ACCEPT

# Autoriser l'accès au SERVEUR WEB de la DMZ (port 80) depuis n'importe où
docker exec R_Entreprise1 iptables -A FORWARD -d 10.10.20.2 -p tcp --dport 80 -j ACCEPT

# Autoriser l'accès au DNS de la DMZ (port 53) pour le LAN
docker exec R_Entreprise1 iptables -A FORWARD -s 10.10.10.0/24 -d 10.10.20.3 -p udp --dport 53 -j ACCEPT
docker exec R_Entreprise1 iptables -A FORWARD -s 10.10.10.0/24 -d 10.10.20.3 -p tcp --dport 53 -j ACCEPT

# 8. NAT (Masquerade) pour que le LAN puisse naviguer sur le réseau FAI
docker exec R_Entreprise1 iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#9 . DNAT si qql tape l'add du routeur entreprise on le redirige vers le serveur web
docker exec R_Entreprise1 iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.10.20.2:80

echo "✅ Le pare-feu de R_Entreprise1 a été configuré et sécurisé."