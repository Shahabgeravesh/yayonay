const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

// Initialize Firebase Admin with service account
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: "yayonay-e7f58"
});

const db = admin.firestore();

async function fixTest2Subcategory() {
    try {
        console.log('Starting fix for test2 subcategory...\n');

        // Get the test2 subcategory from root
        const test2Doc = await db.collection('subcategories').doc('ddlG9Y14UuzmLchB9DKz').get();
        if (!test2Doc.exists) {
            console.log('❌ test2 subcategory not found in root collection');
            return;
        }

        const test2Data = test2Doc.data();
        console.log('Found test2 subcategory:', test2Data);

        // Create the subcategory in the nested structure
        const nestedData = {
            name: test2Data.name,
            imageURL: test2Data.imageURL,
            order: test2Data.order,
            categoryId: test2Data.categoryId,
            createdAt: test2Data.createdAt,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            yayCount: test2Data.yayCount || 0,
            nayCount: test2Data.nayCount || 0
        };

        await db.collection('categories')
            .doc(test2Data.categoryId)
            .collection('subcategories')
            .doc(test2Doc.id)
            .set(nestedData);
        console.log('✅ Created subcategory in nested structure');

        console.log('\n✨ Fix complete! The subcategory should now appear in the app.');
        
    } catch (error) {
        console.error('❌ Error:', error);
    } finally {
        process.exit(0);
    }
}

// Run the fix
fixTest2Subcategory(); 