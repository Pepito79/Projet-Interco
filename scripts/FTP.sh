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

#!/bin/bash
echo "-------------------------------------------------------"
echo "🛠️  CONFIGURATION DES SERVICES FAI (WEB & FTP)"
echo "-------------------------------------------------------"

# 1. CONFIGURATION RÉSEAU (Routes)
echo "🌐 Configuration des routes par défaut..."
docker exec Serveur_Web1 ip route del default || true
docker exec Serveur_Web1 ip route add default via 120.0.37.1
docker exec Serveur_FTP_Public ip route del default || true
docker exec Serveur_FTP_Public ip route add default via 120.0.37.1

# 2. PRÉPARATION DU SERVEUR FTP (Installation SSH à chaud)
echo "📂 Installation SSH sur le serveur FTP..."
docker exec Serveur_FTP_Public apk add --no-cache openssh > /dev/null
docker exec Serveur_FTP_Public ssh-keygen -A > /dev/null
docker exec Serveur_FTP_Public sh -c "echo 'root:root' | chpasswd"
docker exec Serveur_FTP_Public sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
docker exec -d Serveur_FTP_Public /usr/sbin/sshd # Lance SSH en arrière-plan

# 3. PRÉPARATION DU SERVEUR WEB (Client SSH)
echo "🌐 Installation du client SSH sur le serveur Web..."
docker exec Serveur_Web1 apk add --no-cache openssh-client > /dev/null

# 4. LIAISON DE CONFIANCE (Clés SSH)
echo "🔑 Création de la liaison de confiance Web -> FTP..."
docker exec Serveur_Web1 sh -c "mkdir -p /root/.ssh && [ -f /root/.ssh/id_rsa ] || ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa"
PUBKEY=$(docker exec Serveur_Web1 cat /root/.ssh/id_rsa.pub)

docker exec Serveur_FTP_Public sh -c "mkdir -p /root/.ssh && echo '$PUBKEY' > /root/.ssh/authorized_keys"
docker exec Serveur_FTP_Public chmod 700 /root/.ssh
docker exec Serveur_FTP_Public chmod 600 /root/.ssh/authorized_keys

echo "-------------------------------------------------------"
echo "✅ TERMINÉ : Les services sont prêts !"
echo "-------------------------------------------------------"