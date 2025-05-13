const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, deleteDoc } = require('firebase/firestore');

// Your web app's Firebase configuration
const firebaseConfig = {
    projectId: 'yayonay-app',
    apiKey: process.env.FIREBASE_API_KEY
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function cleanupVotesCollection() {
    console.log('Starting votes collection cleanup...');
    
    try {
        // Get all documents from the root votes collection
        const votesSnapshot = await getDocs(collection(db, 'votes'));
        const totalDocs = votesSnapshot.size;
        
        console.log(`Found ${totalDocs} documents in root votes collection`);
        
        if (totalDocs === 0) {
            console.log('No documents found in root votes collection. Nothing to delete.');
            return;
        }
        
        console.log('Starting deletion of root votes collection...');
        
        // Delete all documents
        const deletePromises = votesSnapshot.docs.map(doc => 
            deleteDoc(doc.ref)
        );
        
        await Promise.all(deletePromises);
        console.log('Successfully deleted all documents from root votes collection');
        
    } catch (error) {
        console.error('Error during cleanup:', error);
        process.exit(1);
    }
    
    process.exit(0);
}

cleanupVotesCollection(); 