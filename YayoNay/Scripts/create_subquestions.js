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
  "Drinks": [
    "Taste",
    "Quality",
    "Value",
    "Presentation",
    "Temperature",
    "Freshness"
  ],
  "Dessert": [
    "Taste",
    "Presentation",
    "Sweetness",
    "Texture",
    "Freshness",
    "Value"
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
  "Technology": [
    "Innovation",
    "Usability",
    "Design",
    "Performance",
    "Value",
    "Reliability"
  ],
  "Fashion": [
    "Style",
    "Quality",
    "Comfort",
    "Value",
    "Durability",
    "Trendiness"
  ],
  "Pets": [
    "Temperament",
    "Care Requirements",
    "Cost",
    "Space Needs",
    "Lifespan",
    "Family Friendly"
  ],
  "Home Decor": [
    "Style",
    "Quality",
    "Value",
    "Durability",
    "Functionality",
    "Aesthetics"
  ],
  "Fitness": [
    "Effectiveness",
    "Difficulty",
    "Equipment Needed",
    "Time Required",
    "Safety",
    "Results"
  ],
  "Gaming": [
    "Gameplay",
    "Graphics",
    "Story",
    "Controls",
    "Replay Value",
    "Multiplayer"
  ],
  "Beauty": [
    "Effectiveness",
    "Value",
    "Quality",
    "Packaging",
    "Ingredients",
    "Results"
  ],
  "Cars": [
    "Performance",
    "Design",
    "Comfort",
    "Reliability",
    "Value",
    "Features"
  ],
  "Photography": [
    "Composition",
    "Lighting",
    "Subject",
    "Technical Quality",
    "Creativity",
    "Impact"
  ],
  "Nature": [
    "Beauty",
    "Accessibility",
    "Conservation",
    "Activities",
    "Facilities",
    "Experience"
  ],
  "DIY": [
    "Difficulty",
    "Cost",
    "Time Required",
    "Results",
    "Instructions",
    "Materials Needed"
  ],
  "Politics": [
    "Impact",
    "Fairness",
    "Effectiveness",
    "Transparency",
    "Public Support",
    "Implementation"
  ],
  "Business": [
    "Innovation",
    "Profitability",
    "Sustainability",
    "Leadership",
    "Market Impact",
    "Growth Potential"
  ],
  "Entertainment": [
    "Entertainment Value",
    "Production Quality",
    "Originality",
    "Audience Engagement",
    "Value",
    "Replay Value"
  ],
  "General": [
    "Relevance",
    "Accuracy",
    "Impact",
    "Timeliness",
    "Quality",
    "Value"
  ],
  "Health": [
    "Effectiveness",
    "Safety",
    "Cost",
    "Accessibility",
    "Results",
    "Side Effects"
  ],
  "Lifestyle": [
    "Quality of Life",
    "Sustainability",
    "Cost",
    "Time Management",
    "Balance",
    "Satisfaction"
  ],
  "US": [
    "Impact",
    "Effectiveness",
    "Public Support",
    "Implementation",
    "Cost",
    "Benefits"
  ],
  "World": [
    "Global Impact",
    "International Relations",
    "Cultural Sensitivity",
    "Sustainability",
    "Effectiveness",
    "Long-term Effects"
  ],
  "Sports": [
    "Skill Level",
    "Entertainment Value",
    "Rules",
    "Equipment",
    "Accessibility",
    "Physical Benefits"
  ],
  "Art": [
    "Creativity",
    "Technique",
    "Impact",
    "Originality",
    "Presentation",
    "Message"
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
    let batch = db.batch();
    subQuestionsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log('Cleared existing subQuestions');
    
    // Create new subQuestions
    let count = 0;
    batch = db.batch();
    
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
          
          batch.set(subQuestionRef, subQuestion);
          count++;
          
          // Firestore has a limit of 500 operations per batch
          if (count % 450 === 0) {
            await batch.commit();
            console.log(`Committed batch of ${count} subQuestions`);
            count = 0;
            batch = db.batch(); // Create a new batch
          }
        }
      }
    }
    
    // Commit any remaining operations
    if (count > 0) {
      await batch.commit();
      console.log(`Committed final batch of ${count} subQuestions`);
    }
    
    console.log('Successfully created all subQuestions');
    
  } catch (error) {
    console.error('Error creating subQuestions:', error);
  }
}

// Run the function
createSubQuestions(); 