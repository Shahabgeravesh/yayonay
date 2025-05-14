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

async function restoreSubcategories() {
    try {
        console.log('Starting subcategories restoration...');
        
        // Get all subcategories from root collection
        const subcategoriesSnapshot = await db.collection('subcategories').get();
        
        if (subcategoriesSnapshot.empty) {
            console.log('❌ No subcategories found in root collection');
            return;
        }

        // Keep track of restored subcategories
        let restoredCount = 0;
        let errorCount = 0;
        
        // Process each subcategory
        for (const subcategoryDoc of subcategoriesSnapshot.docs) {
            const subcategoryData = subcategoryDoc.data();
            const subcategoryId = subcategoryDoc.id;
            
            // Check if categoryId exists
            if (!subcategoryData.categoryId) {
                console.log(`⚠️ Skipping subcategory ${subcategoryId} - no categoryId found`);
                errorCount++;
                continue;
            }

            try {
                // Create the subcategory in the nested structure
                await db.collection('categories')
                    .doc(subcategoryData.categoryId)
                    .collection('subcategories')
                    .doc(subcategoryId)
                    .set({
                        ...subcategoryData,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        // Ensure all required fields are present
                        name: subcategoryData.name || '',
                        imageURL: subcategoryData.imageURL || 'https://via.placeholder.com/60',
                        order: subcategoryData.order || 0,
                        yayCount: subcategoryData.yayCount || 0,
                        nayCount: subcategoryData.nayCount || 0
                    });
                
                restoredCount++;
                console.log(`✅ Restored subcategory: ${subcategoryData.name} (${subcategoryId}) under category ${subcategoryData.categoryId}`);
            } catch (error) {
                console.error(`❌ Error restoring subcategory ${subcategoryId}:`, error.message);
                errorCount++;
            }
        }
        
        console.log(`\n✨ Restoration complete!`);
        console.log(`✅ Successfully restored: ${restoredCount} subcategories`);
        if (errorCount > 0) {
            console.log(`⚠️ Errors encountered: ${errorCount} subcategories`);
        }
        
    } catch (error) {
        console.error('❌ Error during restoration:', error);
    } finally {
        // Terminate the app when done
        process.exit(0);
    }
}

// Run the restoration
restoreSubcategories(); 