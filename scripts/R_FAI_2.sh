#!/bin/sh
echo "--- Config R_FAI_2 (RIP) ---"
apk add iptables iproute2
sysctl -w net.ipv4.ip_forward=1

# Adresses IP
ip addr flush dev eth0
ip addr flush dev eth1
ip addr add 120.0.40.2/24 dev eth0 # Vers Bordure
ip addr add 120.0.41.1/24 dev eth1 # Vers Entreprise 2

# Route Statique de sortie (Vers le monde)
ip route add default via 120.0.40.1

# --- CONFIGURATION FRR (RIP) ---
# 1. Activer le démon RIP
sed -i 's/ripd=no/ripd=yes/g' /etc/frr/daemons

# 2. Lancer FRR
/usr/lib/frr/docker-start &
sleep 2

# 3. Configurer RIP via vtysh
vtysh -c 'conf t' \
      -c 'router rip' \
      -c ' version 2' \
      -c ' network 120.0.41.0/24' \
      -c ' redistribute static' \
      -c ' exit' \
      -c 'exit' \
      -c 'write'

# Explication : 
# - network 120.0.41.0/24 : Il parle RIP sur le lien vers l'entreprise.
# - redistribute static : Il partage sa route par défaut (vers la bordure) à l'entreprise via RIP.

tail -f /dev/null