#!/bin/bash
echo "Configuring R12..."

# interface eth0 -> net_39
docker exec --privileged R12 ip addr flush dev eth0
docker exec --privileged R12 ip addr add 120.0.39.2/24 dev eth0
docker exec --privileged R12 ip link set up dev eth0

# interface eth1 -> net_38
docker exec --privileged R12 ip addr flush dev eth1
docker exec --privileged R12 ip addr add 120.0.38.2/24 dev eth1
docker exec --privileged R12 ip link set up dev eth1

# interface eth2 -> net_36
docker exec --privileged R12 ip addr flush dev eth2
docker exec --privileged R12 ip addr add 120.0.36.2/24 dev eth2
docker exec --privileged R12 ip link set up dev eth2
