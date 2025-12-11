#!/bin/bash
echo "Configuring Box_C1..."

# interface eth0 -> net_33
docker exec --privileged Box_C1 ip addr flush dev eth0
docker exec --privileged Box_C1 ip addr add 120.0.33.2/24 dev eth0
docker exec --privileged Box_C1 ip link set up dev eth0

# interface eth1 -> net_c1
docker exec --privileged Box_C1 ip addr flush dev eth1
docker exec --privileged Box_C1 ip addr add 192.168.2.1/24 dev eth1
docker exec --privileged Box_C1 ip link set up dev eth1
