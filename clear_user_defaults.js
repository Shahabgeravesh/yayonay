const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function clearUserDefaults() {
  try {
    console.log('Starting to clear UserDefaults-like data...');

    // Get all subcategories to find their IDs
    const subcategoriesSnapshot = await db.collection('subCategories').get();
    const batch = db.batch();
    let count = 0;

    // Create a collection to store UserDefaults-like data
    const userDefaultsRef = db.collection('userDefaults');
    
    // Clear all existing entries
    const existingDefaults = await userDefaultsRef.get();
    const clearBatch = db.batch();
    existingDefaults.docs.forEach(doc => {
      clearBatch.delete(doc.ref);
    });
    await clearBatch.commit();
    console.log('Cleared existing UserDefaults entries');

    console.log('Successfully cleared all UserDefaults-like data');
    process.exit(0);
  } catch (error) {
    console.error('Error clearing UserDefaults data:', error);
    process.exit(1);
  }
}

// Run the function
clearUserDefaults(); 