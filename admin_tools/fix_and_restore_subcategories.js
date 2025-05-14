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

async function fixAndRestoreSubcategories() {
    try {
        console.log('Starting subcategories fix and restoration...');
        
        // Get all subcategories from root collection
        console.log('Fetching subcategories from root collection...');
        const subcategoriesSnapshot = await db.collection('subcategories').get();
        
        if (subcategoriesSnapshot.empty) {
            console.log('❌ No subcategories found in root collection');
            return;
        }

        console.log(`Found ${subcategoriesSnapshot.size} subcategories in root collection`);

        // Get all categories to find the "Panel" category
        console.log('Fetching categories...');
        const categoriesSnapshot = await db.collection('categories').get();
        console.log(`Found ${categoriesSnapshot.size} categories`);

        let panelCategoryId = null;

        for (const categoryDoc of categoriesSnapshot.docs) {
            const categoryData = categoryDoc.data();
            console.log(`Category: ${categoryData.name} (${categoryDoc.id})`);
            if (categoryData.name && categoryData.name.toLowerCase() === 'panel') {
                panelCategoryId = categoryDoc.id;
                break;
            }
        }

        if (!panelCategoryId) {
            console.log('❌ Could not find Panel category');
            return;
        }

        console.log(`Found Panel category: ${panelCategoryId}`);

        // Keep track of restored subcategories
        let restoredCount = 0;
        let errorCount = 0;
        
        // Process each subcategory
        for (const subcategoryDoc of subcategoriesSnapshot.docs) {
            const subcategoryData = subcategoryDoc.data();
            const subcategoryId = subcategoryDoc.id;
            
            console.log(`\nProcessing subcategory: ${subcategoryId}`);
            console.log('Subcategory data:', subcategoryData);
            
            // If no categoryId, assign it to the Panel category
            if (!subcategoryData.categoryId) {
                console.log(`⚠️ Fixing subcategory ${subcategoryId} - assigning to Panel category`);
                
                // Update the root subcategory with categoryId
                await db.collection('subcategories').doc(subcategoryId).update({
                    categoryId: panelCategoryId
                });
                
                subcategoryData.categoryId = panelCategoryId;
                console.log('Updated subcategory with categoryId');
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

// Run the fix and restoration
fixAndRestoreSubcategories(); 