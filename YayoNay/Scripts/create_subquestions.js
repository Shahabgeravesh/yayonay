const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define sub-questions for each category
const categoryQuestions = {
  "Food": [
    "Taste",
    "Presentation",
    "Portion Size",
    "Value",
    "Service",
    "Ambiance"
  ],
  "Movies": [
    "Plot",
    "Acting",
    "Cinematography",
    "Soundtrack",
    "Pacing",
    "Ending"
  ],
  "Music": [
    "Melody",
    "Lyrics",
    "Production",
    "Vocals",
    "Instrumentation",
    "Vibe"
  ],
  "Books": [
    "Writing Style",
    "Character Development",
    "Plot",
    "Pacing",
    "World Building",
    "Ending"
  ],
  "Gaming": [
    "Gameplay",
    "Graphics",
    "Story",
    "Controls",
    "Replay Value",
    "Multiplayer"
  ],
  "Travel": [
    "Location",
    "Accessibility",
    "Cleanliness",
    "Atmosphere",
    "Facilities",
    "Value"
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
    
    // Get all subcategories
    const subCategoriesSnapshot = await db.collection('subCategories').get();
    const subCategories = {};
    subCategoriesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.categoryId && data.name) {
        if (!subCategories[data.categoryId]) {
          subCategories[data.categoryId] = [];
        }
        subCategories[data.categoryId].push({
          id: doc.id,
          name: data.name
        });
      }
    });
    
    console.log('Found subcategories:', subCategories);
    
    // Clear existing subQuestions
    const subQuestionsSnapshot = await db.collection('subQuestions').get();
    const batch = db.batch();
    subQuestionsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log('Cleared existing subQuestions');
    
    // Create new subQuestions
    const newBatch = db.batch();
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
      for (const question of questions) {
        const subQuestionRef = db.collection('subQuestions').doc();
        const subQuestion = {
          categoryId: categoryId,
            subCategoryId: subCategory.id,
          question: question,
          yayCount: 0,
          nayCount: 0
        };
        
        newBatch.set(subQuestionRef, subQuestion);
        count++;
        
        // Firestore has a limit of 500 operations per batch
        if (count % 450 === 0) {
          await newBatch.commit();
          console.log(`Committed batch of ${count} subQuestions`);
          count = 0;
          }
        }
      }
    }
    
    // Commit any remaining operations
    if (count > 0) {
      await newBatch.commit();
      console.log(`Committed final batch of ${count} subQuestions`);
    }
    
    console.log('Successfully created all subQuestions');
    
  } catch (error) {
    console.error('Error creating subQuestions:', error);
  }
}

// Run the function
createSubQuestions(); 