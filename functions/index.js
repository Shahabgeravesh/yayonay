const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Create a new item
exports.createItem = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }

    const data = req.body;
    const docRef = await admin.firestore().collection('items').add(data);
    
    return res.status(201).json({
      id: docRef.id,
      message: 'Item created successfully'
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// Get all items
exports.getItems = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'GET') {
      return res.status(405).send('Method Not Allowed');
    }

    const snapshot = await admin.firestore().collection('items').get();
    const items = [];
    snapshot.forEach(doc => {
      items.push({
        id: doc.id,
        ...doc.data()
      });
    });

    return res.status(200).json(items);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// Get a single item
exports.getItem = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'GET') {
      return res.status(405).send('Method Not Allowed');
    }

    const itemId = req.query.id;
    if (!itemId) {
      return res.status(400).json({ error: 'Item ID is required' });
    }

    const doc = await admin.firestore().collection('items').doc(itemId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Item not found' });
    }

    return res.status(200).json({
      id: doc.id,
      ...doc.data()
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// Update an item
exports.updateItem = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'PUT') {
      return res.status(405).send('Method Not Allowed');
    }

    const itemId = req.query.id;
    if (!itemId) {
      return res.status(400).json({ error: 'Item ID is required' });
    }

    const data = req.body;
    await admin.firestore().collection('items').doc(itemId).update(data);

    return res.status(200).json({
      message: 'Item updated successfully'
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

// Delete an item
exports.deleteItem = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'DELETE') {
      return res.status(405).send('Method Not Allowed');
    }

    const itemId = req.query.id;
    if (!itemId) {
      return res.status(400).json({ error: 'Item ID is required' });
    }

    await admin.firestore().collection('items').doc(itemId).delete();

    return res.status(200).json({
      message: 'Item deleted successfully'
    });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
}); 