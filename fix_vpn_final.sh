#!/bin/sh
echo "🔧 Applying Final VPN Fixes..."

# 1. R_Entreprise2: Add Static Routes (VPN)
echo "Adding Static Routes to R_Entreprise2..."
docker exec R_Entreprise2 ip route add 10.10.10.0/24 via 10.20.10.10 2>/dev/null || true
docker exec R_Entreprise2 ip route add 10.10.20.0/24 via 10.20.10.10 2>/dev/null || true

# 2. R_Entreprise2: Add NAT (WAN)
echo "Adding NAT to R_Entreprise2..."
docker exec --privileged R_Entreprise2 iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE 2>/dev/null || true

# 3. R_Entreprise1: Restore Firewall Rules
echo "Restoring R_Entreprise1 Firewall..."
./scripts/firewall.sh >/dev/null 2>&1
# Ensure SNAT on eth1 is applied (if not in firewall.sh yet, but it is)
docker exec --privileged R_Entreprise1 iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE 2>/dev/null || true

# 4. R_Ent_DMZ: Ensure Forwarding
echo "Checking R_Ent_DMZ..."
docker exec --privileged R_Ent_DMZ iptables -P FORWARD ACCEPT

# 5. VPN Gateway: Restart to Auth
echo "Restarting VPN Gateway..."
docker restart VPN_Gateway_Ent2
sleep 5

echo "✅ Fixes Applied. Ready for Verification."
