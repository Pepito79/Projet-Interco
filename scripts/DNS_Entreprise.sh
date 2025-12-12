#!/bin/bash
echo "Configuring DNS_Entreprise..."

# interface eth0 -> net_dmz
docker exec --privileged DNS_Entreprise ip link set up dev eth0

# route par défaut -> R_DMZ (10.10.20.254)
docker exec --privileged DNS_Entreprise ip route del default || true
docker exec --privileged DNS_Entreprise ip route add default via 10.10.20.254

# lancer dnsmasq
docker exec --privileged DNS_Entreprise apk add --no-cache dnsmasq
docker exec --privileged DNS_Entreprise dnsmasq -k -C /etc/dnsmasq.conf
