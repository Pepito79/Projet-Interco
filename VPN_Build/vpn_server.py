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

# === 1. BASE DE DONNÉES UTILISATEURS (SIMULATION LDAP) ===
USERS_DB = {
    "thomas": "superpassword",  # Ton compte
    "pepito": "admin123",       # Compte admin
    "rh_user": "rhsecure"       # Compte RH
}

# === 2. ATTRIBUTION DES IP FIXES (IDENTITÉ RÉSEAU) ===
IP_ALLOCATION = {
    "thomas": "10.0.0.2",
    "pepito": "10.0.0.10",
    "rh_user": "10.0.0.20"
}

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

def handle_login(client_sock):
    """Gère l'échange d'authentification"""
    try:
        # On attend "user:pass"
        print("🔐 Attente des identifiants...")
        data = client_sock.recv(1024).decode('utf-8').strip()
        if ":" not in data:
            print("❌ Format invalide reçu.")
            return False, None
            
        username, password = data.split(":", 1)
        
        # Vérification
        if USERS_DB.get(username) == password:
            assigned_ip = IP_ALLOCATION.get(username, "10.0.0.100")
            print(f"✅ Authentification OK pour {username}. IP attribuée : {assigned_ip}")
            
            # On envoie "OK:IP"
            client_sock.send(f"OK:{assigned_ip}".encode('utf-8'))
            return True, assigned_ip
        else:
            print(f"❌ Mot de passe incorrect pour {username}")
            client_sock.send(b"FAIL")
            return False, None
    except Exception as e:
        print(f"❌ Erreur Auth: {e}")
        return False, None
    
# --- MAIN ---
tun_fd = config_tun_dev()
try:
    os.system("ip addr add 10.0.0.1/24 dev tun0")
    os.system("ip link set tun0 up")
    os.system("ip link set tun0 mtu 1400")
except:
    pass

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind((IP_ECOUTE, PORT))
server.listen(1)

print(f"🎧 SERVEUR : En attente sur port {PORT}...")

# Boucle pour accepter les connexions (simple : un client à la fois pour ce TP)
while True:
    try:
        client_socket, addr = server.accept()
        print(f"🔗 Connexion entrante de {addr}")
        
        # --- ETAPE AUTHENTIFICATION ---
        auth_success, client_vpn_ip = handle_login(client_socket)
        
        if not auth_success:
            client_socket.close()
            print("⛔ Déconnexion du client non authentifié.\n")
            continue # On attend le prochain
            
        print("🚀 Tunnel établi. Échange de paquets en cours...")
        
        inputs = [client_socket, tun_fd]
        
        # Boucle de transfert de données
        try:
            while True:
                ready, _, _ = select.select(inputs, [], [])

                for source in ready:
                    if source is client_socket:
                        data = recv_packet(client_socket)
                        if not data: 
                            raise Exception("Déconnexion Client")
                        
                        decrypted = xor_cipher(data)
                        os.write(tun_fd, decrypted)
                    
                    if source is tun_fd:
                        packet = os.read(tun_fd, 4096)
                        if packet:
                            packet = fix_checksum(packet) 
                            encrypted = xor_cipher(packet)
                            send_packet(client_socket, encrypted)
        except Exception as e:
            print(f"Information: {e}")
        finally:
            client_socket.close()
            print("♻️  Serveur prêt pour une nouvelle connexion.\n")

    except KeyboardInterrupt:
        break