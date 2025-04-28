const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifySubQuestions() {
  try {
    console.log('Checking subquestions in the database...');
    
    // Get all subquestions
    const snapshot = await db.collection('subQuestions').get();
    
    if (snapshot.empty) {
      console.log('No subquestions found in the database.');
      return;
    }
    
    console.log(`Found ${snapshot.size} subquestions:`);
    
    snapshot.forEach(doc => {
      const data = doc.data();
      console.log('\nSubQuestion:');
      console.log(`- ID: ${doc.id}`);
      console.log(`- Question: ${data.question || 'N/A'}`);
      console.log(`- Category ID: ${data.categoryId || 'N/A'}`);
      console.log(`- SubCategory ID: ${data.subCategoryId || 'N/A'}`);
      console.log(`- Yay Count: ${data.yayCount || 0}`);
      console.log(`- Nay Count: ${data.nayCount || 0}`);
    });
    
  } catch (error) {
    console.error('Error verifying subquestions:', error);
  } finally {
    admin.app().delete();
  }
}

verifySubQuestions(); 