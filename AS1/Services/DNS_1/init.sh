#!/bin/sh

# 1. Configuration IP (120.0.36.2)
# R12 est la passerelle en .1
ip addr flush dev eth0
ip link set dev eth0 up
ip addr add 120.0.36.2/24 dev eth0

# 2. Route par défaut vers R12
ip route add default via 120.0.36.1

# 3. Maintien du conteneur en vie
sleep infinity