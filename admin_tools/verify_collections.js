// Import Firebase modules
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs } from 'firebase/firestore';

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

async function verifyCollections() {
    console.log('Verifying collections...');
    
    try {
        // Check separate subCategories collection
        const subCategoriesSnapshot = await getDocs(collection(db, 'subcategories'));
        console.log(`\nSeparate subcategories collection:`);
        console.log(`- Document count: ${subCategoriesSnapshot.size}`);
        if (!subCategoriesSnapshot.empty) {
            const firstDoc = subCategoriesSnapshot.docs[0];
            console.log('- First document ID:', firstDoc.id);
            console.log('- First document data:', firstDoc.data());
        }

        // Check nested subcategories
        const categoriesSnapshot = await getDocs(collection(db, 'categories'));
        console.log(`\nNested subcategories structure:`);
        console.log(`- Categories count: ${categoriesSnapshot.size}`);
        
        let totalNestedSubCategories = 0;
        for (const categoryDoc of categoriesSnapshot.docs) {
            const subCategoriesSnapshot = await getDocs(collection(db, `categories/${categoryDoc.id}/subcategories`));
            totalNestedSubCategories += subCategoriesSnapshot.size;
            console.log(`\nCategory: ${categoryDoc.id}`);
            console.log(`- Name: ${categoryDoc.data().name}`);
            console.log(`- Subcategories count: ${subCategoriesSnapshot.size}`);
            if (!subCategoriesSnapshot.empty) {
                const firstDoc = subCategoriesSnapshot.docs[0];
                console.log('- First subcategory ID:', firstDoc.id);
                console.log('- First subcategory data:', firstDoc.data());
            }
        }
        
        console.log(`\nTotal nested subcategories: ${totalNestedSubCategories}`);

    } catch (error) {
        console.error('Error during verification:', error);
    }
}

verifyCollections(); 