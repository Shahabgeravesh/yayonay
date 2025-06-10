const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define sub-questions for each category type
const categoryTypeQuestions = {
  "food": [
    "Taste",
    "Presentation",
    "Portion Size",
    "Value",
    "Service",
    "Ambiance"
  ],
  "beauty": [
    "Effectiveness",
    "Value",
    "Quality",
    "Packaging",
    "Ingredients",
    "Results"
  ],
  "travel": [
    "Location",
    "Accessibility",
    "Cleanliness",
    "Atmosphere",
    "Facilities",
    "Value"
  ],
  "sports": [
    "Skill Level",
    "Entertainment Value",
    "Rules",
    "Equipment",
    "Accessibility",
    "Physical Benefits"
  ],
  "entertainment": [
    "Entertainment Value",
    "Production Quality",
    "Originality",
    "Audience Engagement",
    "Value",
    "Replay Value"
  ],
  "education": [
    "Quality",
    "Effectiveness",
    "Accessibility",
    "Value",
    "Content",
    "Engagement"
  ],
  "health": [
    "Effectiveness",
    "Safety",
    "Cost",
    "Accessibility",
    "Results",
    "Side Effects"
  ],
  "shopping": [
    "Quality",
    "Value",
    "Selection",
    "Service",
    "Convenience",
    "Experience"
  ],
  "home": [
    "Style",
    "Quality",
    "Value",
    "Durability",
    "Functionality",
    "Aesthetics"
  ],
  "technology": [
    "Innovation",
    "Usability",
    "Design",
    "Performance",
    "Value",
    "Reliability"
  ]
};

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
        
        // Get questions based on category type
        const categoryName = categoryData.name.toLowerCase();
        let questions = [];
        
        // Map category names to their corresponding questions
        if (categoryName.includes('food') || categoryName.includes('dining')) {
            questions = categoryTypeQuestions['food'];
        } else if (categoryName.includes('beauty') || categoryName.includes('personal')) {
            questions = categoryTypeQuestions['beauty'];
        } else if (categoryName.includes('travel') || categoryName.includes('tourism')) {
            questions = categoryTypeQuestions['travel'];
        } else if (categoryName.includes('sports') || categoryName.includes('recreation')) {
            questions = categoryTypeQuestions['sports'];
        } else if (categoryName.includes('entertainment')) {
            questions = categoryTypeQuestions['entertainment'];
        } else if (categoryName.includes('education')) {
            questions = categoryTypeQuestions['education'];
        } else if (categoryName.includes('health') || categoryName.includes('wellness')) {
            questions = categoryTypeQuestions['health'];
        } else if (categoryName.includes('shopping')) {
            questions = categoryTypeQuestions['shopping'];
        } else if (categoryName.includes('home') || categoryName.includes('garden')) {
            questions = categoryTypeQuestions['home'];
        } else if (categoryName.includes('technology') || categoryName.includes('tech')) {
            questions = categoryTypeQuestions['technology'];
        } else {
            // Default questions if no match is found
            questions = [
                "Overall Quality",
                "Value",
                "Experience",
                "Service",
                "Atmosphere",
                "Recommendation"
            ];
        }
        
        // Create new subquestions
        for (let i = 0; i < questions.length; i++) {
          const subquestionRef = db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('subquestions')
            .doc();
            
          const subquestion = {
            categoryId: categoryId,
            subCategoryId: subcategoryId,
            question: questions[i],
            order: i + 1,
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
        console.log(`Created ${questions.length} subquestions for subcategory ${subcategoryData.name}`);
      }
    }
    
    console.log(`Successfully created ${totalSubquestions} subquestions`);
    
  } catch (error) {
    console.error('Error creating subquestions:', error);
  }
}

// Run the function
createSubQuestions(); 