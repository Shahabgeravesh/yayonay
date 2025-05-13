// add_dummy_category_and_subcategories.js
// Usage: node add_dummy_category_and_subcategories.js

const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const categoryName = 'Business Test';
const categoryImageURL = 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800';
const categoryDescription = 'A test category for business topics';

async function deleteCategoryAndSubcollections(categoryId) {
  // Delete subcategories subcollection
  const subcatsSnap = await db.collection('categories').doc(categoryId).collection('subcategories').get();
  for (const doc of subcatsSnap.docs) {
    await doc.ref.delete();
    console.log(`Deleted subcategory: ${doc.id}`);
  }
  // Delete the category itself
  await db.collection('categories').doc(categoryId).delete();
  console.log(`Deleted category: ${categoryId}`);
}

async function createCategoryAndDummies() {
  // Find the category by name
  const catSnap = await db.collection('categories').where('name', '==', categoryName).get();
  let categoryId;
  if (!catSnap.empty) {
    categoryId = catSnap.docs[0].id;
    await deleteCategoryAndSubcollections(categoryId);
  }
  // Create new category
  const newCatRef = db.collection('categories').doc();
  categoryId = newCatRef.id;
  await newCatRef.set({
    name: categoryName,
    imageURL: categoryImageURL,
    order: 99,
    isTopCategory: false,
    description: categoryDescription,
    featured: false,
    votesCount: 0
  });
  console.log(`Created new category: ${categoryId}`);
  // Add dummy subcategories
  const dummies = [
    {
      name: 'Dummy Subcategory 1',
      imageURL: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
      order: 0,
      yayCount: 0,
      nayCount: 0
    },
    {
      name: 'Dummy Subcategory 2',
      imageURL: 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?w=800',
      order: 1,
      yayCount: 0,
      nayCount: 0
    },
    {
      name: 'Dummy Subcategory 3',
      imageURL: 'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800',
      order: 2,
      yayCount: 0,
      nayCount: 0
    }
  ];
  for (const dummy of dummies) {
    await db.collection('categories').doc(categoryId).collection('subcategories').add({
      ...dummy,
      categoryId
    });
    console.log(`Added dummy subcategory: ${dummy.name}`);
  }
  console.log('Done!');
}

createCategoryAndDummies().catch(console.error); 