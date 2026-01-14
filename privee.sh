#!/bin/bash

# Script de test pour la partie "Privée" (Box B1 et C1)
# Vérifie: DHCP, DNS (Connectivité), NAT, Sécurité

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== Démarrage des tests Partie Privée (Box B1 & C1) ==="

test_box() {
    local box_name=$1
    local client_name=$2
    local subnet=$3
    local external_router_name="R_FAI_1"
    
    # Définition de la gateway WAN cible pour le test de ping (C'est le routeur FAI direct)
    if [ "$box_name" == "Box_B1" ]; then
        external_target="120.0.32.1"
    else
        external_target="120.0.33.1"
    fi
    
    local dns_server="120.0.36.2" # Serveur DNS de l'infra

    echo -e "\n----------------------------------------"
    echo -e " Test Zone: $box_name (Client: $client_name)"
    echo -e "----------------------------------------"

    # 1. Test DHCP
    echo -n "[DHCP] Récupération IP... "
    # Extraction propre de l'IP (compatible Alpine/Busybox)
    client_ip=$(docker exec $client_name ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    
    if [[ $client_ip == "$subnet"* ]] && [[ ! -z "$client_ip" ]]; then
        echo -e "${GREEN}OK${NC} (Adresse obtenue: $client_ip)"
    else
        echo -e "${RED}KO${NC} (Pas d'IP ou mauvais sous-réseau: $client_ip / Attendu: $subnet.x)"
    fi

    # 2. Test DNS / Connectivité DNS
    # On ping le serveur DNS pour vérifier le routage + firewall sortant basique
    echo -n "[DNS ] Accès serveur DNS ($dns_server)... "
    if docker exec $client_name ping -c 1 -W 2 $dns_server > /dev/null 2>&1; then
         echo -e "${GREEN}OK${NC}"
    else
         echo -e "${RED}KO${NC} (Injoignable)"
    fi

    # 3. Test NAT
    # On ping le routeur FAI. Si ça passe, le NAT masquerade fonctionne (car FAI ne connait pas le LAN privé)
    echo -n "[NAT ] Accès Test WAN ($external_target)... "
    if docker exec $client_name ping -c 1 -W 2 $external_target > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}KO${NC} (Injoignable - Vérifier NAT/Forwarding)"
    fi

    # 4. Test Sécurité (Firewalling Entrant)
    # On essaie de pinger le Client LAN depuis le Routeur FAI.
    # Cela DOIT échouer si le firewall fait son travail (DROP par défaut et pas de DNAT).
    echo -n "[SEC ] Tentative intrusion WAN->LAN... "
    if [ -z "$client_ip" ]; then
        echo -e "${RED}SKIP${NC} (Pas d'IP client)"
    else
        # On attend un échec du ping
        if ! docker exec $external_router_name ping -c 1 -W 1 $client_ip > /dev/null 2>&1; then
            echo -e "${GREEN}OK${NC} (Bloqué comme prévu)"
        else
            echo -e "${RED}FAIL${NC} (Le ping est passé ! La box est ouverte au WAN)"
        fi
    fi
}

# Exécution des tests
test_box "Box_B1" "Client_B1" "192.168.101"
test_box "Box_C1" "Client_C1" "192.168.2"

echo -e "\n=== Fin des tests ==="