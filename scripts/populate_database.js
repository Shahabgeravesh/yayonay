const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define categories and their subcategories
const categories = [
  {
    name: "Food & Dining",
    imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800",
    isTopCategory: true,
    order: 1,
    description: "Vote on your favorite foods and dining experiences",
    subcategories: [
      "Restaurants",
      "Cafes",
      "Fast Food",
      "Fine Dining",
      "Food Trucks",
      "Bars & Pubs",
      "Bakeries",
      "Ice Cream Shops",
      "Food Courts",
      "Catering Services"
    ]
  },
  {
    name: "Entertainment",
    imageURL: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800",
    isTopCategory: true,
    order: 2,
    description: "Rate your entertainment experiences",
    subcategories: [
      "Movies",
      "Theaters",
      "Concerts",
      "Museums",
      "Art Galleries",
      "Amusement Parks",
      "Bowling Alleys",
      "Escape Rooms",
      "Arcades",
      "Comedy Clubs"
    ]
  },
  {
    name: "Shopping",
    imageURL: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=800",
    isTopCategory: true,
    order: 3,
    description: "Share your shopping experiences",
    subcategories: [
      "Clothing Stores",
      "Electronics",
      "Home Goods",
      "Bookstores",
      "Jewelry Stores",
      "Antique Shops",
      "Flea Markets",
      "Malls",
      "Outlet Stores",
      "Gift Shops"
    ]
  },
  {
    name: "Health & Wellness",
    imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800",
    isTopCategory: true,
    order: 4,
    description: "Rate health and wellness services",
    subcategories: [
      "Gyms",
      "Yoga Studios",
      "Spas",
      "Massage Centers",
      "Fitness Classes",
      "Health Food Stores",
      "Medical Clinics",
      "Dental Offices",
      "Physical Therapy",
      "Mental Health Services"
    ]
  },
  {
    name: "Travel & Tourism",
    imageURL: "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800",
    isTopCategory: true,
    order: 5,
    description: "Share your travel experiences",
    subcategories: [
      "Hotels",
      "Resorts",
      "Bed & Breakfasts",
      "Tourist Attractions",
      "Beaches",
      "National Parks",
      "Historical Sites",
      "Tour Guides",
      "Travel Agencies",
      "Cruise Lines"
    ]
  },
  {
    name: "Education",
    imageURL: "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800",
    isTopCategory: true,
    order: 6,
    description: "Rate educational institutions and services",
    subcategories: [
      "Schools",
      "Universities",
      "Libraries",
      "Tutoring Centers",
      "Language Schools",
      "Music Schools",
      "Art Classes",
      "Coding Bootcamps",
      "Professional Training",
      "Online Courses"
    ]
  },
  {
    name: "Technology",
    imageURL: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=800",
    isTopCategory: true,
    order: 7,
    description: "Rate tech products and services",
    subcategories: [
      "Smartphones",
      "Laptops",
      "Gaming Consoles",
      "Smart Home Devices",
      "Wearable Tech",
      "Software",
      "Apps",
      "Websites",
      "Tech Services",
      "Gadgets"
    ]
  },
  {
    name: "Sports & Recreation",
    imageURL: "https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800",
    isTopCategory: true,
    order: 8,
    description: "Rate sports and recreational activities",
    subcategories: [
      "Sports Teams",
      "Fitness Centers",
      "Swimming Pools",
      "Tennis Courts",
      "Golf Courses",
      "Hiking Trails",
      "Bike Paths",
      "Sports Equipment",
      "Sports Events",
      "Recreation Centers"
    ]
  },
  {
    name: "Home & Garden",
    imageURL: "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800",
    isTopCategory: true,
    order: 9,
    description: "Rate home and garden products and services",
    subcategories: [
      "Furniture Stores",
      "Home Decor",
      "Garden Centers",
      "Hardware Stores",
      "Interior Design",
      "Landscaping",
      "Home Services",
      "Cleaning Services",
      "Moving Companies",
      "Storage Solutions"
    ]
  },
  {
    name: "Beauty & Personal Care",
    imageURL: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800",
    isTopCategory: true,
    order: 10,
    description: "Rate beauty and personal care services",
    subcategories: [
      "Hair Salons",
      "Nail Salons",
      "Beauty Products",
      "Barber Shops",
      "Makeup Artists",
      "Skincare Clinics",
      "Tattoo Parlors",
      "Perfume Stores",
      "Beauty Supply",
      "Spa Services"
    ]
  }
];

