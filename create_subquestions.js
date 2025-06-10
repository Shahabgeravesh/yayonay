const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Default questions that will be added to every subcategory
const defaultQuestions = [
  { question: "How would you rate this?", order: 1 },
  { question: "Would you recommend this?", order: 2 },
  { question: "Is this worth the price?", order: 3 },
  { question: "Would you use/do this again?", order: 4 },
  { question: "Is this better than alternatives?", order: 5 }
];

async function createSubQuestions() {
  try {
    console.log('Starting subquestions creation...');
    
    // Get all categories
    const categoriesSnapshot = await db.collection('categories').get();
    console.log(`Found ${categoriesSnapshot.size} categories`);
    
    let totalSubquestions = 0;
    
    // Process each category
    for (const categoryDoc of categoriesSnapshot.docs) {
      const categoryId = categoryDoc.id;
      const categoryData = categoryDoc.data();
      console.log(`Processing category: ${categoryData.name} (${categoryId})`);
      
      // Get subcategories for this category
      const subcategoriesSnapshot = await db.collection('categories')
        .doc(categoryId)
        .collection('subcategories')
        .get();
      
      console.log(`Found ${subcategoriesSnapshot.size} subcategories for category ${categoryData.name}`);
      
      // Process each subcategory
      for (const subcategoryDoc of subcategoriesSnapshot.docs) {
        const subcategoryId = subcategoryDoc.id;
        const subcategoryData = subcategoryDoc.data();
        console.log(`Processing subcategory: ${subcategoryData.name} (${subcategoryId})`);
        
        // Delete existing subquestions
        const existingSubquestionsSnapshot = await db.collection('categories')
          .doc(categoryId)
          .collection('subcategories')
          .doc(subcategoryId)
          .collection('subquestions')
          .get();
          
        const batch = db.batch();
        
        // Delete existing subquestions
        existingSubquestionsSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        
        // Create new subquestions
        for (const questionData of defaultQuestions) {
          const subquestionRef = db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('subquestions')
            .doc();
            
          const subquestion = {
            categoryId: categoryId,
            subCategoryId: subcategoryId,
            question: questionData.question,
            order: questionData.order,
            active: true,
            yayCount: 0,
            nayCount: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            votesMetadata: {
              lastVoteAt: null,
              totalVotes: 0,
              uniqueVoters: 0
            }
          };
          
          batch.set(subquestionRef, subquestion);
          totalSubquestions++;
        }
        
        // Commit the batch
        await batch.commit();
        console.log(`Created ${defaultQuestions.length} subquestions for subcategory ${subcategoryData.name}`);
      }
    }
    
    console.log(`Successfully created ${totalSubquestions} subquestions across all categories`);
    
  } catch (error) {
    console.error('Error creating subquestions:', error);
  }
}

// Run the function
createSubQuestions(); 