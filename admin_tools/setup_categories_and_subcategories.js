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

async function setupCategoriesAndSubcategories() {
    try {
        console.log('Starting setup...');

        // Step 1: Create Panel category if it doesn't exist
        console.log('\n1. Setting up Panel category...');
        const panelCategoryRef = db.collection('categories').doc();
        await panelCategoryRef.set({
            name: 'Panel',
            imageURL: 'https://via.placeholder.com/60',
            order: 1,
            yayCount: 0,
            nayCount: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`✅ Created Panel category with ID: ${panelCategoryRef.id}`);

        // Step 2: Get all subcategories from root collection
        console.log('\n2. Fetching subcategories from root collection...');
        const subcategoriesSnapshot = await db.collection('subcategories').get();
        
        if (subcategoriesSnapshot.empty) {
            console.log('❌ No subcategories found in root collection');
            return;
        }

        console.log(`Found ${subcategoriesSnapshot.size} subcategories in root collection`);

        // Step 3: Process each subcategory
        console.log('\n3. Processing subcategories...');
        let restoredCount = 0;
        let errorCount = 0;
        
        for (const subcategoryDoc of subcategoriesSnapshot.docs) {
            const subcategoryData = subcategoryDoc.data();
            const subcategoryId = subcategoryDoc.id;
            
            console.log(`\nProcessing subcategory: ${subcategoryId}`);
            console.log('Original subcategory data:', subcategoryData);
            
            try {
                // Update root subcategory with Panel category ID
                await db.collection('subcategories').doc(subcategoryId).update({
                    categoryId: panelCategoryRef.id
                });
                
                // Create in nested structure
                await db.collection('categories')
                    .doc(panelCategoryRef.id)
                    .collection('subcategories')
                    .doc(subcategoryId)
                    .set({
                        ...subcategoryData,
                        categoryId: panelCategoryRef.id,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                        // Ensure all required fields are present
                        name: subcategoryData.name || '',
                        imageURL: subcategoryData.imageURL || 'https://via.placeholder.com/60',
                        order: subcategoryData.order || 0,
                        yayCount: subcategoryData.yayCount || 0,
                        nayCount: subcategoryData.nayCount || 0
                    });
                
                restoredCount++;
                console.log(`✅ Restored subcategory: ${subcategoryData.name || 'unnamed'} (${subcategoryId}) under Panel category`);
            } catch (error) {
                console.error(`❌ Error processing subcategory ${subcategoryId}:`, error.message);
                errorCount++;
            }
        }
        
        console.log(`\n✨ Setup complete!`);
        console.log(`✅ Created Panel category`);
        console.log(`✅ Successfully processed: ${restoredCount} subcategories`);
        if (errorCount > 0) {
            console.log(`⚠️ Errors encountered: ${errorCount} subcategories`);
        }
        
    } catch (error) {
        console.error('❌ Error during setup:', error);
    } finally {
        // Terminate the app when done
        process.exit(0);
    }
}

// Run the setup
setupCategoriesAndSubcategories(); 