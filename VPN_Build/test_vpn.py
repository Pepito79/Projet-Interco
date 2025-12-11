import socket

# Configuration
IP_ECOUTE = "0.0.0.0" # 0.0.0.0 signifie "écouter sur toutes les interfaces réseau"
PORT = 9999           # Un port arbitraire (au-dessus de 1024)

# Création du socket (IPv4, TCP)
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# On attache le socket à l'adresse et au port
# Cela peut échouer si le port est déjà pris
try:
    server_socket.bind((IP_ECOUTE, PORT))
    print(f"✅ Socket lié avec succès sur {IP_ECOUTE}:{PORT}")
except Exception as e:
    print(f"❌ Erreur lors du bind : {e}")
    exit()

# On se met en mode écoute (Listen)
server_socket.listen(1)
print("🎧 Le serveur VPN écoute... En attente d'un client...")

# Le programme va se mettre en "pause" ici jusqu'à ce qu'un client se connecte
conn, address = server_socket.accept()

print(f"🎉 Connexion établie avec : {address}")

try:
    while True:
        # On attend des données (bloquant)
        data = conn.recv(1024)
        
        # Si recv renvoie vide, c'est que le client a coupé la connexion (TCP FIN)
        if not data:
            print("⚠️ Le client s'est déconnecté.")
            break
            
        print(f"📥 Reçu ({len(data)} bytes) : {data.decode('utf-8')}")
        
        # Mode ECHO : on renvoie exactement ce qu'on a reçu
        conn.send(data)

except KeyboardInterrupt:
    print("\n🛑 Arrêt manuel du serveur.")

conn.close()
server_socket.close()