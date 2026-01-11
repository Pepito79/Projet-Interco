#!/bin/sh
echo "--- Config R_Entreprise2 (RIP + NAT) ---"
apk add iptables iproute2
sysctl -w net.ipv4.ip_forward=1

# Adresses IP
ip addr flush dev eth0
ip addr flush dev eth1
ip addr add 120.0.41.2/24 dev eth0 # Vers FAI 2
ip addr add 20.20.20.1/24 dev eth1 # Vers LAN Interne

# --- NAT (Masquerade) ---
# Indispensable pour que le LAN privé sorte sur Internet
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# --- CONFIGURATION FRR (RIP) ---
# 1. Activer RIP
sed -i 's/ripd=no/ripd=yes/g' /etc/frr/daemons

# 2. Lancer FRR
/usr/lib/frr/docker-start &
sleep 2

# 3. Configurer RIP
vtysh -c 'conf t' \
      -c 'router rip' \
      -c ' version 2' \
      -c ' network 120.0.41.0/24' \
      -c ' network 20.20.20.0/24' \
      -c ' exit' \
      -c 'exit' \
      -c 'write'

# Explication :
# Il annonce ses deux réseaux (WAN et LAN) en RIP.
# Il va apprendre la route par défaut grâce au "redistribute static" du FAI 2.

tail -f /dev/null