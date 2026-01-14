#!/bin/bash
echo "🚀 Configuration des routes statiques pour le tunnel VPN..."

# --- SITE 1 (Entreprise 1) ---
# Le routeur de tête doit envoyer tout ce qui va vers le LAN 2 (20.20.20.0/24) vers le serveur VPN
docker exec --privileged R_Entreprise1 ip route add 20.20.20.0/24 via 10.10.20.10 2>/dev/null || true

# Le routeur LAN doit envoyer le trafic vers le routeur de tête (R_Entreprise1)
docker exec --privileged R_Ent_LAN ip route add 20.20.20.0/24 via 10.10.1.1 2>/dev/null || true


# --- SITE 2 (Entreprise 2) ---
# Le routeur de tête du Site 2 doit envoyer le trafic vers le LAN 1 (10.10.10.0/24) vers sa passerelle VPN
docker exec --privileged R_Entreprise2 ip route add 10.10.10.0/24 via 10.20.10.10 2>/dev/null || true

# Le routeur LAN du Site 2 doit envoyer le trafic vers son routeur de tête
docker exec --privileged R_Ent2_LAN ip route add 10.10.10.0/24 via 10.20.10.1 2>/dev/null || true

echo "✅ Routes injectées avec succès."