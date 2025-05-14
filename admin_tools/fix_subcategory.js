import { initializeApp } from 'firebase/app';
import { getFirestore, doc, updateDoc, setDoc, Timestamp } from 'firebase/firestore';

// Firebase configuration
const firebaseConfig = {
    projectId: "yayonay-e7f58",
    appId: "1:1057578166868:web:08a14e5604180ddf5a9bc1",
    storageBucket: "yayonay-e7f58.firebasestorage.app",
    apiKey: "AIzaSyDXSbgxpk5oLMl4YmCtjEJy1AbMKgb4G1o",
    authDomain: "yayonay-e7f58.firebaseapp.com",
    messagingSenderId: "1057578166868",
    measurementId: "G-FQ115VP93E"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function fixSubcategory() {
  try {
    // Update root collection document
    const rootDocRef = doc(db, 'subcategories', 'qxypxVRuRiYbHWwdSdGt');
    await updateDoc(rootDocRef, {
      categoryId: 'p7MjbXbQPdYR5YP04zid',
      yayCount: 0,
      nayCount: 0
    });
    
    // Create nested document
    const nestedDocRef = doc(db, 'categories', 'p7MjbXbQPdYR5YP04zid', 'subcategories', 'qxypxVRuRiYbHWwdSdGt');
    await setDoc(nestedDocRef, {
      name: 'test',
      imageURL: 'https://via.placeholder.com/60',
      categoryId: 'p7MjbXbQPdYR5YP04zid',
      order: 1,
      yayCount: 0,
      nayCount: 0,
      createdAt: Timestamp.fromMillis(1747176758789),
      updatedAt: Timestamp.fromMillis(1747176758789)
    });
    
    console.log('✅ Successfully fixed subcategory');
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

fixSubcategory(); 