const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');
const fs = require('fs');
const path = require('path');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Define required indexes for subQuestions
const indexes = {
  "indexes": [
    {
      "collectionGroup": "subQuestions",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "categoryId",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "subQuestions",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "yayCount",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "subQuestions",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "nayCount",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
};

// Write the indexes to firestore.indexes.json
const indexesPath = path.join(__dirname, '../../firestore.indexes.json');
fs.writeFileSync(indexesPath, JSON.stringify(indexes, null, 2));

console.log('Created firestore.indexes.json file');
console.log('To deploy these indexes, run:');
console.log('firebase deploy --only firestore:indexes'); 