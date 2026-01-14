#!/bin/bash
echo "⚙️ Configuration du routeur R_Entreprise2..."

# 1. Activer les interfaces de R_Entreprise2
docker exec --privileged R_Entreprise2 ip link set up dev eth0  # Vers le FAI (net_44)
docker exec --privileged R_Entreprise2 ip link set up dev eth1  # Vers le LAN Site 2 (net_ent2_lan)
docker exec R_Entreprise2 apk add tcpdump
# 2. On n'installe PAS dnsmasq ici, car tu as un conteneur "DHCP_Ent2" dédié
# Par contre, on vérifie que le service DHCP est bien démarré
echo "📡 Vérification du conteneur DHCP dédié..."
docker start DHCP_Ent2 2>/dev/null

echo "✅ R_Entreprise2 configuré."