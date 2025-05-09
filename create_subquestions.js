const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

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
    "Presentation",
    "Quality",
    "Value",
    "Service",
    "Atmosphere"
  ],
  "Dessert": [
    "Taste",
    "Presentation",
    "Sweetness",
    "Texture",
    "Portion Size",
    "Value"
  ],
  "Sports": [
    "Skill Level",
    "Entertainment Value",
    "Athleticism",
    "Strategy",
    "Teamwork",
    "Competition"
  ],
  "Travel": [
    "Location",
    "Accessibility",
    "Cleanliness",
    "Atmosphere",
    "Facilities",
    "Value"
  ],
  "Art": [
    "Creativity",
    "Technique",
    "Originality",
    "Emotional Impact",
    "Aesthetics",
    "Message"
  ],
  "Music": [
    "Melody",
    "Lyrics",
    "Production",
    "Vocals",
    "Instrumentation",
    "Vibe"
  ],
  "Movies": [
    "Plot",
    "Acting",
    "Cinematography",
    "Soundtrack",
    "Pacing",
    "Ending"
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
    "Functionality",
    "Design",
    "Performance",
    "User Experience",
    "Innovation",
    "Value"
  ],
  "Fashion": [
    "Style",
    "Quality",
    "Fit",
    "Trendiness",
    "Versatility",
    "Value"
  ],
  "Pets": [
    "Temperament",
    "Trainability",
    "Health",
    "Grooming Needs",
    "Compatibility",
    "Lifespan"
  ],
  "Home Decor": [
    "Style",
    "Quality",
    "Functionality",
    "Aesthetics",
    "Durability",
    "Value"
  ],
  "Fitness": [
    "Effectiveness",
    "Difficulty",
    "Equipment Needs",
    "Time Commitment",
    "Results",
    "Enjoyment"
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
    "Quality",
    "Results",
    "Application",
    "Packaging",
    "Ingredients",
    "Value"
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
  ],
  "Nature": [
    "Beauty",
    "Accessibility",
    "Wildlife",
    "Conservation",
    "Educational Value",
    "Experience"
  ],
  "DIY": [
    "Difficulty",
    "Cost",
    "Time Required",
    "Results",
    "Learning Value",
    "Satisfaction"
  ],
  "Politics": [
    "Policy",
    "Leadership",
    "Integrity",
    "Communication",
    "Experience",
    "Vision"
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
      
      for (const question of questions) {
        const subQuestionRef = db.collection('subQuestions').doc();
        const subQuestion = {
          categoryId: categoryId,
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