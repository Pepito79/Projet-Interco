#!/bin/bash
echo "Configuring Box_B1..."

# interface eth0 -> net_32 vers le FAI
docker exec --privileged Box_B1 ip link set up dev eth0

# interface eth1 -> net_b1 vers client B1
docker exec --privileged Box_B1 ip link set up dev eth1
