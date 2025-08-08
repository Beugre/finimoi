# FinIMoi Website

Site web officiel de l'application FinIMoi avec pages de redirection pour les paiements CinetPay.

## Structure

```
website/
├── index.html              # Page d'accueil principale
├── payment-success.html    # Page de succès de paiement
├── payment-cancel.html     # Page d'annulation de paiement
└── assets/
    ├── css/
    │   └── style.css       # Styles principaux
    ├── js/
    │   └── main.js         # JavaScript principal
    └── images/             # Images et logos
```

## Fonctionnalités

### Page d'accueil (`index.html`)
- Landing page attractive inspirée de Revolut/Lydia
- Présentation des fonctionnalités FinIMoi
- Section de téléchargement (App Store/Google Play)
- Design responsive
- SEO optimisé

### Pages de redirection de paiement
- **payment-success.html** : Redirection après paiement réussi
- **payment-cancel.html** : Redirection après annulation
- Deep links automatiques vers l'app (`finimoi://`)
- Fallback vers la page d'accueil
- Détection d'app non installée

## Déploiement sur OVH

### 1. Préparation des fichiers
```bash
# Zipper le contenu du dossier website/
cd /Users/yoannbeugre/Documents/DEV/finimoi/website
zip -r finimoi-website.zip .
```

### 2. Upload via cPanel OVH
1. Connectez-vous à votre cPanel OVH
2. Allez dans "Gestionnaire de fichiers"
3. Naviguez vers le dossier `public_html` ou `www`
4. Uploadez et décompressez `finimoi-website.zip`
5. Vérifiez que `index.html` est à la racine

### 3. Configuration DNS
Assurez-vous que votre domaine `finimoi.com` pointe vers les serveurs OVH :
- Type A : `finimoi.com` → IP de votre hébergement
- Type CNAME : `www.finimoi.com` → `finimoi.com`

### 4. SSL/HTTPS
- Activez le certificat SSL Let's Encrypt dans cPanel
- Forcez la redirection HTTP → HTTPS

## URLs importantes

Une fois déployé, ces URLs seront disponibles :

- **Site principal** : `https://finimoi.com`
- **Succès de paiement** : `https://finimoi.com/payment-success.html`
- **Annulation de paiement** : `https://finimoi.com/payment-cancel.html`

## Configuration dans l'app Flutter

Les URLs sont déjà configurées dans :
- `lib/core/config/cinetpay_config.dart`
- `returnUrl` et `cancelUrl` pointent vers finimoi.com

## Personnalisation

### Couleurs principales
```css
--primary-color: #6366f1;    /* Indigo */
--secondary-color: #06b6d4;  /* Cyan */
--accent-color: #f59e0b;     /* Amber */
```

### Polices
- Police principale : Inter (Google Fonts)
- Fallback : System fonts

### Images à ajouter
Placez ces images dans `assets/images/` :
- ✅ `logo.svg` (logo vectoriel principal) 
- ✅ `logo.png` (logo PNG haute résolution)
- ✅ `logo.jpg` (logo JPEG pour réseaux sociaux)
- ✅ `favicon.png` (32x32) - Généré automatiquement
- ✅ `apple-touch-icon.png` (180x180) - Généré automatiquement

## Performance

- CSS et JS minifiés pour la production
- Images optimisées (WebP recommandé)
- Lazy loading pour les images
- Gzip activé côté serveur

## Analytics

Ajoutez Google Analytics dans `index.html` :
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

## Maintenance

### Mise à jour des liens de téléchargement
Quand l'app sera publiée, mettez à jour les liens dans `index.html` :
```html
<!-- Remplacer # par les vrais liens -->
<a href="https://apps.apple.com/app/finimoi" class="download-btn">
<a href="https://play.google.com/store/apps/details?id=com.finimoi.app" class="download-btn">
```

### Webhook de paiement
Créez un endpoint `/api/payment/notify` pour recevoir les notifications CinetPay.

## Tests

Testez les redirections :
1. `https://finimoi.com/payment-success.html?transaction_id=test123`
2. `https://finimoi.com/payment-cancel.html?reason=user_cancelled`

Les deep links doivent s'ouvrir vers l'app FinIMoi si installée.

## Support

Pour toute question sur le déploiement, consultez la documentation OVH ou contactez leur support.
