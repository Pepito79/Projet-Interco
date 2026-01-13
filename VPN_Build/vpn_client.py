#!/usr/bin/env python3
import socket
import os
import struct
import fcntl
import sys
import select

# Configuration
SERVER_IP = "120.0.34.2" # R_Entreprise1 Public IP (DNAT to 10.10.20.10)
SERVER_PORT = 9999
TUN_IP = "10.8.0.2"
TUN_NETMASK = "255.255.255.0"

# TUN Interface constants
TUNSETIFF = 0x400454ca
IFF_TUN = 0x0001
IFF_NO_PI = 0x1000

def create_tun_interface():
    # Ensure /dev/net/tun exists
    if not os.path.exists("/dev/net/tun"):
        os.system("mkdir -p /dev/net")
        os.system("mknod /dev/net/tun c 10 200")
        os.system("chmod 600 /dev/net/tun")

    tun = os.open("/dev/net/tun", os.O_RDWR)
    ifr = struct.pack('16sH', b'tun0', IFF_TUN | IFF_NO_PI)
    fcntl.ioctl(tun, TUNSETIFF, ifr)
    # Configure IP
    os.system(f"ip link set dev tun0 up")
    os.system(f"ip addr add {TUN_IP}/24 dev tun0")
    # Add route to Enterprise LAN 10.10.10.0/24 via VPN
    os.system(f"ip route add 10.10.10.0/24 via 10.8.0.1")
    return tun

def main():
    print(f"[Client] Connecting to {SERVER_IP}:{SERVER_PORT}", flush=True)
    
    # Setup TUN
    try:
        tun_fd = create_tun_interface()
        print(f"[Client] Tunnel interface tun0 created with IP {TUN_IP}", flush=True)
    except Exception as e:
        print(f"[Client] Error creating TUN interface: {e}", flush=True)
        sys.exit(1)

    # Setup Socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    
    # Verify we can reach server (optional, but good)
    
    print(f"[Client] Tunnel started. Routing 10.10.10.0/24 via VPN.", flush=True)

    KEY = b"SECRET_KEY_123"

    def xor_data(data):
        # Mix index into XOR to avoid revealing key on null bytes
        return bytes([b ^ KEY[i % len(KEY)] ^ (i & 0xFF) for i, b in enumerate(data)])

    # Authentication Handshake
    print(f"[Client] Authenticating as 'admin'...", flush=True)
    auth_msg = xor_data(b"AUTH:admin:password123")
    # Authentication Handshake with Retry
    username = sys.argv[1] if len(sys.argv) > 1 else "admin"
    password = sys.argv[2] if len(sys.argv) > 2 else "password123"
    
    print(f"[Client] Authenticating as '{username}'...", flush=True)
    auth_str = f"AUTH:{username}:{password}"
    auth_msg = xor_data(auth_str.encode('utf-8'))
    
    auth_success = False
    sock.settimeout(2.0) # 2s timeout per attempt
    
    for attempt in range(5):
        try:
            print(f"[Client] Sending Auth request (attempt {attempt+1}/5)...", flush=True)
            sock.sendto(auth_msg, (SERVER_IP, SERVER_PORT))
            
            data, addr = sock.recvfrom(4096)
            response = xor_data(data)
            
            if response == b"AUTH_OK" and addr[0] == SERVER_IP:
                print(f"[Client] Authentication SUCCESS!", flush=True)
                auth_success = True
                break
            else:
                print(f"[Client] Received unexpected response during auth: {response}", flush=True)
        except socket.timeout:
            print(f"[Client] Auth timed out, retrying...", flush=True)
            continue
        except Exception as e:
             print(f"[Client] Auth error: {e}", flush=True)
    
    sock.settimeout(None) # Remove timeout
    
    if not auth_success:
        print(f"[Client] Authentication FAILED after 5 attempts!", flush=True)
        sys.exit(1)

    print(f"[Client] Tunnel started. Routing 10.10.10.0/24 via VPN.", flush=True)

    while True:
        r, w, x = select.select([sock, tun_fd], [], [])
        
        for fd in r:
            if fd == tun_fd:
                try:
                    # Read from TUN, send to Server
                    packet = os.read(tun_fd, 4096)
                    if len(packet) > 0:
                        # Encrypt
                        encrypted_packet = xor_data(packet)
                        sock.sendto(encrypted_packet, (SERVER_IP, SERVER_PORT))
                except Exception as e:
                    print(f"[Client] Error handling TUN packet: {e}", flush=True)

            if fd == sock:
                try:
                    # Read from Server, write to TUN
                    data, addr = sock.recvfrom(4096)
                    if addr[0] == SERVER_IP and len(data) > 0:
                        # Decrypt
                        decrypted_data = xor_data(data)
                        os.write(tun_fd, decrypted_data)
                except Exception as e:
                    print(f"[Client] Error handling UDP packet: {e}", flush=True)
if __name__ == "__main__":
    main()
