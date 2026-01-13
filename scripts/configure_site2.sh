#!/bin/bash
echo "🌍 Configuring Site 2 Routing..."

# Route Ent1 LAN via VPN Gateway
docker exec --privileged R_Entreprise2 ip route add 10.10.10.0/24 via 10.20.10.10 2>/dev/null || true
docker exec --privileged R_Entreprise2 ip route add 10.10.20.0/24 via 10.20.10.10 2>/dev/null || true

# Setup NAT on R_Entreprise2 (Essential for VPN Client to reach Internet)
docker exec --privileged R_Entreprise2 apk add iptables
docker exec --privileged R_Entreprise2 iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE

# Masquerade on VPN Gateway? (Optional, if we want to hide LAN2 IPs)
# docker exec --privileged VPN_Gateway_Ent2 iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "✅ Site 2 configured."
