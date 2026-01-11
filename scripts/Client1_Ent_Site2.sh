# #!/bin/bash
# echo "Configuring  with DHCP..."

# # Activer l'interface eth0
# docker exec --privileged Client1_Ent_Site2 ip link set up dev eth0
# sleep 1

# # Installer le client DHCP si ce n'est pas déjà fait
# docker exec --privileged Client1_Ent_Site2 apk add --no-cache dhcpcd

# # Demander une IP automatiquement via DHCP
# docker exec --privileged Client1_Ent_Site2 dhcpcd -n eth0

# # Vérifier l'adresse IP attribuée
# docker exec --privileged Client1_Ent_Site2 ip addr show eth0
