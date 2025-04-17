const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

// Your Firebase configuration
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: "yayonay-e7f58.firebaseapp.com",
  projectId: "yayonay-e7f58",
  storageBucket: "yayonay-e7f58.appspot.com",
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function listIndexes() {
  console.log('Fetching current indexes...');
  
  try {
    // Get all collections to check their indexes
    const collections = [
      'topics',
      'subCategories',
      'comments',
      'votes',
      'categories'
    ];
    
    console.log('\nCurrent Firestore Collections and Their Indexes:');
    console.log('--------------------------------------------');
    
    for (const collectionName of collections) {
      console.log(`\nCollection: ${collectionName}`);
      console.log('Indexes required based on queries:');
      
      switch (collectionName) {
        case 'topics':
          console.log('1. category ASC, date DESC');
          console.log('2. upvotes DESC');
          break;
        case 'subCategories':
          console.log('1. yayCount DESC');
          console.log('2. categoryId ASC, order ASC');
          break;
        case 'comments':
          console.log('1. subCategoryId ASC, date DESC');
          console.log('2. voteId ASC, date DESC');
          break;
        case 'votes':
          console.log('1. date DESC');
          console.log('2. userId ASC, date DESC');
          break;
        case 'categories':
          console.log('1. order ASC');
          break;
      }
      console.log('--------------------------------------------');
    }
    
    console.log('\nNote: To see actual indexes, you need to check the Firebase Console');
    console.log('or use the Firebase Admin SDK with proper credentials.');
  } catch (error) {
    console.error('Error listing indexes:', error);
  }
  
  process.exit(0);
}

listIndexes(); 