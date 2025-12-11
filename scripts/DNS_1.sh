#!/bin/bash
echo "Configuring DNS_1..."

# interface eth0 -> net_36
docker exec --privileged DNS_1 ip addr flush dev eth0
docker exec --privileged DNS_1 ip addr add 120.0.36.10/24 dev eth0
docker exec --privileged DNS_1 ip link set up dev eth0

# Default Gateway -> R12 (120.0.36.2)
docker exec --privileged DNS_1 ip route del default || true
docker exec --privileged DNS_1 ip route add default via 120.0.36.2
