import socket
import struct
import os
import select
import time
import sys

# Config
SERVER_IP = os.getenv("VPN_SERVER_IP", "vpn-server")
SERVER_PORT = 9999
TUNSETIFF = 0x400454ca
IFF_TUN   = 0x0001
IFF_NO_PI = 0x1000
KEY = 0x99 

# Ajoute ceci après les imports
def checksum(data):
    if len(data) % 2 != 0:
        data += b'\x00'
    res = sum(struct.unpack("!%dH" % (len(data) // 2), data))
    res = (res >> 16) + (res & 0xffff)
    res += res >> 16
    return (~res) & 0xffff

def fix_checksum(packet):
    """Recalcule les checksums IP et TCP pour rendre le paquet valide."""
    try:
        # 1. Checksum IP (si c'est IPv4)
        if packet[0] >> 4 == 4:
            ip_header_len = (packet[0] & 0x0F) * 4
            ip_header = bytearray(packet[:ip_header_len])
            ip_header[10:12] = b'\x00\x00'  # Reset checksum
            chk = checksum(ip_header)
            ip_header[10:12] = struct.pack("!H", chk)
            packet = bytes(ip_header) + packet[ip_header_len:]
            
            # 2. Checksum TCP (si protocole == 6)
            if packet[9] == 6:
                tcp_packet = packet[ip_header_len:]
                src_ip = packet[12:16]
                dst_ip = packet[16:20]
                # Pseudo-header TCP
                pseudo_header = src_ip + dst_ip + b'\x00\x06' + struct.pack("!H", len(tcp_packet))
                tcp_header_list = bytearray(tcp_packet)
                tcp_header_list[16:18] = b'\x00\x00' # Reset TCP checksum
                chk = checksum(pseudo_header + tcp_header_list)
                tcp_header_list[16:18] = struct.pack("!H", chk)
                packet = packet[:ip_header_len] + bytes(tcp_header_list)
    except:
        pass # Si paquet malformé, on ne touche à rien
    return packet
# -----------------------
# --- FONCTIONS UTILITAIRES ---
def log(msg):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)

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

# --- GESTION PAQUETS ---
def send_packet(sock, data):
    # On envoie la taille (2 octets) + données
    try:
        packet = struct.pack('>H', len(data)) + data
        sock.sendall(packet)
    except Exception as e:
        log(f"Erreur envoi socket: {e}")

def recv_packet(sock):
    # Lecture exacte de la taille puis des données
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
# -----------------------

tun_fd = config_tun_dev()
# Config IP manuelle (backup)
try:
    os.system("ip addr add 10.0.0.2/24 dev tun0")
    os.system("ip link set tun0 up")
    os.system("ip link set tun0 mtu 1300") # MTU Conservatrice
except:
    pass

log("✅ CLIENT : Interface tun0 prête.")

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
connected = False
while not connected:
    try:
        log(f"🔄 Connexion vers {SERVER_IP}...")
        sock.connect((SERVER_IP, SERVER_PORT))
        connected = True
    except Exception as e:
        time.sleep(2)

log("✅ CLIENT : Connecté !")

inputs = [sock, tun_fd]

try:
    while True:
        ready, _, _ = select.select(inputs, [], [])
        
        for source in ready:
            if source is tun_fd:
                # Lecture TUN -> Envoi Réseau
                packet = os.read(tun_fd, 4096)
                if packet:
                    packet = fix_checksum(packet)
                    encrypted = xor_cipher(packet)
                    send_packet(sock, encrypted)
            
            if source is sock:
                # Lecture Réseau -> Ecriture TUN
                data = recv_packet(sock)
                if not data: 
                    # On garde ce log critique quand même
                    # log("❌ Serveur déconnecté.")
                    sys.exit(0)
                
                # 👇 ON COMMENTE CE LOG POUR ACCÉLÉRER 👇
                # log(f"📥 NET -> TUN ({len(data)} octets)")
                
                decrypted = xor_cipher(data)
                os.write(tun_fd, decrypted)

except KeyboardInterrupt:
    print("Arrêt.")
finally:
    sock.close()