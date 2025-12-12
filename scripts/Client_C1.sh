#!/bin/bash
echo "Configuring Client_C1..."

# interface eth0 -> net_c1
docker exec --privileged Client_C1 ip link set up dev eth0

# Default Gateway -> Box_C1 (192.168.2.1)
docker exec --privileged Client_C1 ip route del default || true
docker exec --privileged Client_C1 ip route add default via 192.168.2.5

# Force DNS to internal server
docker exec --privileged Client_C1 sh -c "echo 'nameserver 120.0.36.2' > /etc/resolv.conf"
