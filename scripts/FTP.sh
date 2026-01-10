# echo "🚀 Configuration du Serveur FTP Public (FAI)..."

# # 1. Configuration de la route par défaut pour le serveur
# # On lui dit de passer par R11 (120.0.37.1) pour répondre au monde entier
# docker exec Serveur_FTP_Public ip route del default 2>/dev/null
# docker exec Serveur_FTP_Public ip route add default via 120.0.37.1

# echo "✅ Route par défaut configurée via 120.0.37.1"

# # 2. Installation de lftp sur les clients pour les tests
# echo "📦 Installation des outils de test sur Client_B1 et Client_Ent1..."
# docker exec Client_B1 apk add --no-cache lftp > /dev/null
# docker exec Client_Ent1 apk add --no-cache lftp > /dev/null

# echo "🔑 Configuration de la confiance SSH entre Web et FTP..."

# # 1. Installer et démarrer SSH sur le serveur FTP
# docker exec Serveur_FTP_Public apk add --no-cache openssh
# docker exec Serveur_FTP_Public ssh-keygen -A
# docker exec Serveur_FTP_Public sh -c "echo 'root:root' | chpasswd"
# docker exec Serveur_FTP_Public sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
# docker exec -d Serveur_FTP_Public /usr/sbin/sshd

# # 2. Générer une clé sur le serveur Web et l'envoyer au FTP
# docker exec Serveur_Web1 ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
# pubkey=$(docker exec Serveur_Web1 cat /root/.ssh/id_rsa.pub)
# docker exec Serveur_FTP_Public sh -c "mkdir -p /root/.ssh && echo '$pubkey' >> /root/.ssh/authorized_keys"