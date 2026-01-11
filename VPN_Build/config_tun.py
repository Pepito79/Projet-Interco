import fcntl
import struct
import os

# Constantes pour configurer le TUN
TUNSETIFF = 0x400454ca
IFF_TUN   = 0x0001
IFF_NO_PI = 0x1000

def config_tun_dev():
    tun = os.open("/dev/net/tun", os.O_RDWR)
    ifr = struct.pack('16sH', b'tun0', IFF_TUN | IFF_NO_PI)
    fcntl.ioctl(tun, TUNSETIFF, ifr)
    return tun

if __name__ == "__main__":
    tun_fd = config_tun_dev()
    print("✅ Succès ! Interface tun0 créée.")
    
    # Instructions pour l'utilisateur
    print("👉 MAINTENANT, allez dans l'autre terminal et tapez :")
    print("   ip addr add 10.0.0.1/24 dev tun0")
    print("   ip link set tun0 up")
    print("   ping 10.0.0.1")
    
    print("🎧 En attente de paquets (Ctrl+C pour arrêter)...")

    while True:
        # On lit le paquet brut qui arrive dans l'interface
        paquet = os.read(tun_fd, 2048)
        print(f"📦 Paquet capturé ! Taille: {len(paquet)} octets")