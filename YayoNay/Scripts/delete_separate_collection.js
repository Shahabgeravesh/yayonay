const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteCollection() {
  console.log('Deleting separate subCategories collection...');
  
  try {
    // Verify collection is empty first
    const snapshot = await db.collection('subCategories').get();
    if (snapshot.size > 0) {
      console.error('Collection is not empty! Aborting deletion.');
      process.exit(1);
    }

    // Delete the collection
    await db.collection('subCategories').doc().delete();
    console.log('Successfully deleted subCategories collection');

  } catch (error) {
    console.error('Error during deletion:', error);
    process.exit(1);
  }
}

// Run the deletion
deleteCollection()
  .then(() => {
    console.log('\nDeletion completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Deletion failed:', error);
    process.exit(1);
  }); 