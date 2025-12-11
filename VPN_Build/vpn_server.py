import socket
import struct
import os
import fcntl
import select

IP_ECOUTE = "0.0.0.0"
PORT = 9999

# Config TUN
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
# --------------------------------------------------
# --- FONCTIONS TUNNELING ---
def config_tun_dev():
    tun = os.open("/dev/net/tun", os.O_RDWR)
    ifr = struct.pack('16sH', b'tun0', IFF_TUN | IFF_NO_PI)
    fcntl.ioctl(tun, TUNSETIFF, ifr)
    return tun

def xor_cipher(data):
    return bytes([b ^ KEY for b in data])

# --- NOUVELLES FONCTIONS POUR GERER LES PAQUETS ---
def send_packet(sock, data):
    """Envoie la taille (2 octets) puis les données"""
    try:
        # >H = Big Endian, Unsigned Short (max 65535)
        sock.sendall(struct.pack('>H', len(data)) + data)
    except:
        pass

def recv_packet(sock):
    """Lit d'abord la taille, puis exactement le bon nombre d'octets"""
    try:
        # 1. Lire la taille (2 octets)
        header = b''
        while len(header) < 2:
            chunk = sock.recv(2 - len(header))
            if not chunk: return None
            header += chunk
        packet_len = struct.unpack('>H', header)[0]
        
        # 2. Lire le contenu
        packet = b''
        while len(packet) < packet_len:
            chunk = sock.recv(packet_len - len(packet))
            if not chunk: return None
            packet += chunk
        return packet
    except:
        return None
# --------------------------------------------------

tun_fd = config_tun_dev()
# Config IP via le script shell normalement, mais on garde la config de secours
try:
    os.system("ip addr add 10.0.0.1/24 dev tun0")
    os.system("ip link set tun0 up")
    os.system("ip link set tun0 mtu 1400") # Sécurité MTU
except:
    pass

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((IP_ECOUTE, PORT))
server.listen(1)

print(f"🎧 SERVEUR : En attente sur port {PORT}...")
client_socket, addr = server.accept()
print(f"🔗 SERVEUR : Connecté avec {addr}")

inputs = [client_socket, tun_fd]

try:
    while True:
        ready, _, _ = select.select(inputs, [], [])

        for source in ready:
            if source is client_socket:
                # RECEPTION DEPUIS LE RESEAU (TCP)
                data = recv_packet(client_socket)
                if not data: 
                    print("Client déconnecté.")
                    exit(0)
                
                decrypted = xor_cipher(data)
                os.write(tun_fd, decrypted)
            
            if source is tun_fd:
                # RECEPTION DEPUIS LE TUNNEL (KERNEL)
                packet = os.read(tun_fd, 4096)
                if packet:
                    # 👇 ON RÉPARE LE PAQUET AVANT DE L'ENVOYER 👇
                    packet = fix_checksum(packet) 
                    
                    encrypted = xor_cipher(packet)
                    send_packet(client_socket, encrypted)

except KeyboardInterrupt:
    print("\nArrêt.")
finally:
    client_socket.close()
    server.close()