#!/bin/bash
echo "Configuring R12..."

# interface eth0 -> net_36
docker exec --privileged R12 ip link set up dev eth0

# interface eth1 -> net_38
docker exec --privileged R12 ip link set up dev eth1

# interface eth2 -> net_39
docker exec --privileged R12 ip link set up dev eth2
