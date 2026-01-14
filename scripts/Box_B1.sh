# #!/bin/bash
# echo "Configuring Box_B1..."

# # interface eth0 -> net_32 vers le FAI
# docker exec --privileged Box_B1 ip link set up dev eth0

# # interface eth1 -> net_b1 vers client B1
# docker exec --privileged Box_B1 ip link set up dev eth1

#!/bin/bash
echo "🚀 Configuring Box_B1 (DHCP + NAT + Routing)..."

# 1. Activation des interfaces (Déjà fait, mais on sécurise)
docker exec --privileged Box_B1 ip link set up dev eth0
docker exec --privileged Box_B1 ip link set up dev eth1

# 2. Activation du Forwarding (Crucial pour un routeur)
docker exec --privileged Box_B1 sysctl -w net.ipv4.ip_forward=1

# 3. Installation et configuration du DHCP (dnsmasq)
echo "📥 Installing DHCP server on Box_B1..."
docker exec --privileged Box_B1 sh -c "
  apk add --no-cache dnsmasq
  
  # Configuration DHCP : Plage .50 à .100, passerelle .5 (elle-même), DNS externe
  echo 'interface=eth1' > /etc/dnsmasq.conf
  echo 'dhcp-range=192.168.101.50,192.168.101.100,24h' >> /etc/dnsmasq.conf
  echo 'dhcp-option=option:router,192.168.101.5' >> /etc/dnsmasq.conf
  echo 'dhcp-option=option:dns-server,120.0.36.2' >> /etc/dnsmasq.conf
  
  # Lancement du service
  pkill dnsmasq
  dnsmasq
"

# 4. Configuration du Firewall et du NAT (Masquerade)
echo "🛡️ Setting up Firewall & NAT..."
docker exec --privileged Box_B1 sh -c "
  # Nettoyage
  iptables -F
  iptables -t nat -F
  
  # NAT : On masque l'IP du LAN quand on sort vers l'Internet (eth0)
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  
  # Forwarding : Autoriser le passage des paquets du LAN vers le WAN
  iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
  iptables -A FORWARD -i eth0 -o eth1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
"

echo "✅ Box_B1 est prête !"