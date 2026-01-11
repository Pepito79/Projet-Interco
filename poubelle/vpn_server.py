import socket, struct, os, fcntl, select, sys

try:
    PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9999
    # Lecture du 3eme argument pour le nom (tun0/tun1)
    IFACE_NAME = sys.argv[3] if len(sys.argv) > 3 else "tun0"
except:
    PORT = 9999; IFACE_NAME = "tun0"

print(f"--- Serveur VPN | Port: {PORT} | Interface: {IFACE_NAME} ---")

IP_ECOUTE = "0.0.0.0"
TUNSETIFF = 0x400454ca; IFF_TUN = 0x0001; IFF_NO_PI = 0x1000; KEY = 0x99 

USERS_DB = {"thomas": "superpassword", "site2_gw": "azerty123", "pepito": "admin123"}
IP_ALLOCATION = {"thomas": "10.0.0.2", "site2_gw": "10.0.1.50", "pepito": "10.0.0.10"}

def checksum(data):
    if len(data) % 2 != 0: data += b'\x00'
    res = sum(struct.unpack("!%dH" % (len(data) // 2), data))
    res = (res >> 16) + (res & 0xffff); res += res >> 16
    return (~res) & 0xffff

def fix_checksum(packet):
    try:
        if packet[0] >> 4 == 4:
            ip_hdr_len = (packet[0] & 0x0F) * 4; ip_hdr = bytearray(packet[:ip_hdr_len])
            ip_hdr[10:12] = b'\x00\x00'; ip_hdr[10:12] = struct.pack("!H", checksum(ip_hdr))
            packet = bytes(ip_hdr) + packet[ip_hdr_len:]
    except: pass
    return packet

def config_tun_dev():
    tun = os.open("/dev/net/tun", os.O_RDWR)
    ifr = struct.pack('16sH', IFACE_NAME.encode('utf-8'), IFF_TUN | IFF_NO_PI)
    fcntl.ioctl(tun, TUNSETIFF, ifr)
    return tun

def xor_cipher(data): return bytes([b ^ KEY for b in data])
def send_packet(sock, data): 
    try: sock.sendall(struct.pack('>H', len(data)) + data)
    except: pass

def recv_packet(sock):
    try:
        header = b''; 
        while len(header) < 2:
            chunk = sock.recv(2 - len(header))
            if not chunk: return None
            header += chunk
        pkt_len = struct.unpack('>H', header)[0]; pkt = b''
        while len(pkt) < pkt_len:
            chunk = sock.recv(pkt_len - len(pkt))
            if not chunk: return None
            pkt += chunk
        return pkt
    except: return None

def handle_login(client):
    try:
        data = client.recv(1024).decode('utf-8').strip()
        if ":" not in data: return False, None
        u, p = data.split(":", 1)
        if USERS_DB.get(u) == p:
            ip = IP_ALLOCATION.get(u, "10.0.0.100")
            client.send(f"OK:{ip}".encode('utf-8'))
            return True, ip
    except: pass
    client.send(b"FAIL"); return False, None

tun_fd = config_tun_dev()
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind((IP_ECOUTE, PORT)); sock.listen(5)

while True:
    try:
        client, addr = sock.accept()
        print(f"🔗 Connexion: {addr}")
        if handle_login(client)[0]:
            inputs = [client, tun_fd]
            try:
                while True:
                    r, _, _ = select.select(inputs, [], [])
                    for s in r:
                        if s is client:
                            d = recv_packet(client)
                            if not d: break
                            os.write(tun_fd, xor_cipher(d))
                        if s is tun_fd:
                            p = os.read(tun_fd, 4096)
                            if p: send_packet(client, xor_cipher(fix_checksum(p)))
            except: pass
            client.close()
    except KeyboardInterrupt: break
