const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, getDocs } = require('firebase/firestore');

// Your Firebase configuration
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: "yayonay-e7f58.firebaseapp.com",
  projectId: "yayonay-e7f58",
  storageBucket: "yayonay-e7f58.appspot.com",
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const categories = [
  {
    name: "Food",
    description: "Share your favorite dishes and restaurants",
    isTopCategory: true,
    order: 1,
    featured: true,
    votesCount: 0
  },
  {
    name: "Drinks",
    description: "Rate your favorite beverages",
    isTopCategory: true,
    order: 2,
    featured: true,
    votesCount: 0
  },
  {
    name: "Dessert",
    description: "Sweet treats and desserts",
    isTopCategory: true,
    order: 3,
    featured: true,
    votesCount: 0
  },
  {
    name: "Sports",
    description: "Sports events and teams",
    isTopCategory: true,
    order: 4,
    featured: true,
    votesCount: 0
  },
  {
    name: "Travel",
    description: "Travel destinations and experiences",
    isTopCategory: true,
    order: 5,
    featured: true,
    votesCount: 0
  },
  {
    name: "Art",
    description: "Art exhibitions and galleries",
    isTopCategory: true,
    order: 6,
    featured: true,
    votesCount: 0
  },
  {
    name: "Music",
    description: "Music albums and concerts",
    isTopCategory: true,
    order: 7,
    featured: true,
    votesCount: 0
  },
  {
    name: "Movies",
    description: "Movies and TV shows",
    isTopCategory: true,
    order: 8,
    featured: true,
    votesCount: 0
  },
  {
    name: "Books",
    description: "Books and literature",
    isTopCategory: true,
    order: 9,
    featured: true,
    votesCount: 0
  },
  {
    name: "Technology",
    description: "Tech products and innovations",
    isTopCategory: true,
    order: 10,
    featured: true,
    votesCount: 0
  },
  {
    name: "Politics",
    description: "Political events and discussions",
    isTopCategory: true,
    order: 11,
    featured: true,
    votesCount: 0
  }
];

async function createCategories() {
  try {
    // Check if categories already exist
    const categoriesRef = collection(db, 'categories');
    const snapshot = await getDocs(categoriesRef);
    
    if (snapshot.empty) {
      console.log('No existing categories found. Creating new categories...');
      
      // Add each category
      for (const category of categories) {
        await addDoc(categoriesRef, category);
        console.log(`Added category: ${category.name}`);
      }
      
      console.log('All categories have been created successfully!');
    } else {
      console.log('Categories already exist in the database.');
    }
  } catch (error) {
    console.error('Error creating categories:', error);
  }
}

// Run the function
createCategories(); 
