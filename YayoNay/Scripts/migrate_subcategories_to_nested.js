// migrate_subcategories_to_nested.js
// Run with: node migrate_subcategories_to_nested.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrate() {
  const subCategoriesSnap = await db.collection('subCategories').get();
  let migrated = 0;
  for (const doc of subCategoriesSnap.docs) {
    const data = doc.data();
    const categoryId = data.categoryId;
    if (!categoryId) {
      console.log(`Skipping subcategory ${doc.id} (missing categoryId)`);
      continue;
    }
    const subCatRef = db.collection('categories').doc(categoryId).collection('subcategories').doc(doc.id);
    await subCatRef.set(data);
    console.log(`Migrated subcategory ${doc.id} to categories/${categoryId}/subcategories`);
    migrated++;
  }
  console.log(`Migration complete! Migrated ${migrated} subcategories.`);
}

migrate().catch(err => {
  console.error('Migration failed:', err);
}); 