const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define collections to clear
const collectionsToClear = [
  'users',
  'categories',
  'subCategories',
  'subQuestions',
  'votes',
  'userVotes',
  'comments',
  'allTimeBest',
  'topics',
  'topicsBox',
  'topicBox',
  'topicComments',
  'bestTopics',
  'popularTopics',
  'trendingTopics',
  'recentTopics',
  'attributeVotes',
  'attributes',
  'attributeTopics'
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

async function clearUserSubcollections() {
  try {
    console.log('Starting to clear user subcollections...');
    
    // Get all users
    const usersSnapshot = await db.collection('users').get();
    let totalSubcollections = 0;
    
    for (const userDoc of usersSnapshot.docs) {
      // Get all subcollections for this user
      const collections = await userDoc.ref.listCollections();
      
      for (const collection of collections) {
        const snapshot = await collection.get();
        const batch = db.batch();
        let count = 0;
        
        snapshot.forEach(doc => {
          batch.delete(doc.ref);
          count++;
          totalSubcollections++;
          
          if (count % 450 === 0) {
            batch.commit();
            console.log(`Committed batch of ${count} deletions for user ${userDoc.id} subcollection ${collection.id}`);
            count = 0;
          }
        });
        
        if (count > 0) {
          await batch.commit();
          console.log(`Committed final batch of ${count} deletions for user ${userDoc.id} subcollection ${collection.id}`);
        }
      }
    }
    
    console.log(`Successfully cleared ${totalSubcollections} user subcollections`);
    
  } catch (error) {
    console.error('Error clearing user subcollections:', error);
  }
}

async function clearAllData() {
  try {
    console.log('Starting to clear all data...');
    
    // First clear user subcollections
    await clearUserSubcollections();
    
    // Then clear all collections including users
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