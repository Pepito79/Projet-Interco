#!/bin/sh
echo "--- Config Client_Entreprise_2 ---"
ip route del default 2>/dev/null
ip route add default via 20.20.20.1

tail -f /dev/null