#!/bin/bash

# Script de préparation et déploiement automatique du site FinIMoi sur OVH
# Utilisation: ./prepare-deploy.sh

echo "🚀 Préparation du site FinIMoi pour déploiement..."

# Configuration OVH
FTP_HOST="ftp.cluster021.hosting.ovh.net"
FTP_USER="finimob"
FTP_PASS="azertyuiopA1"
FTP_DIR="/www"
FTP_PORT="21"

# Dossiers locaux
WEBSITE_DIR="/Users/yoannbeugre/Documents/DEV/finimoi/website"
DEPLOY_DIR="/Users/yoannbeugre/Documents/DEV/finimoi/deploy"

# Créer le dossier de déploiement
mkdir -p "$DEPLOY_DIR"

# Copier tous les fichiers nécessaires
echo "📁 Copie des fichiers..."
cp -r "$WEBSITE_DIR"/* "$DEPLOY_DIR/"

# Supprimer le README et le script de déploiement (pas nécessaire en production)
rm -f "$DEPLOY_DIR/README.md"
rm -f "$DEPLOY_DIR/prepare-deploy.sh"

# Vérifier la structure
echo "📋 Structure du déploiement:"
find "$DEPLOY_DIR" -type f | sort

# Créer l'archive pour backup local
echo "📦 Création de l'archive de backup..."
cd "$DEPLOY_DIR"
zip -r "../finimoi-website-backup.zip" .

# Fonction pour tester la connexion SFTP
test_connection() {
    echo "🔗 Test de connexion SFTP..."
    sftp -o ConnectTimeout=10 -o BatchMode=no "$FTP_USER@$FTP_HOST" <<EOF
quit
EOF
    return $?
}

# Fonction pour déployer via FTP
deploy_ftp() {
    echo "🚀 Déploiement via FTP vers $FTP_HOST:$FTP_PORT..."
    
    # Créer un script batch FTP temporaire
    FTP_BATCH="/tmp/ftp_commands.txt"
    cat > "$FTP_BATCH" <<EOF
binary
cd $FTP_DIR
lcd .
prompt off
mput *
mput assets/css/*
mput assets/js/*
mput assets/images/*
quit
EOF

    # Exécuter le transfert FTP
    echo "📤 Upload des fichiers via FTP..."
    ftp -n "$FTP_HOST" < "$FTP_BATCH" <<EOF
user $FTP_USER $FTP_PASS
$(cat "$FTP_BATCH")
EOF
    
    # Nettoyer le fichier temporaire
    rm -f "$FTP_BATCH"
    
    if [ $? -eq 0 ]; then
        echo "✅ Déploiement FTP réussi !"
        return 0
    else
        echo "❌ Erreur lors du déploiement FTP"
        return 1
    fi
}

# Alternative avec lftp (plus robuste pour FTP)
deploy_lftp() {
    echo "🚀 Déploiement via LFTP vers $FTP_HOST:$FTP_PORT..."
    
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
        echo "✅ Déploiement réussi avec LFTP !"
        return 0
    else
        echo "❌ Erreur lors du déploiement avec LFTP"
        return 1
    fi
}

# Vérifier si lftp est installé (pas besoin de sshpass pour FTP)
if ! command -v lftp &> /dev/null; then
    echo "⚠️  lftp n'est pas installé. Installation..."
    if command -v brew &> /dev/null; then
        brew install lftp
    else
        echo "❌ Veuillez installer lftp manuellement:"
        echo "   brew install lftp"
        exit 1
    fi
fi

# Choisir la méthode de déploiement
echo "🔧 Tentative de déploiement automatique via FTP..."

# Essayer d'abord avec lftp (plus robuste)
if command -v lftp &> /dev/null; then
    echo "📡 Utilisation de LFTP..."
    deploy_lftp
    DEPLOY_SUCCESS=$?
else
    echo "📡 LFTP non disponible, utilisation de FTP standard..."
    deploy_ftp
    DEPLOY_SUCCESS=$?
fi

echo "✅ Site prêt pour déploiement !"

if [ $DEPLOY_SUCCESS -eq 0 ]; then
    echo "🎉 Déploiement automatique réussi !"
    echo "📁 Backup créé: /Users/yoannbeugre/Documents/DEV/finimoi/finimoi-website-backup.zip"
    echo ""
    echo "� Votre site est maintenant en ligne :"
    echo "   - Site principal: https://finimoi.com"
    echo "   - Succès paiement: https://finimoi.com/payment-success.html"
    echo "   - Annulation: https://finimoi.com/payment-cancel.html"
    echo ""
    echo "�🔧 Prochaines étapes recommandées :"
    echo "1. Vérifier le site: https://finimoi.com"
    echo "2. Tester les pages de redirection"
    echo "3. Activer SSL/HTTPS dans le panel OVH si pas déjà fait"
    echo "4. Configurer les analytics Google"
else
    echo "❌ Déploiement automatique échoué"
    echo "📁 Archive de backup disponible: /Users/yoannbeugre/Documents/DEV/finimoi/finimoi-website-backup.zip"
    echo ""
    echo "🔧 Déploiement manuel requis :"
    echo "1. Uploadez finimoi-website-backup.zip dans votre cPanel OVH"
    echo "2. Extraire dans le dossier public_html ou www"
    echo "3. Vérifier que index.html est à la racine"
    echo "4. Activer SSL/HTTPS"
    echo "5. Tester: https://finimoi.com"
    echo ""
    echo "� Pour le déploiement automatique, vérifiez :"
    echo "   - Connexion internet"
    echo "   - Identifiants SFTP"
    echo "   - Permissions du dossier distant"
fi

echo ""
echo "📊 Récapitulatif technique :"
echo "   - Serveur: $FTP_HOST"
echo "   - Utilisateur: $FTP_USER"
echo "   - Dossier distant: $FTP_DIR"
echo "   - Fichiers déployés: $(find "$DEPLOY_DIR" -type f | wc -l | tr -d ' ') fichiers"
echo "   - Taille totale: $(du -sh "$DEPLOY_DIR" | cut -f1)"
