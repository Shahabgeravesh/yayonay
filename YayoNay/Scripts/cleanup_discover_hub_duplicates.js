const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteDiscoverHubDuplicates() {
  const snapshot = await db.collection('subCategories').where('categoryId', '==', 'random').get();
  let deleted = 0;
  const batch = db.batch();
  snapshot.forEach(doc => {
    batch.delete(doc.ref);
    deleted++;
  });
  if (deleted > 0) {
    await batch.commit();
    console.log(`✅ Deleted ${deleted} duplicate Discover Hub subcategories.`);
  } else {
    console.log('No Discover Hub duplicates found.');
  }
  process.exit();
}

deleteDiscoverHubDuplicates(); 