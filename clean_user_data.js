const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanUserData() {
  try {
    console.log('Starting to clean user data...');

    // Get all users
    const usersSnapshot = await db.collection('users').get();
    const batch = db.batch();
    let userCount = 0;

    usersSnapshot.docs.forEach(doc => {
      // Update user document to remove vote-related data
      batch.update(doc.ref, {
        lastVoteDate: admin.firestore.FieldValue.delete(),
        recentActivity: admin.firestore.FieldValue.delete(),
        votesCount: 0,
        yayVotes: admin.firestore.FieldValue.delete(),
        nayVotes: admin.firestore.FieldValue.delete()
      });
      userCount++;
    });

    if (userCount > 0) {
      await batch.commit();
      console.log(`Cleaned data for ${userCount} users`);
    }

    // Also clear any UserDefaults-like data in the votes collection
    const votesSnapshot = await db.collection('votes').get();
    const votesBatch = db.batch();
    let votesCount = 0;

    votesSnapshot.docs.forEach(doc => {
      votesBatch.delete(doc.ref);
      votesCount++;
    });

    if (votesCount > 0) {
      await votesBatch.commit();
      console.log(`Deleted ${votesCount} votes`);
    }

    console.log('Successfully cleaned all user data');
    process.exit(0);
  } catch (error) {
    console.error('Error cleaning user data:', error);
    process.exit(1);
  }
}

// Run the function
cleanUserData(); 