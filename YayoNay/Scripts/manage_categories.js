const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define all categories with their order and image URLs
const categories = [
  { 
    name: "Discover Hub", 
    order: 0, 
    imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800",
    isTopCategory: true,
    description: "All content",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Fashion", 
    order: 1, 
    imageURL: "https://images.unsplash.com/photo-1445208345000-3c1a1c3b8d1a?w=800",
    isTopCategory: true,
    description: "Style and trends",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Pets", 
    order: 2, 
    imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800",
    isTopCategory: true,
    description: "Furry friends and companions",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Home Decor", 
    order: 3, 
    imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800",
    isTopCategory: true,
    description: "Interior design and decoration",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Fitness", 
    order: 4, 
    imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800",
    isTopCategory: true,
    description: "Health and exercise",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Gaming", 
    order: 5, 
    imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800",
    isTopCategory: true,
    description: "Video games and entertainment",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Beauty", 
    order: 6, 
    imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800",
    isTopCategory: true,
    description: "Cosmetics and skincare",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Cars", 
    order: 7, 
    imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800",
    isTopCategory: true,
    description: "Automobiles and vehicles",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Photography", 
    order: 8, 
    imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800",
    isTopCategory: true,
    description: "Capturing moments",
    featured: true,
    votesCount: 0
  },
  { 
    name: "Nature", 
    order: 9, 
    imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800",
    isTopCategory: true,
    description: "Outdoor and wildlife",
    featured: true,
    votesCount: 0
  },
  { 
    name: "DIY", 
    order: 10, 
    imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800",
    isTopCategory: true,
    description: "Do it yourself projects",
    featured: true,
    votesCount: 0
  }
];

