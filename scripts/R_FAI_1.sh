#!/bin/bash
echo "Configuring R_FAI_1..."

# interface eth0 -> net_32
docker exec --privileged R_FAI_1 ip addr flush dev eth0
docker exec --privileged R_FAI_1 ip addr add 120.0.32.1/24 dev eth0
docker exec --privileged R_FAI_1 ip link set up dev eth0

# interface eth1 -> net_33
docker exec --privileged R_FAI_1 ip addr flush dev eth1
docker exec --privileged R_FAI_1 ip addr add 120.0.33.1/24 dev eth1
docker exec --privileged R_FAI_1 ip link set up dev eth1

# interface eth2 -> net_34
docker exec --privileged R_FAI_1 ip addr flush dev eth2
docker exec --privileged R_FAI_1 ip addr add 120.0.34.4/24 dev eth2
docker exec --privileged R_FAI_1 ip link set up dev eth2

# interface eth3 -> net_35
docker exec --privileged R_FAI_1 ip addr flush dev eth3
docker exec --privileged R_FAI_1 ip addr add 120.0.35.1/24 dev eth3
docker exec --privileged R_FAI_1 ip link set up dev eth3

# interface eth4 -> net_39
docker exec --privileged R_FAI_1 ip addr flush dev eth4
docker exec --privileged R_FAI_1 ip addr add 120.0.39.3/24 dev eth4
docker exec --privileged R_FAI_1 ip link set up dev eth4
