const { initializeApp } = require('firebase/app');
const { getFirestore } = require('firebase/firestore');
const admin = require('firebase-admin');

// Your Firebase configuration
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: "yayonay-e7f58.firebaseapp.com",
  projectId: "yayonay-e7f58",
  storageBucket: "yayonay-e7f58.appspot.com",
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID
};

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: "yayonay-e7f58"
});

const db = admin.firestore();

// Define all required indexes
const requiredIndexes = [
  // Topics indexes
  {
    collectionGroup: "topics",
    queryScope: "COLLECTION",
    fields: [
      { fieldPath: "category", order: "ASCENDING" },
      { fieldPath: "date", order: "DESCENDING" }
    ]
  },
  {
    collectionGroup: "topics",
    queryScope: "COLLECTION",
    fields: [
      { fieldPath: "upvotes", order: "DESCENDING" }
    ]
  },

  // SubCategories indexes
  {
    collectionGroup: "subCategories",
    queryScope: "COLLECTION",
    fields: [
      { fieldPath: "yayCount", order: "DESCENDING" }
    ]
  },
  {
    collectionGroup: "subCategories",
    queryScope: "COLLECTION",
    fields: [
      { fieldPath: "categoryId", order: "ASCENDING" },
      { fieldPath: "order", order: "ASCENDING" }
    ]
  },

  // Comments indexes
  {
    collectionGroup: "comments",
    queryScope: "COLLECTION",
    fields: [
      { fieldPath: "subCategoryId", order: "ASCENDING" },
      { fieldPath: "date", order: "DESCENDING" }
    ]
  },
  {
    collectionGroup: "comments",
    queryScope: "COLLECTION",
    fields: [
      { fieldPath: "voteId", order: "ASCENDING" },
      { fieldPath: "date", order: "DESCENDING" }
    ]
  },

  // Votes indexes
  {
    collectionGroup: "votes",
    queryScope: "COLLECTION",
    fields: [
      { fieldPath: "date", order: "DESCENDING" }
    ]
  },
  {
    collectionGroup: "votes",
    queryScope: "COLLECTION",
    fields: [
      { fieldPath: "userId", order: "ASCENDING" },
      { fieldPath: "date", order: "DESCENDING" }
    ]
  }
];

async function createIndexes() {
  console.log('Starting to create indexes...');
  
  for (const index of requiredIndexes) {
    try {
      const indexName = `${index.collectionGroup}_${index.fields.map(f => `${f.fieldPath}_${f.order}`).join('_')}`;
      console.log(`Creating index: ${indexName}`);
      
      await db.collection('__indexes__').doc(indexName).set({
        queryScope: index.queryScope,
        fields: index.fields
      });
      
      console.log(`Successfully created index: ${indexName}`);
    } catch (error) {
      console.error(`Error creating index: ${error.message}`);
    }
  }
  
  console.log('Finished creating indexes');
  process.exit(0);
}

createIndexes(); 