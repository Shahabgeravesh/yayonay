const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

// Initialize Firebase Admin with service account
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: "yayonay-e7f58",
    storageBucket: "yayonay-e7f58.firebasestorage.app",
    databaseURL: `https://yayonay-e7f58.firebaseio.com`
});

const db = admin.firestore();

async function restoreCategories() {
    try {
        console.log('Starting categories restoration...');
        
        // Get all categories from the nested structure
        const categoriesSnapshot = await db.collection('categories').get();
        
        // Keep track of restored categories
        let restoredCount = 0;
        
        // Process each category
        for (const categoryDoc of categoriesSnapshot.docs) {
            const categoryData = categoryDoc.data();
            const categoryId = categoryDoc.id;
            
            // Create the category in the root collection with the same ID
            await db.collection('categories').doc(categoryId).set({
                ...categoryData,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                // Ensure all required fields are present
                name: categoryData.name || '',
                imageURL: categoryData.imageURL || 'https://via.placeholder.com/60',
                order: categoryData.order || 0,
                yayCount: categoryData.yayCount || 0,
                nayCount: categoryData.nayCount || 0
            });
            
            restoredCount++;
            console.log(`✅ Restored category: ${categoryData.name} (${categoryId})`);
        }
        
        console.log(`\n✨ Successfully restored ${restoredCount} categories!`);
        
    } catch (error) {
        console.error('❌ Error restoring categories:', error);
    } finally {
        // Terminate the app when done
        process.exit(0);
    }
}

// Run the restoration
restoreCategories(); 