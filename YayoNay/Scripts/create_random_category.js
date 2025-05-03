const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createRandomCategory() {
  try {
    // Check if Random category already exists
    const randomCategoryRef = db.collection('categories').doc('random');
    const randomCategoryDoc = await randomCategoryRef.get();
    
    if (!randomCategoryDoc.exists) {
      // Create Random category
      await randomCategoryRef.set({
        name: 'Random',
        description: 'Discover and vote on random items from all categories',
        imageURL: 'https://example.com/random-category.jpg', // Replace with actual image URL
        isTopCategory: true,
        order: 0,
        featured: true,
        votesCount: 0
      });
      console.log('Created Random category');
    } else {
      console.log('Random category already exists');
    }

    // Get all subcategories
    const subcategoriesSnapshot = await db.collection('subcategories').get();
    const subcategories = subcategoriesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Create Random subcategories collection
    const randomSubcategoriesRef = db.collection('random_subcategories');
    
    // Add all subcategories to Random category
    for (const subcategory of subcategories) {
      const randomSubcategoryRef = randomSubcategoriesRef.doc(subcategory.id);
      const randomSubcategoryDoc = await randomSubcategoryRef.get();
      
      if (!randomSubcategoryDoc.exists) {
        await randomSubcategoryRef.set({
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
    }

    console.log('Random category setup completed successfully');
  } catch (error) {
    console.error('Error setting up Random category:', error);
  } finally {
    admin.app().delete();
  }
}

createRandomCategory(); 