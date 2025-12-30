#!/bin/bash

# 1. Nettoyage
docker exec R_Entreprise1 iptables -F
docker exec R_Entreprise1 iptables -t nat -F

# 2. Politiques restrictives (Tout est bloqué par défaut)
docker exec R_Entreprise1 iptables -P INPUT DROP
docker exec R_Entreprise1 iptables -P FORWARD DROP
docker exec R_Entreprise1 iptables -P OUTPUT ACCEPT

# -------------------------------------------------------------------------
# 3. SÉCURITÉ : On bloque l'entrée vers le LAN AVANT toute autorisation
# -------------------------------------------------------------------------
# On utilise -I (Insert) pour que ce soit la TOUTE PREMIÈRE règle lue.
# Elle dit : "Si ça vient de l'extérieur (eth0) vers le LAN, on jette direct"
docker exec R_Entreprise1 iptables -I FORWARD -i eth0 -d 10.10.10.0/24 -j DROP

# 4. Autoriser le trafic de retour (Stateful)
docker exec R_Entreprise1 iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
docker exec R_Entreprise1 iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# 5. Autoriser les protocoles de structure (OSPF, ICMP, Loopback)
docker exec R_Entreprise1 iptables -A INPUT -i lo -j ACCEPT
docker exec R_Entreprise1 iptables -A INPUT -p ospf -j ACCEPT
docker exec R_Entreprise1 iptables -A FORWARD -p ospf -j ACCEPT
docker exec R_Entreprise1 iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# 6. Autoriser le LAN à sortir (Pour que les employés aient Internet)
docker exec R_Entreprise1 iptables -A FORWARD -s 10.10.10.0/24 -j ACCEPT

# 7. Autoriser le Serveur WEB (DMZ)
docker exec R_Entreprise1 iptables -A FORWARD -d 10.10.20.2 -p tcp --dport 80 -j ACCEPT

# 8. NAT : Redirection de port (DNAT) et Masquerade
# On redirige l'IP publique vers le serveur Web interne
docker exec R_Entreprise1 iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 10.10.20.2:80
# On permet au LAN de sortir avec l'IP publique
docker exec R_Entreprise1 iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "✅ Pare-feu sécurisé : Le service RH est désormais isolé de l'extérieur."