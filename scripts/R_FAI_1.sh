#!/bin/bash
echo "Configuring R_FAI_1..."

# interface eth0 -> net_32
docker exec --privileged R_FAI_1 sysctl -w net.ipv4.ip_forward=1
docker exec --privileged R_FAI_1 ip link set up dev eth0

# interface eth1 -> net_33
docker exec --privileged R_FAI_1 ip link set up dev eth1

# interface eth2 -> net_34
docker exec --privileged R_FAI_1 ip link set up dev eth2

# interface eth3 -> net_35
docker exec --privileged R_FAI_1 ip link set up dev eth3

# interface eth4 -> net_39
docker exec --privileged R_FAI_1 ip link set up dev eth4

#interface eth5 -> net-44
docker exec --privileged R_FAI_1 ip link set up dev eth5