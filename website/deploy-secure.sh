#!/bin/bash

# Script de déploiement sécurisé FinIMoi
# Les identifiants sont demandés à l'exécution pour plus de sécurité

echo "🚀 Déploiement sécurisé du site FinIMoi..."

# Configuration
FTP_HOST="ftp.cluster021.hosting.ovh.net"
FTP_DIR="/www"
FTP_PORT="21"
WEBSITE_DIR="/Users/yoannbeugre/Documents/DEV/finimoi/website"
DEPLOY_DIR="/Users/yoannbeugre/Documents/DEV/finimoi/deploy"

# Demander les identifiants
echo "🔐 Identifiants OVH requis:"
read -p "Utilisateur FTP: " FTP_USER
read -s -p "Mot de passe FTP: " FTP_PASS
echo ""

# Créer le dossier de déploiement
echo "📁 Préparation des fichiers..."
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

# Copier tous les fichiers
cp -r "$WEBSITE_DIR"/* "$DEPLOY_DIR/"

# Nettoyer les fichiers de développement
rm -f "$DEPLOY_DIR/README.md"
rm -f "$DEPLOY_DIR/prepare-deploy.sh"
rm -f "$DEPLOY_DIR/deploy-secure.sh"

echo "📋 Fichiers à déployer:"
find "$DEPLOY_DIR" -type f | wc -l | tr -d ' '

# Déploiement avec lftp (recommandé)
if command -v lftp &> /dev/null; then
    echo "📡 Déploiement via LFTP..."
    cd "$DEPLOY_DIR"
    
    lftp -c "
    set ftp:passive-mode on;
    set ftp:ssl-allow no;
    set ssl:verify-certificate no;
    open ftp://$FTP_USER:$FTP_PASS@$FTP_HOST:$FTP_PORT;
    cd $FTP_DIR;
    mirror -R --delete --verbose --exclude-glob=*.DS_Store . .;
    quit
    "
    
    if [ $? -eq 0 ]; then
        echo "✅ Déploiement réussi !"
        echo "🌐 Site disponible sur: https://finimoi.com"
    else
        echo "❌ Erreur lors du déploiement"
        exit 1
    fi
else
    echo "❌ LFTP non installé. Installation requise:"
    echo "   brew install lftp"
    exit 1
fi

# Nettoyage
echo "🧹 Nettoyage..."
rm -rf "$DEPLOY_DIR"

echo "🎉 Déploiement terminé avec succès !"
