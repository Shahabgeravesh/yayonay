const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define collections to clear
const collectionsToClear = [
  'categories',
  'subCategories',
  'subQuestions',
  'votes'
];

async function clearCollection(collectionName) {
  try {
    console.log(`Clearing collection: ${collectionName}`);
    
    // Get all documents in the collection
    const snapshot = await db.collection(collectionName).get();
    
    // Create a batch
    const batch = db.batch();
    let count = 0;
    
    // Add delete operations to the batch
    snapshot.forEach(doc => {
      batch.delete(doc.ref);
      count++;
      
      // Firestore has a limit of 500 operations per batch
      if (count % 450 === 0) {
        batch.commit();
        console.log(`Committed batch of ${count} deletions for ${collectionName}`);
        count = 0;
      }
    });
    
    // Commit any remaining operations
    if (count > 0) {
      await batch.commit();
      console.log(`Committed final batch of ${count} deletions for ${collectionName}`);
    }
    
    console.log(`Successfully cleared collection: ${collectionName}`);
    
  } catch (error) {
    console.error(`Error clearing collection ${collectionName}:`, error);
  }
}

async function clearAllData() {
  try {
    console.log('Starting to clear all data...');
    
    // Clear each collection
    for (const collection of collectionsToClear) {
      await clearCollection(collection);
    }
    
    console.log('Successfully cleared all data');
    
  } catch (error) {
    console.error('Error in clearAllData:', error);
  }
}

// Run the function
clearAllData(); 