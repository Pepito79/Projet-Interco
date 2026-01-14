# #!/bin/bash
# echo "Configuring Client_Ent1..."

# # Activer l'interface
# docker exec --privileged Client_Ent1 ip link set up dev eth0
# sleep 1

# # DHCP
# docker exec --privileged Client_Ent1 apk add --no-cache dhcpcd
# docker exec --privileged Client_Ent1 dhcpcd -n eth0

# # FORCE GATEWAY : On s'assure qu'il utilise R_Ent_LAN (10.10.10.1)
# docker exec Client_Ent1 ip route del default || true
# docker exec Client_Ent1 ip route add default via 10.10.10.254

# echo "Client_Ent1 configured."


# #!/bin/bash
# echo "Configuring Client_Ent1 (Static Mode)..."

# # 1. On force l'interface UP
# docker exec --privileged Client_Ent1 ip link set eth0 up

# # 2. On attribue l'IP manuellement (pour éviter les soucis de DHCP)
# # On nettoie d'abord les IPs existantes
# # docker exec --privileged Client_Ent1 ip addr flush dev eth0
# # docker exec --privileged Client_Ent1 ip addr add 10.10.10.2/24 dev eth0

# # 3. On définit la passerelle (le routeur R_Ent_LAN)
# # On attend un peu que l'interface soit prête
# sleep 1
# docker exec --privileged Client_Ent1 ip route del default || true
# docker exec --privileged Client_Ent1 ip route add default via 10.10.10.1

# echo "Client_Ent1 configured with IP 10.10.10.2 and Gateway 10.10.10.1."

#!/bin/bash
echo "Vérification du Client_Ent1 (Mode DHCP)..."

# 1. On s'assure que l'interface est UP
docker exec --privileged Client_Ent1 ip link set eth0 up

# 2. On force le renouvellement DHCP (au cas où il aurait échoué au boot)
echo "Demande de bail DHCP..."
docker exec --privileged Client_Ent1 udhcpc -n -i eth0

# 3. Vérification de l'IP reçue
IP_RECU=$(docker exec Client_Ent1 ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [ -z "$IP_RECU" ]; then
    echo "Erreur : Le client n'a pas reçu d'IP du serveur DHCP."
else
    echo "Succès : Client_Ent1 a reçu l'IP : $IP_RECU"
fi

# 4. Vérification de la passerelle
echo "Table de routage :"
docker exec Client_Ent1 ip route show