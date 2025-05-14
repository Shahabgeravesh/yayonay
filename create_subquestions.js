const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define sub-questions for each category
const categoryQuestions = {
  "Politics": [
    "Policy",
    "Leadership",
    "Integrity",
    "Communication",
    "Experience",
    "Vision"
  ],
  "TV Shows": [
    "Plot",
    "Acting",
    "Production",
    "Entertainment",
    "Character Development",
    "Pacing"
  ],
  "Business Test": [
    "Innovation",
    "Strategy",
    "Leadership",
    "Market Impact",
    "Growth",
    "Value"
  ],
  "Nature": [
    "Beauty",
    "Accessibility",
    "Wildlife",
    "Conservation",
    "Educational Value",
    "Experience"
  ],
  "Gaming": [
    "Gameplay",
    "Graphics",
    "Story",
    "Controls",
    "Replay Value",
    "Multiplayer"
  ],
  "Sport": [
    "Skill Level",
    "Entertainment Value",
    "Athleticism",
    "Strategy",
    "Teamwork",
    "Competition"
  ],
  "DIY": [
    "Difficulty",
    "Cost",
    "Time Required",
    "Results",
    "Learning Value",
    "Satisfaction"
  ],
  "Cars": [
    "Performance",
    "Design",
    "Comfort",
    "Reliability",
    "Features",
    "Value"
  ],
  "Photography": [
    "Composition",
    "Lighting",
    "Subject",
    "Technical Quality",
    "Creativity",
    "Impact"
  ]
};

async function createSubQuestions() {
  try {
    // First, get all categories to map names to IDs
    const categoriesSnapshot = await db.collection('categories').get();
    
    const categoryIdMap = {};
    categoriesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.name) {
        categoryIdMap[data.name] = doc.id;
      }
    });
    
    console.log('Found categories:', categoryIdMap);
    
    // Get all subcategories using the new nested structure
    const subCategories = {};
    for (const [categoryName, categoryId] of Object.entries(categoryIdMap)) {
      const subCategoriesSnapshot = await db.collection('categories')
        .doc(categoryId)
        .collection('subcategories')
        .get();
      
      subCategories[categoryId] = subCategoriesSnapshot.docs.map(doc => ({
        id: doc.id,
        name: doc.data().name
      }));
    }
    
    console.log('Found subcategories:', subCategories);
    
    // Create new subQuestions using nested structure
    let count = 0;
    
    for (const [categoryName, questions] of Object.entries(categoryQuestions)) {
      const categoryId = categoryIdMap[categoryName];
      if (!categoryId) {
        console.log(`No ID found for category: ${categoryName}`);
        continue;
      }
      
      const categorySubCategories = subCategories[categoryId] || [];
      console.log(`Creating sub-questions for ${categoryName} (${categorySubCategories.length} subcategories)`);
      
      for (const subCategory of categorySubCategories) {
        let batch = db.batch();
        
        // First, delete existing subquestions
        const existingSubQuestionsSnapshot = await db.collection('categories')
          .doc(categoryId)
          .collection('subcategories')
          .doc(subCategory.id)
          .collection('subquestions')
          .get();
          
        existingSubQuestionsSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        
        // Then create new subquestions using question text as document ID
      for (const question of questions) {
          const docId = question.toLowerCase().replace(/[^a-z0-9]/g, '_');
          const subQuestionRef = db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subCategory.id)
            .collection('subquestions')
            .doc(docId);
            
        const subQuestion = {
          categoryId: categoryId,
            subCategoryId: subCategory.id,
          question: question,
          yayCount: 0,
            nayCount: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            // Add metadata for votes subcollection
            votesMetadata: {
              lastVoteAt: null,
              totalVotes: 0,
              uniqueVoters: 0
            }
        };
        
          batch.set(subQuestionRef, subQuestion);
        count++;
          
          // Create votes subcollection with an example structure document
          const votesMetadataRef = subQuestionRef.collection('votes').doc('_metadata');
          batch.set(votesMetadataRef, {
            description: 'This collection stores individual votes. Each document ID is the user ID who voted.',
            schema: {
              userId: 'string',
              vote: 'boolean (true for yay, false for nay)',
              timestamp: 'timestamp',
              previousVote: 'boolean | null (for tracking vote changes)',
              lastChangeAt: 'timestamp | null'
            },
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        
        // Firestore has a limit of 500 operations per batch
        if (count % 450 === 0) {
            await batch.commit();
          console.log(`Committed batch of ${count} subQuestions`);
            count = 0;
            batch = db.batch(); // Create a new batch
          }
        }
        
        // Commit any remaining operations for this subcategory
        if (count > 0) {
          await batch.commit();
          console.log(`Committed batch of ${count} subQuestions for subcategory ${subCategory.name}`);
          count = 0;
        }
      }
    }
    
    console.log('Successfully created all subQuestions');
    
  } catch (error) {
    console.error('Error creating subQuestions:', error);
  }
}

// Run the function
createSubQuestions(); 