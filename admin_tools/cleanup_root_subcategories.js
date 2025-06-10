const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupRootSubcategories() {
    console.log('Starting cleanup of root subcategories collection...');
    
    try {
        // Get all subcategories from root collection
        const rootSubcategories = await db.collection('subcategories').get();
        console.log(`Found ${rootSubcategories.size} subcategories in root collection`);
        
        // Track statistics
        let deletedCount = 0;
        let errorCount = 0;
        
        // Delete each subcategory
        for (const doc of rootSubcategories.docs) {
            try {
                await doc.ref.delete();
                deletedCount++;
                console.log(`Deleted subcategory: ${doc.id}`);
            } catch (error) {
                console.error(`Error deleting subcategory ${doc.id}:`, error);
                errorCount++;
            }
        }
        
        // Print summary
        console.log('\nCleanup Summary:');
        console.log('----------------');
        console.log(`Total subcategories processed: ${rootSubcategories.size}`);
        console.log(`Successfully deleted: ${deletedCount}`);
        console.log(`Errors encountered: ${errorCount}`);
        
        // Verify cleanup
        const remainingDocs = await db.collection('subcategories').count().get();
        console.log(`\nRemaining documents in root collection: ${remainingDocs.data().count}`);
        
        if (remainingDocs.data().count === 0) {
            console.log('✅ Cleanup completed successfully!');
        } else {
            console.log('⚠️ Some documents remain in the root collection.');
        }
        
    } catch (error) {
        console.error('Error during cleanup:', error);
    } finally {
        process.exit(0);
    }
}

// Run the cleanup
cleanupRootSubcategories(); 