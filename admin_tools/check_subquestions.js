const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkSubQuestions() {
    console.log('Checking subquestions in both root and nested collections...');
    
    try {
        // Check root collection
        const rootSubquestions = await db.collection('subQuestions').get();
        console.log(`\nRoot Collection (subQuestions):`);
        console.log(`Found ${rootSubquestions.size} subquestions`);
        
        if (rootSubquestions.size > 0) {
            console.log('\nSample subquestions from root collection:');
            rootSubquestions.docs.slice(0, 3).forEach(doc => {
                console.log(`- ${doc.id}: ${doc.data().question}`);
            });
        }
        
        // Check nested collections
        console.log('\nNested Collections (categories/{categoryId}/subcategories/{subcategoryId}/subquestions):');
        let totalNestedSubquestions = 0;
        let categoryCount = 0;
        let subcategoryCount = 0;
        
        const categories = await db.collection('categories').get();
        categoryCount = categories.size;
        
        for (const category of categories.docs) {
            const subcategories = await db.collection('categories')
                .doc(category.id)
                .collection('subcategories')
                .get();
            
            subcategoryCount += subcategories.size;
            
            for (const subcategory of subcategories.docs) {
                const subquestions = await db.collection('categories')
                    .doc(category.id)
                    .collection('subcategories')
                    .doc(subcategory.id)
                    .collection('subquestions')
                    .get();
                
                totalNestedSubquestions += subquestions.size;
            }
        }
        
        console.log(`Found ${totalNestedSubquestions} subquestions in nested collections`);
        console.log(`Across ${categoryCount} categories and ${subcategoryCount} subcategories`);
        
        // Print summary
        console.log('\nSummary:');
        console.log('--------');
        console.log(`Root collection subquestions: ${rootSubquestions.size}`);
        console.log(`Nested collection subquestions: ${totalNestedSubquestions}`);
        
        if (rootSubquestions.size === 0 && totalNestedSubquestions > 0) {
            console.log('\n✅ All subquestions are properly organized in the nested structure');
        } else if (rootSubquestions.size > 0) {
            console.log('\n⚠️ Found subquestions in both root and nested collections');
        } else {
            console.log('\n❌ No subquestions found in either collection');
        }
        
    } catch (error) {
        console.error('Error checking subquestions:', error);
    } finally {
        process.exit(0);
    }
}

// Run the check
checkSubQuestions(); 