// Define subcategories for each category
const categorySubcategories = {
  "Fashion": [
    { name: "Streetwear", imageURL: "https://images.unsplash.com/photo-1445208345000-3c1a1c3b8d1a?w=800" },
    { name: "Formal", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" },
    { name: "Casual", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" },
    { name: "Athletic", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" },
    { name: "Vintage", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" },
    { name: "Luxury", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" },
    { name: "Accessories", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" },
    { name: "Footwear", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" },
    { name: "Jewelry", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" },
    { name: "Bags", imageURL: "https://images.unsplash.com/photo-1593032465175-8d1a0b1c4b1a?w=800" }
  ],
  "Pets": [
    { name: "Dogs", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Cats", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Birds", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Fish", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Reptiles", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Small Animals", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Horses", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Exotic Pets", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Pet Care", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" },
    { name: "Pet Training", imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800" }
  ],
  "Home Decor": [
    { name: "Living Room", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Bedroom", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Kitchen", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Bathroom", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Outdoor", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Lighting", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Furniture", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Wall Art", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Rugs", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" },
    { name: "Storage", imageURL: "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=800" }
  ],
  "Fitness": [
    { name: "Cardio", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "Strength Training", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "Yoga", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "Pilates", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "HIIT", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "CrossFit", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "Running", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "Cycling", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "Swimming", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" },
    { name: "Dance", imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800" }
  ],
  "Gaming": [
    { name: "PC Gaming", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "Console Gaming", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "Mobile Gaming", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "VR Gaming", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "Indie Games", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "RPGs", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "FPS", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "Strategy", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "Sports", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" },
    { name: "Racing", imageURL: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800" }
  ],
  "Beauty": [
    { name: "Skincare", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Makeup", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Haircare", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Fragrance", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Nails", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Body Care", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Natural Beauty", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Men's Grooming", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Tools & Accessories", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" },
    { name: "Beauty Treatments", imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800" }
  ],
  "Cars": [
    { name: "Sedans", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "SUVs", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "Trucks", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "Sports Cars", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "Luxury", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "Electric", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "Hybrid", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "Classic", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "Performance", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" },
    { name: "Off-Road", imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800" }
  ],
  "Photography": [
    { name: "Portrait", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Landscape", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Street", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Wildlife", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Macro", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Architecture", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Event", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Fashion", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Food", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" },
    { name: "Travel", imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800" }
  ],
  "Nature": [
    { name: "Mountains", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Forests", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Oceans", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Deserts", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Wildlife", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Flowers", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Trees", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Weather", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Conservation", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" },
    { name: "Gardening", imageURL: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800" }
  ],
  "DIY": [
    { name: "Woodworking", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Home Improvement", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Crafts", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Furniture", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Electronics", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Automotive", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Gardening", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Sewing", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Painting", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" },
    { name: "Upcycling", imageURL: "https://images.unsplash.com/photo-1581094794329-1c1c5a0c0d9a?w=800" }
  ]
};

async function createCategories() {
  try {
    // Get existing categories to find the next available order number
    const categoriesSnapshot = await db.collection('categories').get();
    let maxOrder = 0;
    const existingCategories = new Set();
    
    categoriesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.order > maxOrder) {
        maxOrder = data.order;
      }
      existingCategories.add(data.name);
    });
    
    // Create new categories
    const batch = db.batch();
    let count = 0;
    
    for (const category of categories) {
      // Skip if category already exists
      if (existingCategories.has(category.name)) {
        console.log(`Category ${category.name} already exists, skipping...`);
        continue;
      }

      // Use fixed document ID for Discover Hub category
      const categoryRef = category.name === "Discover Hub" 
        ? db.collection('categories').doc('random')
        : db.collection('categories').doc();
        
      const categoryData = {
        name: category.name,
        order: maxOrder + category.order,
        imageURL: category.imageURL,
        isTopCategory: category.isTopCategory,
        description: category.description,
        featured: category.featured,
        votesCount: category.votesCount
      };
      
      batch.set(categoryRef, categoryData);
      count++;
      
      // Firestore has a limit of 500 operations per batch
      if (count % 450 === 0) {
        await batch.commit();
        console.log(`Committed batch of ${count} categories`);
        count = 0;
      }
    }
    
    // Commit any remaining operations
    if (count > 0) {
      await batch.commit();
      console.log(`Committed final batch of ${count} categories`);
    }
    
    console.log('Successfully created all categories');
    
  } catch (error) {
    console.error('Error creating categories:', error);
  }
}

async function createSubcategories() {
  try {
    // Get all categories to map names to IDs
    const categoriesSnapshot = await db.collection('categories').get();
    
    const categoryIdMap = {};
    categoriesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.name) {
        categoryIdMap[data.name] = doc.id;
      }
    });
    
    console.log('Found categories:', categoryIdMap);
    
    // Get existing subcategories to avoid duplicates
    const subcategoriesSnapshot = await db.collection('subCategories').get();
    const existingSubcategories = new Set();
    
    subcategoriesSnapshot.forEach(doc => {
      const data = doc.data();
      existingSubcategories.add(`${data.categoryId}-${data.name}`);
    });
    
    // Create new subcategories
    let batch = db.batch();
    let count = 0;
    
    for (const [categoryName, subcategories] of Object.entries(categorySubcategories)) {
      const categoryId = categoryIdMap[categoryName];
      if (!categoryId) {
        console.log(`No ID found for category: ${categoryName}`);
        continue;
      }
      
      console.log(`Creating subcategories for ${categoryName}`);
      
      for (let i = 0; i < subcategories.length; i++) {
        const subcategory = subcategories[i];
        // Skip if subcategory already exists
        const subcategoryKey = `${categoryId}-${subcategory.name}`;
        if (existingSubcategories.has(subcategoryKey)) {
          console.log(`Subcategory ${subcategory.name} already exists for ${categoryName}, skipping...`);
          continue;
        }

        const subcategoryRef = db.collection('subCategories').doc();
        const subcategoryData = {
          categoryId: categoryId,
          name: subcategory.name,
          imageURL: subcategory.imageURL,
          order: i, // Add order based on array index
          yayCount: 0, // Initialize yayCount
          nayCount: 0, // Initialize nayCount
          attributes: {} // Initialize empty attributes object
        };
        
        batch.set(subcategoryRef, subcategoryData);
        count++;
        
        // Firestore has a limit of 500 operations per batch
        if (count % 450 === 0) {
          await batch.commit();
          console.log(`Committed batch of ${count} subcategories`);
          batch = db.batch(); // Create a new batch
          count = 0;
        }
      }
    }
    
    // Commit any remaining operations
    if (count > 0) {
      await batch.commit();
      console.log(`Committed final batch of ${count} subcategories`);
    }
    
    console.log('Successfully created all subcategories');
    
  } catch (error) {
    console.error('Error creating subcategories:', error);
  }
}

async function populateDiscoverHubSubcategories() {
  try {
    console.log('Starting to populate discover hub subcategories...');
    
    // Clear existing discover hub subcategories
    const discoverHubSubcategoriesSnapshot = await db.collection('random_subcategories').get();
    console.log(`Found ${discoverHubSubcategoriesSnapshot.size} existing discover hub subcategories`);
    
    const batch = db.batch();
    discoverHubSubcategoriesSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log('Cleared existing discover hub subcategories');
    
    // Create new discover hub subcategories
    const subcategoriesSnapshot = await db.collection('subcategories').get();
    const subcategories = subcategoriesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    // Use ALL subcategories for Discover Hub
    const selectedSubcategories = subcategories;
    console.log(`Selected ${selectedSubcategories.length} discover hub subcategories`);
    
    let count = 0;
    let newBatch = db.batch();
    
    for (const subcategory of selectedSubcategories) {
      const discoverHubSubcategoryRef = db.collection('random_subcategories').doc(subcategory.id);
      const discoverHubSubcategoryData = {
        name: subcategory.name,
        imageURL: subcategory.imageURL,
        categoryId: 'random',
        order: Math.floor(Math.random() * 1000), // Random order
        yayCount: 0,
        nayCount: 0,
        attributes: subcategory.attributes || {},
        originalCategoryId: subcategory.categoryId // Keep track of original category
      };
      
      newBatch.set(discoverHubSubcategoryRef, discoverHubSubcategoryData);
      count++;
      
      if (count % 500 === 0) {
        await newBatch.commit();
        console.log(`Committed batch of ${count} discover hub subcategories`);
        newBatch = db.batch();
      }
    }
    
    if (count % 500 !== 0) {
      await newBatch.commit();
      console.log(`Committed final batch of ${count % 500} discover hub subcategories`);
    }
    
    console.log('Discover hub subcategories population completed successfully');
  } catch (error) {
    console.error('Error populating discover hub subcategories:', error);
  }
}

// Main function to run the script
async function main() {
  try {
    // First create categories
    await createCategories();
    
    // Then create subcategories
    await createSubcategories();
    
    // Finally populate discover hub subcategories
    await populateDiscoverHubSubcategories();
    
    console.log('All operations completed successfully');
  } catch (error) {
    console.error('Error in main function:', error);
  }
}

// Run the main function
main(); 