// Common questions for all categories
const commonQuestions = [
  "How would you rate the overall quality?",
  "Is it worth the price?",
  "Would you recommend it to others?",
  "How is the customer service?",
  "How is the location/accessibility?",
  "How is the cleanliness/maintenance?",
  "How is the atmosphere/ambiance?",
  "How is the variety/selection?",
  "How is the value for money?",
  "Would you visit/use it again?"
];

// Category-specific questions
const categorySpecificQuestions = {
  "Food & Dining": [
    "How is the taste?",
    "How is the portion size?",
    "How is the presentation?",
    "How is the menu variety?",
    "How is the food freshness?"
  ],
  "Entertainment": [
    "How is the entertainment value?",
    "How is the production quality?",
    "How is the seating/viewing experience?",
    "How is the sound/visual quality?",
    "How is the duration/timing?"
  ],
  "Shopping": [
    "How is the product quality?",
    "How is the price range?",
    "How is the store layout?",
    "How is the product variety?",
    "How is the return policy?"
  ],
  "Health & Wellness": [
    "How is the service quality?",
    "How is the staff expertise?",
    "How is the facility cleanliness?",
    "How is the equipment quality?",
    "How is the appointment availability?"
  ],
  "Travel & Tourism": [
    "How is the location?",
    "How is the accommodation quality?",
    "How is the tourist information?",
    "How is the local transportation?",
    "How is the cultural experience?"
  ],
  "Education": [
    "How is the teaching quality?",
    "How is the curriculum?",
    "How is the learning environment?",
    "How is the student support?",
    "How is the course material?"
  ],
  "Technology": [
    "How is the performance?",
    "How is the user interface?",
    "How is the reliability?",
    "How is the battery life?",
    "How is the build quality?"
  ],
  "Sports & Recreation": [
    "How is the facility quality?",
    "How is the equipment condition?",
    "How is the staff knowledge?",
    "How is the safety measures?",
    "How is the booking system?"
  ],
  "Home & Garden": [
    "How is the product durability?",
    "How is the design quality?",
    "How is the installation process?",
    "How is the warranty coverage?",
    "How is the maintenance requirement?"
  ],
  "Beauty & Personal Care": [
    "How is the service quality?",
    "How is the product effectiveness?",
    "How is the staff expertise?",
    "How is the hygiene standards?",
    "How is the appointment system?"
  ]
};

async function populateDatabase() {
  try {
    console.log('Starting database population...');
    
    // Create categories and their subcategories
    for (const category of categories) {
      console.log(`Creating category: ${category.name}`);
      
      // Create category document
      const categoryRef = await db.collection('categories').add({
        name: category.name,
        imageURL: category.imageURL,
        isTopCategory: category.isTopCategory,
        order: category.order,
        description: category.description,
        active: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      console.log(`Created category with ID: ${categoryRef.id}`);
      
      // Create subcategories for this category
      for (let i = 0; i < category.subcategories.length; i++) {
        const subcategoryName = category.subcategories[i];
        console.log(`Creating subcategory: ${subcategoryName}`);
        
        const subcategoryRef = await db.collection('categories')
          .doc(categoryRef.id)
          .collection('subcategories')
          .add({
            name: subcategoryName,
            categoryId: categoryRef.id,
            order: i + 1,
            active: true,
            yayCount: 0,
            nayCount: 0,
            imageURL: category.imageURL, // Using category image as default
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            votesMetadata: {
              lastVoteAt: null,
              totalVotes: 0,
              uniqueVoters: 0
            }
          });
        
        console.log(`Created subcategory with ID: ${subcategoryRef.id}`);
        
        // Create subquestions for this subcategory
        const allQuestions = [
          ...commonQuestions,
          ...(categorySpecificQuestions[category.name] || [])
        ];
        
        for (let j = 0; j < allQuestions.length; j++) {
          const question = allQuestions[j];
          console.log(`Creating subquestion: ${question}`);
          
          await db.collection('categories')
            .doc(categoryRef.id)
            .collection('subcategories')
            .doc(subcategoryRef.id)
            .collection('subquestions')
            .add({
              categoryId: categoryRef.id,
              subCategoryId: subcategoryRef.id,
              question: question,
              order: j + 1,
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
            });
        }
      }
    }
    
    console.log('Database population completed successfully!');
  } catch (error) {
    console.error('Error populating database:', error);
  } finally {
    process.exit(0);
  }
}

// Run the population script
populateDatabase(); 