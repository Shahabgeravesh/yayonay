const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupRootSubQuestions() {
    console.log('Starting cleanup of root subquestions collection...');
    
    try {
        // Get all subquestions from root collection
        const rootSubquestions = await db.collection('subQuestions').get();
        console.log(`Found ${rootSubquestions.size} subquestions in root collection`);
        
        // Track statistics
        let deletedCount = 0;
        let errorCount = 0;
        
        // Delete each subquestion
        for (const doc of rootSubquestions.docs) {
            try {
                await doc.ref.delete();
                deletedCount++;
                console.log(`Deleted subquestion: ${doc.id}`);
            } catch (error) {
                console.error(`Error deleting subquestion ${doc.id}:`, error);
                errorCount++;
            }
        }
        
        // Print summary
        console.log('\nCleanup Summary:');
        console.log('----------------');
        console.log(`Total subquestions processed: ${rootSubquestions.size}`);
        console.log(`Successfully deleted: ${deletedCount}`);
        console.log(`Errors encountered: ${errorCount}`);
        
        // Verify cleanup
        const remainingDocs = await db.collection('subQuestions').count().get();
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
cleanupRootSubQuestions(); 