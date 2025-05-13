const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');
const readline = require('readline');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

// Create interface for reading user input
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Helper function to ask questions
const question = (query) => new Promise((resolve) => rl.question(query, resolve));

// Main menu options
const MENU_OPTIONS = {
  '1': 'Add new category',
  '2': 'Add subcategory to existing category',
  '3': 'List all categories and subcategories',
  '4': 'Update category',
  '5': 'Update subcategory',
  '6': 'Delete category',
  '7': 'Delete subcategory',
  '8': 'Exit'
};

// Function to display the main menu
function displayMenu() {
  console.log('\n=== YayoNay Admin Tool ===');
  console.log('Choose an option:');
  Object.entries(MENU_OPTIONS).forEach(([key, value]) => {
    console.log(`${key}. ${value}`);
  });
}

// Function to add a new category
async function addCategory() {
  try {
    const name = await question('Enter category name: ');
    const imageURL = await question('Enter category image URL (or press Enter for default): ');
    const order = parseInt(await question('Enter display order number: '));

    const categoryData = {
      name,
      imageURL: imageURL || 'https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_category.png?alt=media',
      order,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection('categories').add(categoryData);
    console.log('✅ Category added successfully!');
  } catch (error) {
    console.error('❌ Error adding category:', error.message);
  }
}

// Function to add a subcategory
async function addSubcategory() {
  try {
    // First, list all categories
    const categories = await db.collection('categories').get();
    console.log('\nAvailable categories:');
    categories.forEach(doc => {
      console.log(`- ${doc.data().name} (ID: ${doc.id})`);
    });

    const categoryId = await question('\nEnter category ID: ');
    const name = await question('Enter subcategory name: ');
    const imageURL = await question('Enter subcategory image URL (or press Enter for default): ');
    const order = parseInt(await question('Enter display order number: '));

    const subcategoryData = {
      name,
      imageURL: imageURL || 'https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_subcategory.png?alt=media',
      order,
      categoryId,
      yayCount: 0,
      nayCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await db.collection('categories').doc(categoryId).collection('subcategories').add(subcategoryData);
    console.log('✅ Subcategory added successfully!');
  } catch (error) {
    console.error('❌ Error adding subcategory:', error.message);
  }
}

// Function to list all categories and subcategories
async function listAll() {
  try {
    const categories = await db.collection('categories').orderBy('order').get();
    console.log('\n=== Current Categories and Subcategories ===');
    
    for (const category of categories.docs) {
      const categoryData = category.data();
      console.log(`\n📁 ${categoryData.name} (Order: ${categoryData.order})`);
      
      const subcategories = await category.ref.collection('subcategories').orderBy('order').get();
      subcategories.forEach(subcat => {
        const subcatData = subcat.data();
        console.log(`  └─ 📑 ${subcatData.name} (Order: ${subcatData.order})`);
      });
    }
  } catch (error) {
    console.error('❌ Error listing categories:', error.message);
  }
}

// Function to update a category
async function updateCategory() {
  try {
    const categories = await db.collection('categories').get();
    console.log('\nAvailable categories:');
    categories.forEach(doc => {
      console.log(`- ${doc.data().name} (ID: ${doc.id})`);
    });

    const categoryId = await question('\nEnter category ID to update: ');
    const name = await question('Enter new name (or press Enter to skip): ');
    const imageURL = await question('Enter new image URL (or press Enter to skip): ');
    const orderStr = await question('Enter new order number (or press Enter to skip): ');

    const updateData = {};
    if (name) updateData.name = name;
    if (imageURL) updateData.imageURL = imageURL;
    if (orderStr) updateData.order = parseInt(orderStr);
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('categories').doc(categoryId).update(updateData);
    console.log('✅ Category updated successfully!');
  } catch (error) {
    console.error('❌ Error updating category:', error.message);
  }
}

// Function to update a subcategory
async function updateSubcategory() {
  try {
    const categories = await db.collection('categories').get();
    console.log('\nAvailable categories:');
    for (const category of categories.docs) {
      console.log(`\n${category.data().name} (ID: ${category.id})`);
      const subcategories = await category.ref.collection('subcategories').get();
      subcategories.forEach(subcat => {
        console.log(`  └─ ${subcat.data().name} (ID: ${subcat.id})`);
      });
    }

    const categoryId = await question('\nEnter category ID: ');
    const subcategoryId = await question('Enter subcategory ID to update: ');
    const name = await question('Enter new name (or press Enter to skip): ');
    const imageURL = await question('Enter new image URL (or press Enter to skip): ');
    const orderStr = await question('Enter new order number (or press Enter to skip): ');

    const updateData = {};
    if (name) updateData.name = name;
    if (imageURL) updateData.imageURL = imageURL;
    if (orderStr) updateData.order = parseInt(orderStr);
    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

    await db.collection('categories').doc(categoryId).collection('subcategories').doc(subcategoryId).update(updateData);
    console.log('✅ Subcategory updated successfully!');
  } catch (error) {
    console.error('❌ Error updating subcategory:', error.message);
  }
}

// Function to delete a category
async function deleteCategory() {
  try {
    const categories = await db.collection('categories').get();
    console.log('\nAvailable categories:');
    categories.forEach(doc => {
      console.log(`- ${doc.data().name} (ID: ${doc.id})`);
    });

    const categoryId = await question('\nEnter category ID to delete: ');
    const confirm = await question('Are you sure you want to delete this category? (yes/no): ');

    if (confirm.toLowerCase() === 'yes') {
      await db.collection('categories').doc(categoryId).delete();
      console.log('✅ Category deleted successfully!');
    } else {
      console.log('Deletion cancelled.');
    }
  } catch (error) {
    console.error('❌ Error deleting category:', error.message);
  }
}

// Function to delete a subcategory
async function deleteSubcategory() {
  try {
    const categories = await db.collection('categories').get();
    console.log('\nAvailable categories and subcategories:');
    for (const category of categories.docs) {
      console.log(`\n${category.data().name} (ID: ${category.id})`);
      const subcategories = await category.ref.collection('subcategories').get();
      subcategories.forEach(subcat => {
        console.log(`  └─ ${subcat.data().name} (ID: ${subcat.id})`);
      });
    }

    const categoryId = await question('\nEnter category ID: ');
    const subcategoryId = await question('Enter subcategory ID to delete: ');
    const confirm = await question('Are you sure you want to delete this subcategory? (yes/no): ');

    if (confirm.toLowerCase() === 'yes') {
      await db.collection('categories').doc(categoryId).collection('subcategories').doc(subcategoryId).delete();
      console.log('✅ Subcategory deleted successfully!');
    } else {
      console.log('Deletion cancelled.');
    }
  } catch (error) {
    console.error('❌ Error deleting subcategory:', error.message);
  }
}

// Main function to run the admin tool
async function main() {
  while (true) {
    displayMenu();
    const choice = await question('\nEnter your choice (1-8): ');

    switch (choice) {
      case '1':
        await addCategory();
        break;
      case '2':
        await addSubcategory();
        break;
      case '3':
        await listAll();
        break;
      case '4':
        await updateCategory();
        break;
      case '5':
        await updateSubcategory();
        break;
      case '6':
        await deleteCategory();
        break;
      case '7':
        await deleteSubcategory();
        break;
      case '8':
        console.log('Goodbye! 👋');
        rl.close();
        process.exit(0);
      default:
        console.log('Invalid option. Please try again.');
    }
  }
}

// Start the admin tool
console.log('Welcome to YayoNay Admin Tool! 🚀');
main().catch(error => {
  console.error('Error:', error);
  rl.close();
  process.exit(1);
}); 