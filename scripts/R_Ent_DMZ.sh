#!/bin/bash
echo "Configuring R_DMZ..."
# 0. Enable Forwarding
docker exec --privileged R_Ent_DMZ sysctl -w net.ipv4.ip_forward=1

# interface eth0 -> net_ent_dmz (vers R_Entreprise1)
docker exec --privileged R_Ent_DMZ ip link set up dev eth0

# 2. Add Route to Site 2 (via VPN)
docker exec --privileged R_Ent_DMZ ip route add 20.20.20.0/24 via 10.10.20.10 2>/dev/null || true

# 3. [FIX] SNAT for VPN Traffic: Force return traffic via R_Ent_DMZ (10.10.20.1) instead of Docker GW
# This ensures Server sees a routable source IP
docker exec --privileged R_Ent_DMZ apk add iptables
# Fix for VPN return routing: Masquerade traffic to Server
docker exec --privileged R_Ent_DMZ iptables -t nat -A POSTROUTING -d 10.10.20.10/32 -j MASQUERADE

# interface eth1 -> net_dmz (vers DMZ interne)
docker exec --privileged R_Ent_DMZ ip link set up dev eth1
