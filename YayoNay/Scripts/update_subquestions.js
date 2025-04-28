const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateSubQuestions() {
  try {
    console.log('Starting to update subquestions...');

    // Get all subcategories first
    const subcategoriesSnapshot = await db.collection('subCategories').get();
    const subcategories = {};
    
    subcategoriesSnapshot.forEach(doc => {
      const data = doc.data();
      if (!subcategories[data.categoryId]) {
        subcategories[data.categoryId] = [];
      }
      subcategories[data.categoryId].push({
        id: doc.id,
        name: data.name
      });
    });

    // Get all subquestions
    const subquestionsSnapshot = await db.collection('subQuestions').get();
    let batch = db.batch();
    let updateCount = 0;
    let totalUpdates = 0;

    for (const doc of subquestionsSnapshot.docs) {
      const data = doc.data();
      const categoryId = data.categoryId;

      if (subcategories[categoryId] && subcategories[categoryId].length > 0) {
        // Assign this subquestion to all subcategories in its category
        for (const subcategory of subcategories[categoryId]) {
          // Create a new subquestion for each subcategory
          const newSubQuestionRef = db.collection('subQuestions').doc();
          batch.set(newSubQuestionRef, {
            ...data,
            subCategoryId: subcategory.id,
            question: data.question,
            yayCount: 0,
            nayCount: 0
          });
          updateCount++;
          totalUpdates++;
        }
        // Delete the original subquestion
        batch.delete(doc.ref);
      }

      // Commit batch when it gets close to the limit
      if (updateCount >= 400) {  // Firestore batch limit is 500
        await batch.commit();
        console.log(`Committed batch of ${updateCount} updates (Total: ${totalUpdates})`);
        batch = db.batch();  // Create a new batch
        updateCount = 0;
      }
    }

    // Commit any remaining updates
    if (updateCount > 0) {
      await batch.commit();
      console.log(`Committed final batch of ${updateCount} updates (Total: ${totalUpdates})`);
    }

    console.log(`Successfully updated all subquestions (Total: ${totalUpdates})`);
  } catch (error) {
    console.error('Error updating subquestions:', error);
  } finally {
    admin.app().delete();
  }
}

updateSubQuestions(); 