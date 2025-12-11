#!/bin/bash
echo "Configuring R11..."

# interface eth0 -> net_35
docker exec --privileged R11 ip addr flush dev eth0
docker exec --privileged R11 ip addr add 120.0.35.12/24 dev eth0
docker exec --privileged R11 ip link set up dev eth0

# interface eth1 -> net_38
docker exec --privileged R11 ip addr flush dev eth1
docker exec --privileged R11 ip addr add 120.0.38.1/24 dev eth1
docker exec --privileged R11 ip link set up dev eth1

# interface eth2 -> net_37
docker exec --privileged R11 ip addr flush dev eth2
docker exec --privileged R11 ip addr add 120.0.37.1/24 dev eth2
docker exec --privileged R11 ip link set up dev eth2
