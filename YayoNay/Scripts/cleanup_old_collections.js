// cleanup_old_collections.js
// Run with: node cleanup_old_collections.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanup() {
  // Delete subCategories collection
  const subCategoriesSnap = await db.collection('subCategories').get();
  for (const doc of subCategoriesSnap.docs) {
    await doc.ref.delete();
    console.log(`Deleted subCategory ${doc.id}`);
  }

  // Delete subQuestions collection
  const subQuestionsSnap = await db.collection('subQuestions').get();
  for (const doc of subQuestionsSnap.docs) {
    await doc.ref.delete();
    console.log(`Deleted subQuestion ${doc.id}`);
  }

  // Delete votes collection
  const votesSnap = await db.collection('votes').get();
  for (const doc of votesSnap.docs) {
    await doc.ref.delete();
    console.log(`Deleted vote ${doc.id}`);
  }

  // Optionally, delete random_subcategories if it exists
  const randomSubcategoriesSnap = await db.collection('random_subcategories').get();
  for (const doc of randomSubcategoriesSnap.docs) {
    await doc.ref.delete();
    console.log(`Deleted random_subcategory ${doc.id}`);
  }

  console.log('Cleanup complete!');
}

cleanup().catch(err => {
  console.error('Cleanup failed:', err);
}); 