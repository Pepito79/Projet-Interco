#!/usr/bin/env python3
import socket
import os
import struct
import fcntl
import sys
import select

# Configuration
TUN_IP = "10.8.0.1"
TUN_NETMASK = "255.255.255.0"
PORT = 9999

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
    # Add routes to Site 2
    os.system(f"ip route add 20.20.20.0/24 dev tun0")
    os.system(f"ip route add 10.20.10.0/24 dev tun0")
    
    # Enable IP Forwarding
    os.system("sysctl -w net.ipv4.ip_forward=1")
    # Enable NAT (Masquerade) for VPN traffic
    os.system(f"iptables -t nat -A POSTROUTING -s {TUN_IP}/24 -o eth0 -j MASQUERADE")
    # Allow forwarding
    os.system("iptables -A FORWARD -i tun0 -o eth0 -j ACCEPT")
    os.system("iptables -A FORWARD -i eth0 -o tun0 -j ACCEPT")
    
    return tun

def main():
    print(f"[Server] Starting VPN Server on port {PORT}...", flush=True)
    
    # Setup TUN
    try:
        tun_fd = create_tun_interface()
        print(f"[Server] Tunnel interface tun0 created with IP {TUN_IP}", flush=True)
    except Exception as e:
        print(f"[Server] Error creating TUN interface: {e}", flush=True)
        sys.exit(1)

    # Setup Socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('0.0.0.0', PORT))
    
    print(f"[Server] Listening on 0.0.0.0:{PORT}", flush=True)

    client_addr = None
    KEY = b"SECRET_KEY_123"
    USERS = {"admin": "password123", "site2": "secret"}
    
    # Static IP Assignment
    USER_VIPS = {
        "admin": "10.8.0.2",
        "site2": "10.8.0.3"
    }
    
    # Subnet Routing (Network -> Gateway VIP)
    SUBNET_ROUTES = [
        {"net": "20.20.20.0", "mask": "255.255.255.0", "gw": "10.8.0.3"},
        {"net": "192.168.2.0", "mask": "255.255.255.0", "gw": "10.8.0.2"}
    ]
    
    # Active Sessions: VIP -> RealAddr
    vpn_sessions = {}
    authenticated_clients = set() # Keep for validation

    def xor_data(data):
        # Mix index into XOR to avoid revealing key on null bytes
        return bytes([b ^ KEY[i % len(KEY)] ^ (i & 0xFF) for i, b in enumerate(data)])

    def ip_to_int(ip):
        return struct.unpack("!I", socket.inet_aton(ip))[0]

    def get_target_addr(dest_ip_bytes):
        dest_ip_str = socket.inet_ntoa(dest_ip_bytes)
        
        # 1. Direct VIP Match
        if dest_ip_str in vpn_sessions:
            return vpn_sessions[dest_ip_str]
            
        # 2. Subnet Match
        dest_int = ip_to_int(dest_ip_str)
        for route in SUBNET_ROUTES:
            net_int = ip_to_int(route["net"])
            mask_int = ip_to_int(route["mask"])
            if (dest_int & mask_int) == net_int:
                gw = route["gw"]
                return vpn_sessions.get(gw)
        return None

    while True:
        r, w, x = select.select([sock, tun_fd], [], [])
        
        for fd in r:
            if fd == sock:
                try:
                    data, addr = sock.recvfrom(4096)
                    
                    if len(data) > 0:
                        decrypted_data = xor_data(data)
                        print(f"[Server] Debug Decrypted: {decrypted_data[:50]}...", flush=True)
                        
                        # Check for Control Messages
                        if decrypted_data.startswith(b"AUTH:"):
                            try:
                                parts = decrypted_data.decode('utf-8').split(":")
                                if len(parts) >= 3:
                                    username = parts[1]
                                    password = parts[2]
                                    if USERS.get(username) == password:
                                        print(f"[Server] User '{username}' authenticated from {addr}", flush=True)
                                        vip = USER_VIPS.get(username)
                                        if vip:
                                            vpn_sessions[vip] = addr
                                            print(f"[Server] Assigned VIP {vip} to {addr}", flush=True)
                                        
                                        authenticated_clients.add(addr)
                                        response = xor_data(b"AUTH_OK")
                                        sock.sendto(response, addr)
                                    else:
                                        print(f"[Server] Failed auth attempt from {addr}", flush=True)
                                        sock.sendto(xor_data(b"AUTH_FAIL"), addr)
                            except Exception as e:
                                print(f"[Server] Auth Exception: {e}", flush=True)
                            continue

                        # Data Packet
                        if addr in authenticated_clients:
                             # Update session if IP changed? 
                             # For now assume static session until re-auth.
                             # But update 'vpn_sessions' mapping in reverse? No, expensive.
                             os.write(tun_fd, decrypted_data)
                        else:
                            print(f"[Server] Dropped unauthenticated packet from {addr}", flush=True)
                            pass
                            
                except Exception as e:
                    print(f"[Server] Error handling UPD packet: {e}", flush=True)
            
            if fd == tun_fd:
                try:
                    packet = os.read(tun_fd, 4096)
                    if len(packet) >= 20: # IPv4 Header min size
                        # Extract Dest IP (Bytes 16-19)
                        dest_ip = packet[16:20]
                        target_addr = get_target_addr(dest_ip)
                        
                        # print(f"[Server] TUN Packet to {socket.inet_ntoa(dest_ip)} -> Target {target_addr}", flush=True)

                        if target_addr:
                             # Encrypt TUN data
                            encrypted_packet = xor_data(packet)
                            sock.sendto(encrypted_packet, target_addr)
                        else:
                            # Broadcast/Unknown - drop or debug
                            print(f"[Server] No route for dest {socket.inet_ntoa(dest_ip)}. Header: {packet[:20].hex()}", flush=True)
                            pass
                except Exception as e:
                    print(f"[Server] Error handling TUN packet: {e}", flush=True)

if __name__ == "__main__":
    main()
