const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

// Initialize Firebase Admin with service account
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: "yayonay-e7f58"
});

const db = admin.firestore();

async function checkDatabaseState() {
    try {
        console.log('Checking database state...\n');

        // Check categories
        console.log('1. Categories in root collection:');
        const categoriesSnapshot = await db.collection('categories').get();
        console.log(`Total categories: ${categoriesSnapshot.size}`);
        
        for (const doc of categoriesSnapshot.docs) {
            const data = doc.data();
            console.log(`\nCategory: ${data.name} (${doc.id})`);
            console.log('Data:', data);

            // Check subcategories for this category
            const subcategoriesSnapshot = await doc.ref.collection('subcategories').get();
            console.log(`Subcategories under this category: ${subcategoriesSnapshot.size}`);
            
            subcategoriesSnapshot.forEach(subDoc => {
                console.log(`- Subcategory: ${subDoc.data().name} (${subDoc.id})`);
                console.log('  Data:', subDoc.data());
            });
        }

        // Check root subcategories collection
        console.log('\n2. Subcategories in root collection:');
        const rootSubcategoriesSnapshot = await db.collection('subcategories').get();
        console.log(`Total subcategories: ${rootSubcategoriesSnapshot.size}`);
        
        rootSubcategoriesSnapshot.forEach(doc => {
            const data = doc.data();
            console.log(`\nSubcategory: ${data.name} (${doc.id})`);
            console.log('Data:', data);
        });

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit(0);
    }
}

// Run the check
checkDatabaseState(); 