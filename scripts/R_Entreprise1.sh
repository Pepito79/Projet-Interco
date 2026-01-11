#!/bin/sh
echo "--- CONFIGURATION AUTO R_ENTREPRISE1 ---"

# 1. Installer iptables (s'il n'est pas déjà dans l'image)
apk add --no-cache iptables

# 2. Définition des variables (VPN Python)
WAN_IF="eth0"           # Interface vers Internet (120.0.34.2)
VPN_IP="10.10.20.4"     # IP du Serveur VPN
VPN_PORT="9999"         # Port TCP de ton code Python
PROTO="tcp"

echo "Application des règles NAT pour le VPN ($PROTO/$VPN_PORT)..."

# 3. Règle DNAT (Redirection entrée)
# "Tout ce qui arrive sur le port 9999 est redirigé vers 10.10.20.4"
iptables -t nat -A PREROUTING -i $WAN_IF -p $PROTO --dport $VPN_PORT -j DNAT --to-destination $VPN_IP:$VPN_PORT

# 4. Règle FORWARD (Autorisation traversée VPN) - PRIORITAIRE
# "J'autorise UNIQUEMENT le port 9999 à passer vers le serveur"
iptables -A FORWARD -p $PROTO -d $VPN_IP --dport $VPN_PORT -j ACCEPT

# ==============================================================================
# 5. [AJOUT SÉCURITÉ] Règle DROP (Fermeture de la faille OSPF)
# "Tout le reste venant d'Internet et voulant aller vers le LAN (10.10.x.x) -> POUBELLE"
# C'est cette ligne qui empêche le ping 'triche' sans VPN.
iptables -A FORWARD -i $WAN_IF -d 10.10.0.0/16 -j DROP
# ==============================================================================

# 6. Règle MASQUERADE (Post-out)
# "Je m'assure que le retour se fait bien"
iptables -t nat -A POSTROUTING -d $VPN_IP -p $PROTO --dport $VPN_PORT -j MASQUERADE

# 7. Route de secours (Gateway vers Internet)
ip route add default via 120.0.34.1 metric 200 2>/dev/null || true

echo "✅ Règles appliquées. Lancement du routage FRR..."

# 8. LANCEMENT FINAL DU PROCESSUS PRINCIPAL
/usr/lib/frr/docker-start
