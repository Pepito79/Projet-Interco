# #!/bin/bash
# echo "🛡️ Configuration du Firewall : Focus DMZ Entreprise (10.10.20.x)..."

# # 1. Reset
# docker exec --privileged R_Entreprise1 iptables -F
# docker exec --privileged R_Entreprise1 iptables -X

# # 2. Politique par défaut (DROP)
# docker exec --privileged R_Entreprise1 iptables -P FORWARD DROP
# docker exec --privileged R_Entreprise1 iptables -P INPUT DROP

# # 3. ÉTAT : Autoriser les réponses (Stateful)
# docker exec --privileged R_Entreprise1 iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# # 4. LAN -> DMZ & INTERNET : Autoriser le LAN (10.10.10.0/24) à sortir
# docker exec --privileged R_Entreprise1 iptables -A FORWARD -s 10.10.10.0/24 -j ACCEPT

# # 5. INTERNET -> DMZ : Autoriser l'accès externe au serveur Web de l'ENTREPRISE
# # C'est ici qu'on utilise l'IP de TA DMZ
# docker exec --privileged R_Entreprise1 iptables -A FORWARD -p tcp -d 10.10.20.2 --dport 80 -j ACCEPT

# # 6. ICMP (Ping) : Le LAN peut pinger la DMZ et l'extérieur, mais l'inverse est faux
# docker exec --privileged R_Entreprise1 iptables -A FORWARD -p icmp -s 10.10.10.0/24 -j ACCEPT

# echo "✅ Firewall mis à jour pour la DMZ interne (10.10.20.2)."