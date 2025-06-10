const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateSubQuestions() {
    console.log('Starting subquestions migration to nested structure...');
    
    try {
        // Get all subquestions from root collection
        const rootSubquestions = await db.collection('subQuestions').get();
        console.log(`Found ${rootSubquestions.size} subquestions in root collection`);
        
        // Track statistics
        let migratedCount = 0;
        let errorCount = 0;
        let skippedCount = 0;
        
        // Process each subquestion
        for (const doc of rootSubquestions.docs) {
            const data = doc.data();
            const { categoryId, subCategoryId } = data;
            
            // Skip if missing required fields
            if (!categoryId || !subCategoryId) {
                console.log(`❌ Skipping subquestion ${doc.id}: Missing categoryId or subCategoryId`);
                skippedCount++;
                continue;
            }
            
            try {
                // Check if category exists
                const categoryDoc = await db.collection('categories').doc(categoryId).get();
                if (!categoryDoc.exists) {
                    console.log(`❌ Skipping subquestion ${doc.id}: Parent category ${categoryId} not found`);
                    skippedCount++;
                    continue;
                }
                
                // Check if subcategory exists
                const subcategoryDoc = await db.collection('categories')
                    .doc(categoryId)
                    .collection('subcategories')
                    .doc(subCategoryId)
                    .get();
                
                if (!subcategoryDoc.exists) {
                    console.log(`❌ Skipping subquestion ${doc.id}: Parent subcategory ${subCategoryId} not found`);
                    skippedCount++;
                    continue;
                }
                
                // Check if subquestion already exists in nested structure
                const existingSubquestion = await db.collection('categories')
                    .doc(categoryId)
                    .collection('subcategories')
                    .doc(subCategoryId)
                    .collection('subquestions')
                    .where('question', '==', data.question)
                    .get();
                
                if (!existingSubquestion.empty) {
                    console.log(`⏭️ Skipping subquestion ${doc.id}: Already exists in nested structure`);
                    skippedCount++;
                    continue;
                }
                
                // Create subquestion in nested structure
                await db.collection('categories')
                    .doc(categoryId)
                    .collection('subcategories')
                    .doc(subCategoryId)
                    .collection('subquestions')
                    .doc(doc.id)
                    .set({
                        ...data,
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                
                migratedCount++;
                console.log(`✅ Migrated subquestion: ${doc.id}`);
                
            } catch (error) {
                console.error(`❌ Error migrating subquestion ${doc.id}:`, error);
                errorCount++;
            }
        }
        
        // Print summary
        console.log('\nMigration Summary:');
        console.log('----------------');
        console.log(`Total subquestions processed: ${rootSubquestions.size}`);
        console.log(`Successfully migrated: ${migratedCount}`);
        console.log(`Skipped: ${skippedCount}`);
        console.log(`Errors encountered: ${errorCount}`);
        
        // Verify migration
        console.log('\nVerifying migration...');
        let nestedCount = 0;
        
        const categories = await db.collection('categories').get();
        for (const category of categories.docs) {
            const subcategories = await db.collection('categories')
                .doc(category.id)
                .collection('subcategories')
                .get();
            
            for (const subcategory of subcategories.docs) {
                const subquestions = await db.collection('categories')
                    .doc(category.id)
                    .collection('subcategories')
                    .doc(subcategory.id)
                    .collection('subquestions')
                    .get();
                
                nestedCount += subquestions.size;
            }
        }
        
        console.log('\nVerification Results:');
        console.log(`- Root collection count: ${rootSubquestions.size}`);
        console.log(`- Nested collections count: ${nestedCount}`);
        
        if (nestedCount >= rootSubquestions.size) {
            console.log('✅ Migration verification successful');
        } else {
            console.log('⚠️ Migration verification: Some subquestions may be missing');
        }
        
    } catch (error) {
        console.error('Error during migration:', error);
    } finally {
        process.exit(0);
    }
}

// Run the migration
migrateSubQuestions(); 