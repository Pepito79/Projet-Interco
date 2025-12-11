#!/bin/bash
echo "Configuring Box_B1..."

# interface eth0 -> net_32
docker exec --privileged Box_B1 ip addr flush dev eth0
docker exec --privileged Box_B1 ip addr add 120.0.32.2/24 dev eth0
docker exec --privileged Box_B1 ip link set up dev eth0

# interface eth1 -> net_b1
docker exec --privileged Box_B1 ip addr flush dev eth1
docker exec --privileged Box_B1 ip addr add 192.168.101.1/24 dev eth1
docker exec --privileged Box_B1 ip link set up dev eth1
