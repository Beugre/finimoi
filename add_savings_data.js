const admin = require('firebase-admin');

// Initialiser Firebase Admin avec les credentials
const serviceAccount = require('./path/to/serviceAccount.json'); // Vous devrez fournir le bon chemin

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function addSavingsData() {
  try {
    // Ajouter des plans d'épargne d'exemple
    const savingsPlans = [
      {
        title: 'Plan Épargne Débutant',
        description: 'Parfait pour commencer à épargner avec un taux attractif',
        minimumAmount: 5000,
        interestRate: 2.5,
        durationMonths: 6,
        features: ['Retrait flexible', 'Taux garanti', 'Pas de frais'],
        color: 'blue',
        isActive: true
      },
      {
        title: 'Plan Épargne Premium',
        description: 'Taux d\'intérêt avantageux pour les épargnants ambitieux',
        minimumAmount: 25000,
        interestRate: 4.2,
        durationMonths: 12,
        features: ['Taux privilégié', 'Conseiller dédié', 'Assurance incluse'],
        color: 'green',
        isActive: true
      },
      {
        title: 'Plan Épargne Projet',
        description: 'Idéal pour financer vos projets à moyen terme',
        minimumAmount: 10000,
        interestRate: 3.8,
        durationMonths: 18,
        features: ['Objectif personnalisé', 'Rappels automatiques', 'Bonus fidélité'],
        color: 'purple',
        isActive: true
      }
    ];

    // Ajouter les plans
    for (const plan of savingsPlans) {
      await db.collection('savings_plans').add(plan);
      console.log(`Plan ajouté: ${plan.title}`);
    }

    console.log('Données d\'épargne ajoutées avec succès!');
  } catch (error) {
    console.error('Erreur lors de l\'ajout des données:', error);
  }
}

addSavingsData();
