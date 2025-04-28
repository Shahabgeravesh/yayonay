const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifySportsData() {
  try {
    console.log('Starting to verify Sports data...');

    // First, get the Sports category
    const categoriesSnapshot = await db.collection('categories')
      .where('name', '==', 'Sports')
      .get();
    
    if (categoriesSnapshot.empty) {
      console.log('Sports category not found in database!');
      return;
    }

    const sportsId = categoriesSnapshot.docs[0].id;
    console.log('Found Sports category with ID:', sportsId);

    // Get all subcategories for Sports
    const subcategoriesSnapshot = await db.collection('subCategories')
      .where('categoryId', '==', sportsId)
      .get();

    console.log(`Found ${subcategoriesSnapshot.size} subcategories for Sports:`);
    subcategoriesSnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log('-', data.name, '(ID:', doc.id, ')');
      console.log('  Data:', JSON.stringify(data, null, 2));
    });

    // Check if there are any votes for these subcategories
    const votesSnapshot = await db.collection('votes').get();
    console.log(`\nFound ${votesSnapshot.size} total votes in the database`);

    // Check user data
    const usersSnapshot = await db.collection('users').get();
    console.log(`\nFound ${usersSnapshot.size} users in the database`);
    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log('User:', doc.id);
      console.log('Data:', JSON.stringify(data, null, 2));
    });

  } catch (error) {
    console.error('Error verifying Sports data:', error);
  }
}

verifySportsData(); 