const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteAllVotes() {
  try {
    console.log('Starting to delete all votes data...');

    // 1. Delete main votes collection if it exists
    const votesSnapshot = await db.collection('votes').get();
    const votesBatch = db.batch();
    let votesCount = 0;

    votesSnapshot.docs.forEach(doc => {
      votesBatch.delete(doc.ref);
      votesCount++;
    });

    if (votesCount > 0) {
      await votesBatch.commit();
      console.log(`Deleted ${votesCount} votes from main votes collection`);
    }

    // 2. Delete votes from subQuestions collection
    const subQuestionsSnapshot = await db.collection('subQuestions').get();
    const subQuestionsBatch = db.batch();
    let subQuestionsCount = 0;

    subQuestionsSnapshot.docs.forEach(doc => {
      subQuestionsBatch.update(doc.ref, {
        yayCount: 0,
        nayCount: 0,
        votes: admin.firestore.FieldValue.delete()  // Delete the votes field if it exists
      });
      subQuestionsCount++;
    });

    if (subQuestionsCount > 0) {
      await subQuestionsBatch.commit();
      console.log(`Reset vote counts for ${subQuestionsCount} subQuestions`);
    }

    // 3. Delete votes from categories collection
    const categoriesSnapshot = await db.collection('categories').get();
    const categoriesBatch = db.batch();
    let categoriesCount = 0;

    categoriesSnapshot.docs.forEach(doc => {
      categoriesBatch.update(doc.ref, {
        votesCount: 0,
        votes: admin.firestore.FieldValue.delete()  // Delete the votes field if it exists
      });
      categoriesCount++;
    });

    if (categoriesCount > 0) {
      await categoriesBatch.commit();
      console.log(`Reset vote counts for ${categoriesCount} categories`);
    }

    // 4. Delete user votes
    const usersSnapshot = await db.collection('users').get();
    let userVotesCount = 0;

    for (const userDoc of usersSnapshot.docs) {
      // Delete votes subcollection
      const userVotesSnapshot = await userDoc.ref.collection('votes').get();
      const userVotesBatch = db.batch();
      
      userVotesSnapshot.docs.forEach(voteDoc => {
        userVotesBatch.delete(voteDoc.ref);
        userVotesCount++;
      });

      if (userVotesSnapshot.docs.length > 0) {
        await userVotesBatch.commit();
      }

      // Also update the user document to remove any vote-related fields
      await userDoc.ref.update({
        votes: admin.firestore.FieldValue.delete(),
        votesCount: admin.firestore.FieldValue.delete(),
        yayVotes: admin.firestore.FieldValue.delete(),
        nayVotes: admin.firestore.FieldValue.delete()
      });
    }

    if (userVotesCount > 0) {
      console.log(`Deleted ${userVotesCount} user votes`);
    }

    // 5. Check for userVotes collection if it exists
    const userVotesSnapshot = await db.collection('userVotes').get();
    const userVotesBatch = db.batch();
    let userVotesMainCount = 0;

    userVotesSnapshot.docs.forEach(doc => {
      userVotesBatch.delete(doc.ref);
      userVotesMainCount++;
    });

    if (userVotesMainCount > 0) {
      await userVotesBatch.commit();
      console.log(`Deleted ${userVotesMainCount} documents from userVotes collection`);
    }

    console.log('Successfully deleted all votes data');
    process.exit(0);
  } catch (error) {
    console.error('Error deleting votes:', error);
    process.exit(1);
  }
}

// Run the function
deleteAllVotes(); 