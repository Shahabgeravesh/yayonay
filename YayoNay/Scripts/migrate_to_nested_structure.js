// migrate_to_nested_structure.js
// Run with: node migrate_to_nested_structure.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateSubCategories() {
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

async function migrateSubQuestions() {
  const subQuestionsSnap = await db.collection('subQuestions').get();
  let migrated = 0;
  for (const doc of subQuestionsSnap.docs) {
    const data = doc.data();
    const subCategoryId = data.subCategoryId;
    const categoryId = data.categoryId;
    if (!categoryId || !subCategoryId) {
      console.log(`Skipping subquestion ${doc.id} (missing categoryId or subCategoryId)`);
      continue;
    }
    const subQRef = db.collection('categories').doc(categoryId)
      .collection('subcategories').doc(subCategoryId)
      .collection('subquestions').doc(doc.id);
    await subQRef.set(data);
    console.log(`Migrated subquestion ${doc.id} to categories/${categoryId}/subcategories/${subCategoryId}/subquestions`);
    migrated++;
  }
  console.log(`Migration complete! Migrated ${migrated} subquestions.`);
}

async function migrateVotes() {
  const votesSnap = await db.collection('votes').get();
  let migrated = 0;
  for (const doc of votesSnap.docs) {
    const data = doc.data();
    const userId = data.userId;
    if (!userId) {
      console.log(`Skipping vote ${doc.id} (missing userId)`);
      continue;
    }
    const voteRef = db.collection('users').doc(userId).collection('votes').doc(doc.id);
    await voteRef.set(data);
    console.log(`Migrated vote ${doc.id} to users/${userId}/votes`);
    migrated++;
  }
  console.log(`Migration complete! Migrated ${migrated} votes.`);
}

async function main() {
  console.log('Starting migration to nested structure...');
  await migrateSubCategories();
  await migrateSubQuestions();
  await migrateVotes();
  console.log('All migrations complete!');
}

main().catch(err => {
  console.error('Migration failed:', err);
}); 