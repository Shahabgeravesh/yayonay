const fs = require('fs');
const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log('This script will help you download your Firebase service account key.');
console.log('Follow these steps:');
console.log('1. Go to the Firebase Console (https://console.firebase.google.com/)');
console.log('2. Select your project "yayonay-e7f58"');
console.log('3. Click on the gear icon (⚙️) next to "Project Overview" to open Project settings');
console.log('4. Go to the "Service accounts" tab');
console.log('5. Click "Generate new private key" button');
console.log('6. Save the downloaded JSON file as "serviceAccountKey.json" in this directory');
console.log('\nAfter downloading the file, press Enter to continue...');

rl.question('', () => {
  if (fs.existsSync('./serviceAccountKey.json')) {
    console.log('Great! The serviceAccountKey.json file was found.');
    console.log('Now you can run the add_categories.js script with:');
    console.log('node add_categories.js');
  } else {
    console.log('The serviceAccountKey.json file was not found in the current directory.');
    console.log('Please make sure you downloaded it and placed it in this directory.');
  }
  rl.close();
}); 