#!/bin/bash
echo "Configuring R11..."

# interface eth0 -> net_35
docker exec --privileged R11 ip link set up dev eth0

# interface eth1 -> net_37
docker exec --privileged R11 ip link set up dev eth1

# interface eth2 -> net_38
docker exec --privileged R11 ip link set up dev eth2
