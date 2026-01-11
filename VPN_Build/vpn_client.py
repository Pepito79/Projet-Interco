import socket
import struct
import os
import select
import time
import sys

# Config
SERVER_IP = os.getenv("VPN_SERVER_IP", "120.0.34.2") # IP Publique par defaut
SERVER_PORT = 9999
TUNSETIFF = 0x400454ca
IFF_TUN   = 0x0001
IFF_NO_PI = 0x1000
KEY = 0x99 

def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)

def checksum(data):
    if len(data) % 2 != 0:
        data += b'\x00'
    res = sum(struct.unpack("!%dH" % (len(data) // 2), data))
    res = (res >> 16) + (res & 0xffff)
    res += res >> 16
    return (~res) & 0xffff

def fix_checksum(packet):
    try:
        if packet[0] >> 4 == 4:
            ip_header_len = (packet[0] & 0x0F) * 4
            ip_header = bytearray(packet[:ip_header_len])
            ip_header[10:12] = b'\x00\x00'
            chk = checksum(ip_header)
            ip_header[10:12] = struct.pack("!H", chk)
            packet = bytes(ip_header) + packet[ip_header_len:]
            if packet[9] == 6:
                tcp_packet = packet[ip_header_len:]
                src_ip = packet[12:16]
                dst_ip = packet[16:20]
                pseudo_header = src_ip + dst_ip + b'\x00\x06' + struct.pack("!H", len(tcp_packet))
                tcp_header_list = bytearray(tcp_packet)
                tcp_header_list[16:18] = b'\x00\x00'
                chk = checksum(pseudo_header + tcp_header_list)
                tcp_header_list[16:18] = struct.pack("!H", chk)
                packet = packet[:ip_header_len] + bytes(tcp_header_list)
    except:
        pass
    return packet

def xor_cipher(data):
    return bytes([b ^ KEY for b in data])

def config_tun_dev():
    try:
        tun = os.open("/dev/net/tun", os.O_RDWR)
        ifr = struct.pack('16sH', b'tun0', IFF_TUN | IFF_NO_PI)
        import fcntl
        fcntl.ioctl(tun, TUNSETIFF, ifr)
        return tun
    except Exception as e:
        log(f"ERREUR TUN: {e}")
        sys.exit(1)

def send_packet(sock, data):
    try:
        packet = struct.pack('>H', len(data)) + data
        sock.sendall(packet)
    except Exception as e:
        log(f"Erreur envoi socket: {e}")

def recv_packet(sock):
    try:
        header = b''
        while len(header) < 2:
            chunk = sock.recv(2 - len(header))
            if not chunk: return None
            header += chunk
        size = struct.unpack('>H', header)[0]
        data = b''
        while len(data) < size:
            chunk = sock.recv(size - len(data))
            if not chunk: return None
            data += chunk
        return data
    except:
        return None

# --- MAIN ---

# 1. Préparation de l'interface (mais sans IP pour l'instant)
tun_fd = config_tun_dev()
log("✅ CLIENT : Interface tun0 initialisée (en attente d'IP).")

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# 2. Connexion TCP
try:
    log(f"🔄 Connexion vers {SERVER_IP}...")
    sock.connect((SERVER_IP, SERVER_PORT))
except Exception as e:
    log(f"❌ Impossible de joindre le serveur : {e}")
    sys.exit(1)

# 3. AUTHENTIFICATION INTERACTIVE
try:
    print("\n" + "="*40)
    print("🔐  AUTHENTIFICATION VPN ENTREPRISE")
    print("="*40)
    # On force la lecture sur stdin (utile si lancé via docker exec -it)
   #sys.stdin = open(0) 
    username = input("👤 Utilisateur : ").strip()
    password = input("🔑 Mot de passe : ").strip()
    
    # Envoi au serveur
    creds = f"{username}:{password}"
    sock.send(creds.encode('utf-8'))
    
    # Attente réponse
    response = sock.recv(1024).decode('utf-8')
    
    if response.startswith("OK:"):
        _, assigned_ip = response.split(":")
        log(f"\n✅ Authentification RÉUSSIE !")
        log(f"🆔 Votre IP VPN attribuée est : {assigned_ip}")
    else:
        log(f"\n❌ ECHEC : Identifiants incorrects.")
        sock.close()
        sys.exit(1)

except Exception as e:
    log(f"Erreur Auth: {e}")
    sys.exit(1)

# 4. CONFIGURATION RÉSEAU (Maintenant qu'on a l'IP)
try:
    os.system("ip addr flush dev tun0") # Nettoyage
    os.system(f"ip addr add {assigned_ip}/24 dev tun0")
    os.system("ip link set tun0 up")
    os.system("ip link set tun0 mtu 1300")
    
    # Routage vers le LAN Entreprise (Important !)
    # On ajoute la route vers le réseau 10.10.x.x via le serveur VPN
    os.system("ip route add 10.10.0.0/16 via 10.0.0.1 dev tun0 2>/dev/null")
    
except Exception as e:
    log(f"Erreur config IP: {e}")

log("🚀 TUNNEL ACTIF. Vous êtes connecté.")

inputs = [sock, tun_fd]

try:
    while True:
        ready, _, _ = select.select(inputs, [], [])
        
        for source in ready:
            if source is tun_fd:
                packet = os.read(tun_fd, 4096)
                if packet:
                    packet = fix_checksum(packet)
                    encrypted = xor_cipher(packet)
                    send_packet(sock, encrypted)
            
            if source is sock:
                data = recv_packet(sock)
                if not data: 
                    log("❌ Serveur déconnecté.")
                    sys.exit(0)
                
                decrypted = xor_cipher(data)
                os.write(tun_fd, decrypted)

except KeyboardInterrupt:
    print("Arrêt.")
finally:
    sock.close()