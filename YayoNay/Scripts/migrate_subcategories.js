const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateSubCategories() {
  console.log('Starting subcategories migration...');
  
  try {
    // Get all subcategories from the separate collection
    const subCategoriesSnapshot = await db.collection('subCategories').get();
    console.log(`Found ${subCategoriesSnapshot.size} subcategories to migrate`);

    // Create a batch for writing
    let batch = db.batch();
    let batchCount = 0;
    const BATCH_LIMIT = 500; // Firestore batch limit is 500

    // Process each subcategory
    for (const doc of subCategoriesSnapshot.docs) {
      const subCategoryData = doc.data();
      const subCategoryId = doc.id;
      
      // Get the category ID from the subcategory data
      const categoryId = subCategoryData.categoryId;
      
      if (!categoryId) {
        console.error(`Subcategory ${subCategoryId} has no categoryId, skipping...`);
        continue;
      }

      // Create the nested subcategory document
      const nestedRef = db
        .collection('categories')
        .doc(categoryId)
        .collection('subcategories')
        .doc(subCategoryId);

      // Add to batch
      batch.set(nestedRef, subCategoryData);
      batchCount++;

      // If we reach the batch limit, commit and create a new batch
      if (batchCount >= BATCH_LIMIT) {
        console.log(`Committing batch of ${batchCount} documents...`);
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    // Commit any remaining documents
    if (batchCount > 0) {
      console.log(`Committing final batch of ${batchCount} documents...`);
      await batch.commit();
    }

    console.log('Migration completed successfully!');
    
    // Verify the migration
    const categoriesSnapshot = await db.collection('categories').get();
    let totalNestedSubCategories = 0;
    
    for (const categoryDoc of categoriesSnapshot.docs) {
      const subCategoriesSnapshot = await categoryDoc.ref.collection('subcategories').get();
      totalNestedSubCategories += subCategoriesSnapshot.size;
    }
    
    console.log(`Verification: Found ${totalNestedSubCategories} subcategories in the nested structure`);
    console.log(`Original count: ${subCategoriesSnapshot.size} subcategories`);
    
    if (totalNestedSubCategories === subCategoriesSnapshot.size) {
      console.log('Verification successful! All subcategories have been migrated correctly.');
    } else {
      console.error('Verification failed! Some subcategories may be missing.');
    }

  } catch (error) {
    console.error('Error during migration:', error);
  }
}

// Run the migration
migrateSubCategories()
  .then(() => {
    console.log('Migration script completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Migration script failed:', error);
    process.exit(1);
  }); 