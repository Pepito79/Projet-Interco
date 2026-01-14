#!/bin/bash
# Script de test VoIP (SIP REGISTER)
CLIENT=${1:-Client_Ent1}
SERVER_IP="10.10.20.20"

echo "🧪 Test de connectivité VoIP depuis $CLIENT vers $SERVER_IP..."

# Installation de Python3 si absent
echo "   Checking/Installing Python3 on $CLIENT..."
docker exec $CLIENT sh -c "command -v python3 >/dev/null || apk add --no-cache python3"

# Injecter le script Python de test
echo "   Injecting SIP test script..."
docker exec -i $CLIENT sh -c 'cat > /tmp/sip_test.py' <<EOF
import socket
import sys
import random

target_ip = "$SERVER_IP"
target_port = 5060
sip_user = "1001"
tag = "".join([str(random.randint(0,9)) for _ in range(8)])
call_id = "".join([str(random.randint(0,9)) for _ in range(10)])

# Paquet SIP REGISTER minimal
msg = (
    f"REGISTER sip:{target_ip} SIP/2.0\r\n"
    f"Via: SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK{tag}\r\n"
    f"Max-Forwards: 70\r\n"
    f"From: <sip:{sip_user}@{target_ip}>;tag={tag}\r\n"
    f"To: <sip:{sip_user}@{target_ip}>\r\n"
    f"Call-ID: {call_id}@{target_ip}\r\n"
    f"CSeq: 1 REGISTER\r\n"
    f"Contact: <sip:{sip_user}@127.0.0.1:5060>\r\n"
    f"Content-Length: 0\r\n"
    f"\r\n"
)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.settimeout(5)

try:
    print(f"   📡 Sending REGISTER to {target_ip}:{target_port}...")
    sock.sendto(msg.encode(), (target_ip, target_port))
    
    data, addr = sock.recvfrom(4096)
    reply = data.decode('utf-8', errors='ignore')
    first_line = reply.split("\r\n")[0]
    print(f"   📩 Received: {first_line}")
    
    if "200 OK" in first_line or "401 Unauthorized" in first_line:
        print("   ✅ SUCCESS: Server reachable and speaking SIP.")
        sys.exit(0)
    else:
        print(f"   ❌ FAILURE: Unexpected response code.")
        sys.exit(1)

except socket.timeout:
    print("   ❌ FAILURE: Response timeout (Firewall issue or Server down).")
    sys.exit(1)
except Exception as e:
    print(f"   ❌ FAILURE: {e}")
    sys.exit(1)
EOF

# Exécuter le test
echo "   Running test..."
docker exec $CLIENT python3 /tmp/sip_test.py
RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "🎉 Test passed for $CLIENT"
else
    echo "💥 Test failed for $CLIENT"
fi
exit $RESULT
