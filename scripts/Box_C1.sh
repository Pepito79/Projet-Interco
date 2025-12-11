#!/bin/bash
echo "Configuring Box_C1..."

# interface eth0 -> net_33 vers le FAI
docker exec --privileged Box_C1 ip link set up dev eth0

# interface eth1 -> net_c1 vers client C1
docker exec --privileged Box_C1 ip link set up dev eth1
