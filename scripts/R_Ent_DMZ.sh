frr version 8.4
frr defaults traditional
hostname R_Ent_DMZ
no ipv6 forwarding
!
interface eth0
 description Vers R_Entreprise1
 ip address 10.10.2.2/29
!
interface eth1
 description Vers DMZ (Serveur VPN .4)
 ip address 10.10.20.1/24
!
router ospf
 ospf router-id 2.2.2.2
 ! Annonce du réseau DMZ (où se trouve le 10.10.20.4)
 network 10.10.20.0/24 area 0.0.0.1
 ! Annonce du lien vers l'entreprise
 network 10.10.2.0/29 area 0.0.0.1
!
line vty
!