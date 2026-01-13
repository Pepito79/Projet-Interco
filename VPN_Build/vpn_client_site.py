#!/usr/bin/env python3
import socket
import os
import struct
import fcntl
import sys
import select

# Configuration
SERVER_IP = "120.0.34.2" # R_Entreprise1
SERVER_PORT = 9999
TUN_IP = "10.8.0.3" # Unique IP for Site Gateway
TUN_NETMASK = "255.255.255.0"

# TUN Constants
TUNSETIFF = 0x400454ca
IFF_TUN = 0x0001
IFF_NO_PI = 0x1000

KEY = b"SECRET_KEY_123"

def xor_data(data):
    return bytes([b ^ KEY[i % len(KEY)] ^ (i & 0xFF) for i, b in enumerate(data)])

def create_tun_interface():
    if not os.path.exists("/dev/net/tun"):
        os.system("mkdir -p /dev/net")
        os.system("mknod /dev/net/tun c 10 200")
        os.system("chmod 600 /dev/net/tun")

    tun = os.open("/dev/net/tun", os.O_RDWR)
    ifr = struct.pack('16sH', b'tun0', IFF_TUN | IFF_NO_PI)
    fcntl.ioctl(tun, TUNSETIFF, ifr)
    
    os.system(f"ip link set dev tun0 up")
    os.system(f"ip addr add {TUN_IP}/24 dev tun0")
    
    # Routes to Enterprise 1 Networks (LAN + DMZ)
    os.system(f"ip route add 10.10.10.0/24 via 10.8.0.1")
    os.system(f"ip route add 10.10.20.0/24 via 10.8.0.1")
    
    # Enable IP Forwarding on Gateway (Critical for Site-to-Site)
    os.system("sysctl -w net.ipv4.ip_forward=1")
    # Masquerade outbound TUN traffic? 
    # If Ent1 Server routes to 20.20.20.0/24, we don't need NAT.
    # But VPN_Gateway must forward packets from LAN to TUN.
    return tun

def main():
    print(f"[Gateway] Connecting to {SERVER_IP}:{SERVER_PORT}", flush=True)
    
    try:
        tun_fd = create_tun_interface()
        print(f"[Gateway] Tunnel interface tun0 created with IP {TUN_IP}", flush=True)
    except Exception as e:
        print(f"[Gateway] Error creating TUN interface: {e}", flush=True)
        sys.exit(1)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    # Auth
    print(f"[Gateway] Authenticating as 'site2'...", flush=True)
    auth_str = "AUTH:site2:secret"
    auth_msg = xor_data(auth_str.encode('utf-8'))
    
    auth_success = False
    sock.settimeout(2.0)
    
    for attempt in range(30):
        try:
            print(f"[Gateway] Sending Auth request (attempt {attempt+1}/30)...", flush=True)
            sock.sendto(auth_msg, (SERVER_IP, SERVER_PORT))
            
            data, addr = sock.recvfrom(4096)
            response = xor_data(data)
            
            if response == b"AUTH_OK" and addr[0] == SERVER_IP:
                print(f"[Gateway] Authentication SUCCESS!", flush=True)
                auth_success = True
                break
        except socket.timeout:
            print(f"[Gateway] Auth timed out, retrying...", flush=True)
            continue
        except Exception as e:
             print(f"[Gateway] Auth error: {e}", flush=True)
    
    sock.settimeout(None)
    
    if not auth_success:
        print(f"[Gateway] Authentication FAILED!", flush=True)
        sys.exit(1)

    print(f"[Gateway] Routing started.", flush=True)

    while True:
        r, w, x = select.select([sock, tun_fd], [], [])
        
        for fd in r:
            if fd == tun_fd:
                try:
                    packet = os.read(tun_fd, 4096)
                    if len(packet) > 0:
                        encrypted_packet = xor_data(packet)
                        sock.sendto(encrypted_packet, (SERVER_IP, SERVER_PORT))
                except Exception as e:
                    print(f"[Gateway] Error handling TUN packet: {e}", flush=True)

            if fd == sock:
                try:
                    data, addr = sock.recvfrom(4096)
                    if addr[0] == SERVER_IP and len(data) > 0:
                        decrypted_data = xor_data(data)
                        os.write(tun_fd, decrypted_data)
                except Exception as e:
                    print(f"[Gateway] Error handling UDP packet: {e}", flush=True)

if __name__ == "__main__":
    main()
