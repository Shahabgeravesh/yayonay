const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: "yayonay-e7f58"
});

const db = admin.firestore();

async function migrateToNestedStructure() {
    console.log('Starting migration to nested structure...');
    
    try {
        // 1. Get all subcategories from root collection
        const rootSubcategoriesSnapshot = await db.collection('subcategories').get();
        console.log(`Found ${rootSubcategoriesSnapshot.size} subcategories in root collection`);
        
        // 2. Process each subcategory
        let migratedCount = 0;
        let errorCount = 0;
        
        for (const subcategoryDoc of rootSubcategoriesSnapshot.docs) {
            const subcategoryData = subcategoryDoc.data();
            const subcategoryId = subcategoryDoc.id;
            const categoryId = subcategoryData.categoryId;
            
            if (!categoryId) {
                console.log(`❌ Skipping subcategory ${subcategoryId}: No categoryId found`);
                errorCount++;
                continue;
            }
            
            try {
                // 3. Check if category exists
                const categoryDoc = await db.collection('categories').doc(categoryId).get();
                if (!categoryDoc.exists) {
                    console.log(`❌ Skipping subcategory ${subcategoryId}: Parent category ${categoryId} not found`);
                    errorCount++;
                    continue;
                }
                
                // 4. Create in nested structure
                await db.collection('categories')
                    .doc(categoryId)
                    .collection('subcategories')
                    .doc(subcategoryId)
                    .set({
                        ...subcategoryData,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                
                migratedCount++;
                console.log(`✅ Migrated subcategory: ${subcategoryData.name} (${subcategoryId}) to nested structure`);
                
            } catch (error) {
                console.error(`❌ Error migrating subcategory ${subcategoryId}:`, error.message);
                errorCount++;
            }
        }
        
        console.log('\nMigration Summary:');
        console.log(`✅ Successfully migrated: ${migratedCount} subcategories`);
        console.log(`❌ Errors encountered: ${errorCount}`);
        
        // 5. Verify migration
        await verifyMigration();
        
    } catch (error) {
        console.error('Migration failed:', error);
    }
}

async function verifyMigration() {
    console.log('\nVerifying migration...');
    
    try {
        // Get count from root collection
        const rootCount = (await db.collection('subcategories').get()).size;
        
        // Get count from nested collections
        let nestedCount = 0;
        const categoriesSnapshot = await db.collection('categories').get();
        
        for (const categoryDoc of categoriesSnapshot.docs) {
            const subcategoriesSnapshot = await categoryDoc.ref.collection('subcategories').get();
            nestedCount += subcategoriesSnapshot.size;
        }
        
        console.log('\nVerification Results:');
        console.log(`- Root collection count: ${rootCount}`);
        console.log(`- Nested collections count: ${nestedCount}`);
        
        if (nestedCount >= rootCount) {
            console.log('✅ Migration verification successful');
        } else {
            console.log('❌ Migration verification failed: Some data may be missing');
        }
        
    } catch (error) {
        console.error('Verification failed:', error);
    }
}

// Run migration
migrateToNestedStructure()
    .then(() => {
        console.log('\nMigration process completed');
        process.exit(0);
    })
    .catch(error => {
        console.error('Migration process failed:', error);
        process.exit(1);
    }); 