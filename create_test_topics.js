const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const testTopics = [
  {
    title: "Should AI be regulated?",
    description: "Discussing the implications of AI regulation on innovation and safety",
    tags: ["#AI", "#Technology", "#Regulation"],
    category: "Technology",
    optionA: "Yes, regulate AI",
    optionB: "No, keep it free",
    mediaURL: "https://example.com/ai-image.jpg",
    userImage: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
    userId: "test_user_1"
  },
  {
    title: "Remote Work vs Office Work",
    description: "Debating the future of work: remote or in-office?",
    tags: ["#Work", "#Business", "#Future"],
    category: "Business",
    optionA: "Remote Work",
    optionB: "Office Work",
    mediaURL: "https://example.com/work-image.jpg",
    userImage: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
    userId: "test_user_2"
  },
  {
    title: "Best Gaming Platform",
    description: "Which gaming platform offers the best experience?",
    tags: ["#Gaming", "#Technology", "#Entertainment"],
    category: "Gaming",
    optionA: "PC Gaming",
    optionB: "Console Gaming",
    mediaURL: "https://example.com/gaming-image.jpg",
    userImage: "https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_profile.png?alt=media",
    userId: "test_user_3"
  }
];

async function createTestTopics() {
  try {
    const batch = db.batch();
    let count = 0;

    for (const topicData of testTopics) {
      const topicRef = db.collection('topics').doc();
      const topic = {
        ...topicData,
        id: topicRef.id,
        date: admin.firestore.FieldValue.serverTimestamp(),
        upvotes: 0,
        downvotes: 0,
        userVoteStatus: "none"
      };

      batch.set(topicRef, topic);
      count++;
      console.log(`Added topic: ${topic.title}`);
    }

    await batch.commit();
    console.log(`Successfully created ${count} test topics`);

  } catch (error) {
    console.error('Error creating test topics:', error);
  }
}

createTestTopics(); 