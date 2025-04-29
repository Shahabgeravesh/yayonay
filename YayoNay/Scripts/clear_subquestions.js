const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function clearSubQuestions() {
  try {
    console.log('Starting to clear sub-questions...');
    
    const snapshot = await db.collection('subQuestions').get();
    const batch = db.batch();
    let count = 0;

    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`Successfully deleted ${count} sub-questions`);
    } else {
      console.log('No sub-questions found to delete');
    }

    process.exit(0);
  } catch (error) {
    console.error('Error clearing sub-questions:', error);
    process.exit(1);
  }
}

// Run the function
clearSubQuestions(); 