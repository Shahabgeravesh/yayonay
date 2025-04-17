const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define 20 categories
const categories = [
  {
    name: "Food",
    description: "Discover delicious dishes",
    isTopCategory: true,
    order: 1,
    featured: true,
    votesCount: 0
  },
  {
    name: "Drinks",
    description: "Refreshing beverages",
    isTopCategory: true,
    order: 2,
    featured: true,
    votesCount: 0
  },
  {
    name: "Dessert",
    description: "Sweet treats and delights",
    isTopCategory: true,
    order: 3,
    featured: true,
    votesCount: 0
  },
  {
    name: "Sports",
    description: "Game on!",
    isTopCategory: true,
    order: 4,
    featured: true,
    votesCount: 0
  },
  {
    name: "Travel",
    description: "Explore destinations",
    isTopCategory: true,
    order: 5,
    featured: true,
    votesCount: 0
  },
  {
    name: "Art",
    description: "Creative expressions",
    isTopCategory: true,
    order: 6,
    featured: true,
    votesCount: 0
  },
  {
    name: "Music",
    description: "Rhythm and melodies",
    isTopCategory: true,
    order: 7,
    featured: true,
    votesCount: 0
  },
  {
    name: "Movies",
    description: "Cinematic experiences",
    isTopCategory: true,
    order: 8,
    featured: true,
    votesCount: 0
  },
  {
    name: "Books",
    description: "Literary adventures",
    isTopCategory: true,
    order: 9,
    featured: true,
    votesCount: 0
  },
  {
    name: "Technology",
    description: "Innovation and gadgets",
    isTopCategory: true,
    order: 10,
    featured: true,
    votesCount: 0
  },
  {
    name: "Fashion",
    description: "Style and trends",
    isTopCategory: false,
    order: 11,
    featured: false,
    votesCount: 0
  },
  {
    name: "Pets",
    description: "Furry friends and companions",
    isTopCategory: false,
    order: 12,
    featured: false,
    votesCount: 0
  },
  {
    name: "Home Decor",
    description: "Interior design and decoration",
    isTopCategory: false,
    order: 13,
    featured: false,
    votesCount: 0
  },
  {
    name: "Fitness",
    description: "Health and exercise",
    isTopCategory: false,
    order: 14,
    featured: false,
    votesCount: 0
  },
  {
    name: "Gaming",
    description: "Video games and entertainment",
    isTopCategory: false,
    order: 15,
    featured: false,
    votesCount: 0
  },
  {
    name: "Beauty",
    description: "Cosmetics and skincare",
    isTopCategory: false,
    order: 16,
    featured: false,
    votesCount: 0
  },
  {
    name: "Cars",
    description: "Automobiles and vehicles",
    isTopCategory: false,
    order: 17,
    featured: false,
    votesCount: 0
  },
  {
    name: "Photography",
    description: "Capturing moments",
    isTopCategory: false,
    order: 18,
    featured: false,
    votesCount: 0
  },
  {
    name: "Nature",
    description: "Outdoor and wildlife",
    isTopCategory: false,
    order: 19,
    featured: false,
    votesCount: 0
  },
  {
    name: "DIY",
    description: "Do it yourself projects",
    isTopCategory: false,
    order: 20,
    featured: false,
    votesCount: 0
  },
  {
    name: "Politics",
    description: "Political discussions and debates",
    isTopCategory: true,
    order: 21,
    featured: true,
    votesCount: 0
  }
];

// Add categories to Firestore
async function addCategories() {
  console.log("Adding categories to Firestore...");
  
  // First, delete all existing categories
  const existingCategories = await db.collection('categories').get();
  const batch = db.batch();
  existingCategories.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();
  console.log("Deleted existing categories");

  // Now add the new categories
  for (const category of categories) {
    try {
      await db.collection('categories').add(category);
      console.log(`Successfully added category: ${category.name}`);
    } catch (error) {
      console.error(`Error adding category ${category.name}:`, error);
    }
  }
  
  console.log("Finished adding categories.");
  process.exit(0);
}

addCategories(); 