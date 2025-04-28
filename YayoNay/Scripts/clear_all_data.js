const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function clearAllData() {
  try {
    console.log('Starting to clear all data...');

    // Collections to clear
    const collections = [
      'votes',
      'comments',
      'replies',
      'topicBoxComments',
      'likes',
      'users',
      'topics',
      'topicBox',
      'userVotes',
      'userDefaults'
    ];

    // Clear each collection
    for (const collectionName of collections) {
      console.log(`Clearing ${collectionName}...`);
      
      const snapshot = await db.collection(collectionName).get();
      const batch = db.batch();
      let count = 0;

      snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
        count++;
      });

      if (count > 0) {
        await batch.commit();
        console.log(`Deleted ${count} documents from ${collectionName}`);
      }
    }

    // Reset vote counts in subcategories
    const subcategoriesSnapshot = await db.collection('subCategories').get();
    const subcategoriesBatch = db.batch();
    let subcategoriesCount = 0;

    subcategoriesSnapshot.docs.forEach(doc => {
      subcategoriesBatch.update(doc.ref, {
        yayCount: 0,
        nayCount: 0,
        votes: admin.firestore.FieldValue.delete()
      });
      subcategoriesCount++;
    });

    if (subcategoriesCount > 0) {
      await subcategoriesBatch.commit();
      console.log(`Reset vote counts for ${subcategoriesCount} subcategories`);
    }

    // Reset vote counts in categories
    const categoriesSnapshot = await db.collection('categories').get();
    const categoriesBatch = db.batch();
    let categoriesCount = 0;

    categoriesSnapshot.docs.forEach(doc => {
      categoriesBatch.update(doc.ref, {
        votesCount: 0,
        votes: admin.firestore.FieldValue.delete()
      });
      categoriesCount++;
    });

    if (categoriesCount > 0) {
      await categoriesBatch.commit();
      console.log(`Reset vote counts for ${categoriesCount} categories`);
    }

    console.log('Successfully cleared all data');
    process.exit(0);
  } catch (error) {
    console.error('Error clearing data:', error);
    process.exit(1);
  }
}

// Run the function
clearAllData(); 