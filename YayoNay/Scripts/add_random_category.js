const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

async function addRandomCategory() {
  try {
    // Check if Random category already exists
    const randomCategoryRef = db.collection('categories').doc('random');
    const randomCategoryDoc = await randomCategoryRef.get();
    
    if (!randomCategoryDoc.exists) {
      // Create Random category
      await randomCategoryRef.set({
        name: 'Random',
        description: 'Discover and vote on random items from all categories',
        imageURL: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800',
        isTopCategory: true,
        order: 0, // This will make it appear at the top
        featured: true,
        votesCount: 0
      });
      console.log('Created Random category');
    } else {
      console.log('Random category already exists');
    }
  } catch (error) {
    console.error('Error adding Random category:', error);
  } finally {
    admin.app().delete();
  }
}

addRandomCategory(); 