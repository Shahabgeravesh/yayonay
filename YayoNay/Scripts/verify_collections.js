const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyCollections() {
  console.log('Verifying collections...');
  
  try {
    // Check separate subCategories collection
    const subCategoriesSnapshot = await db.collection('subCategories').get();
    console.log(`\nSeparate subCategories collection:`);
    console.log(`- Document count: ${subCategoriesSnapshot.size}`);
    if (subCategoriesSnapshot.size > 0) {
      console.log('- First document ID:', subCategoriesSnapshot.docs[0].id);
      console.log('- First document data:', subCategoriesSnapshot.docs[0].data());
    }

    // Check nested subcategories
    const categoriesSnapshot = await db.collection('categories').get();
    console.log(`\nNested subcategories structure:`);
    console.log(`- Categories count: ${categoriesSnapshot.size}`);
    
    let totalNestedSubCategories = 0;
    for (const categoryDoc of categoriesSnapshot.docs) {
      const subCategoriesSnapshot = await categoryDoc.ref.collection('subcategories').get();
      totalNestedSubCategories += subCategoriesSnapshot.size;
      console.log(`\nCategory: ${categoryDoc.id}`);
      console.log(`- Subcategories count: ${subCategoriesSnapshot.size}`);
      if (subCategoriesSnapshot.size > 0) {
        console.log('- First subcategory ID:', subCategoriesSnapshot.docs[0].id);
        console.log('- First subcategory data:', subCategoriesSnapshot.docs[0].data());
      }
    }
    
    console.log(`\nTotal nested subcategories: ${totalNestedSubCategories}`);

  } catch (error) {
    console.error('Error during verification:', error);
  }
}

// Run the verification
verifyCollections()
  .then(() => {
    console.log('\nVerification completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Verification failed:', error);
    process.exit(1);
  }); 