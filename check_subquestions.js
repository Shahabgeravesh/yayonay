const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function checkSubQuestions() {
  try {
    console.log('Checking all subquestions...');
    
    // Get all categories
    const categoriesSnapshot = await db.collection('categories').get();
    console.log(`Found ${categoriesSnapshot.size} categories`);
    
    for (const categoryDoc of categoriesSnapshot.docs) {
      const categoryId = categoryDoc.id;
      const categoryData = categoryDoc.data();
      console.log(`\nCategory: ${categoryData.name} (${categoryId})`);
      
      // Get subcategories
      const subcategoriesSnapshot = await db.collection('categories')
        .doc(categoryId)
        .collection('subcategories')
        .get();
      
      console.log(`Found ${subcategoriesSnapshot.size} subcategories`);
      
      for (const subcategoryDoc of subcategoriesSnapshot.docs) {
        const subcategoryId = subcategoryDoc.id;
        const subcategoryData = subcategoryDoc.data();
        console.log(`\nSubcategory: ${subcategoryData.name} (${subcategoryId})`);
        
        // Get subquestions
        const subquestionsSnapshot = await db.collection('categories')
          .doc(categoryId)
          .collection('subcategories')
          .doc(subcategoryId)
          .collection('subquestions')
          .get();
        
        console.log(`Found ${subquestionsSnapshot.size} subquestions:`);
        subquestionsSnapshot.forEach(doc => {
          const data = doc.data();
          console.log(`- ${data.question} (Order: ${data.order}, Active: ${data.active})`);
        });
      }
    }
  } catch (error) {
    console.error('Error checking subquestions:', error);
  }
}

// Run the check
checkSubQuestions(); 