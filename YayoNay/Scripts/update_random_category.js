const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateRandomCategory() {
  try {
    // Get all subcategories
    const subcategoriesSnapshot = await db.collection('subcategories').get();
    const subcategories = subcategoriesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Get current random subcategories
    const randomSubcategoriesSnapshot = await db.collection('random_subcategories').get();
    const currentRandomSubcategories = randomSubcategoriesSnapshot.docs.map(doc => doc.id);

    // Create Random subcategories collection
    const randomSubcategoriesRef = db.collection('random_subcategories');
    
    // Remove old subcategories
    for (const doc of randomSubcategoriesSnapshot.docs) {
      await doc.ref.delete();
      console.log(`Removed ${doc.data().name} from Random category`);
    }

    // Add new random selection of subcategories
    const shuffledSubcategories = [...subcategories].sort(() => Math.random() - 0.5);
    const selectedSubcategories = shuffledSubcategories.slice(0, 20); // Select 20 random subcategories

    for (const subcategory of selectedSubcategories) {
      await randomSubcategoriesRef.doc(subcategory.id).set({
        name: subcategory.name,
        imageURL: subcategory.imageURL,
        categoryId: 'random',
        order: Math.floor(Math.random() * 1000), // Random order
        yayCount: 0,
        nayCount: 0,
        attributes: subcategory.attributes || {},
        originalCategoryId: subcategory.categoryId // Keep track of original category
      });
      console.log(`Added ${subcategory.name} to Random category`);
    }

    console.log('Random category update completed successfully');
  } catch (error) {
    console.error('Error updating Random category:', error);
  } finally {
    admin.app().delete();
  }
}

updateRandomCategory(); 