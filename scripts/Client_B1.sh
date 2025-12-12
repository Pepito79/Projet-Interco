#!/bin/bash
echo "Configuring Client_B1..."

# interface eth0 -> net_b1
docker exec --privileged Client_B1 ip link set up dev eth0

# Default Gateway -> Box_B1 (192.168.101.1)
docker exec --privileged Client_B1 ip route del default || true
docker exec --privileged Client_B1 ip route add default via 192.168.101.5

# Force DNS to internal server
docker exec --privileged Client_B1 sh -c "echo 'nameserver 120.0.36.2' > /etc/resolv.conf"
