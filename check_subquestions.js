const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function checkSubQuestions() {
  const categoryId = 'br5z6EL89FuHLqKvMXOI'; // Gaming category ID
  const subCategoryId = '8oHoF6knQ25qJAhVsbRg'; // Mobile Gaming subcategory ID
  
  const subQuestionsRef = db.collection('categories')
    .doc(categoryId)
    .collection('subcategories')
    .doc(subCategoryId)
    .collection('subquestions');
  
  const snapshot = await subQuestionsRef.get();
  console.log(`Found ${snapshot.size} subquestions`);
  snapshot.forEach(doc => {
    console.log('SubQuestion:', doc.data());
  });
}

checkSubQuestions(); 