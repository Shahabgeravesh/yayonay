const admin = require('firebase-admin');
const serviceAccount = require('../../serviceAccountKey.json');

// Initialize the app with your service account
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Define subcategories with specific image URLs
const categorySubcategories = {
  "Sports": [
    {
      name: "Football",
      imageURL: "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800"
    },
    {
      name: "Basketball",
      imageURL: "https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800"
    },
    {
      name: "Soccer",
      imageURL: "https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=800"
    },
    {
      name: "Baseball",
      imageURL: "https://images.unsplash.com/photo-1508344928928-7165b67de128?w=800"
    },
    {
      name: "Tennis",
      imageURL: "https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?w=800"
    },
    {
      name: "Golf",
      imageURL: "https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=800"
    },
    {
      name: "Hockey",
      imageURL: "https://images.unsplash.com/photo-1580138923608-429ef9a21533?w=800"
    },
    {
      name: "Volleyball",
      imageURL: "https://images.unsplash.com/photo-1592656094267-764a45160876?w=800"
    },
    {
      name: "Rugby",
      imageURL: "https://images.unsplash.com/photo-1544298621-35a764866ff0?w=800"
    },
    {
      name: "Cricket",
      imageURL: "https://images.unsplash.com/photo-1624526267942-ab0ff8a3e972?w=800"
    }
  ],
  "Food": [
    {
      name: "Italian",
      imageURL: "https://images.unsplash.com/photo-1498579150354-977475b7ea0b?w=800"
    },
    {
      name: "Japanese",
      imageURL: "https://images.unsplash.com/photo-1580822184713-fc5400e7fe10?w=800"
    },
    {
      name: "Mexican",
      imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800"
    },
    {
      name: "Chinese",
      imageURL: "https://images.unsplash.com/photo-1585032226651-759b368d7246?w=800"
    },
    {
      name: "Indian",
      imageURL: "https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800"
    },
    {
      name: "American",
      imageURL: "https://images.unsplash.com/photo-1551615593-ef5fe247e8f7?w=800"
    },
    {
      name: "Mediterranean",
      imageURL: "https://images.unsplash.com/photo-1544250965-67a1716ae3a8?w=800"
    },
    {
      name: "Thai",
      imageURL: "https://images.unsplash.com/photo-1559314809-0d155014e29e?w=800"
    },
    {
      name: "French",
      imageURL: "https://images.unsplash.com/photo-1608855238293-a8853e7f7c98?w=800"
    },
    {
      name: "Korean",
      imageURL: "https://images.unsplash.com/photo-1498654896293-37aacf113fd9?w=800"
    }
  ],
  "Drinks": [
    {
      name: "Coffee",
      imageURL: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800"
    },
    {
      name: "Tea",
      imageURL: "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800"
    },
    {
      name: "Cocktails",
      imageURL: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800"
    },
    {
      name: "Wine",
      imageURL: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=800"
    },
    {
      name: "Beer",
      imageURL: "https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=800"
    },
    {
      name: "Smoothies",
      imageURL: "https://images.unsplash.com/photo-1502741224143-90386d7f8c82?w=800"
    },
    {
      name: "Juice",
      imageURL: "https://images.unsplash.com/photo-1613478223719-2ab802602423?w=800"
    },
    {
      name: "Energy Drinks",
      imageURL: "https://images.unsplash.com/photo-1622543925917-763c34d1a86e?w=800"
    },
    {
      name: "Soft Drinks",
      imageURL: "https://images.unsplash.com/photo-1581006852262-e4307cf6283a?w=800"
    },
    {
      name: "Mocktails",
      imageURL: "https://images.unsplash.com/photo-1604178280816-55e5a3d5e767?w=800"
    }
  ],
  "Dessert": [
    {
      name: "Ice Cream",
      imageURL: "https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=800"
    },
    {
      name: "Cakes",
      imageURL: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800"
    },
    {
      name: "Cookies",
      imageURL: "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=800"
    },
    {
      name: "Pastries",
      imageURL: "https://images.unsplash.com/photo-1517433670267-08bbd4be890f?w=800"
    },
    {
      name: "Chocolate",
      imageURL: "https://images.unsplash.com/photo-1511381939415-e44015466834?w=800"
    },
    {
      name: "Pies",
      imageURL: "https://images.unsplash.com/photo-1519915028121-7d3463d20b13?w=800"
    },
    {
      name: "Puddings",
      imageURL: "https://images.unsplash.com/photo-1516684163977-84cc7de8c7c8?w=800"
    },
    {
      name: "Frozen Treats",
      imageURL: "https://images.unsplash.com/photo-1505394033641-40c6ad1178d7?w=800"
    },
    {
      name: "Candy",
      imageURL: "https://images.unsplash.com/photo-1582058091505-f87a2e55a40f?w=800"
    },
    {
      name: "Baked Goods",
      imageURL: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800"
    }
  ],
  "Travel": [
    {
      name: "Beach Resorts",
      imageURL: "https://images.unsplash.com/photo-1582610116397-edb318620f90?w=800"
    },
    {
      name: "City Breaks",
      imageURL: "https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800"
    },
    {
      name: "Mountain Retreats",
      imageURL: "https://images.unsplash.com/photo-1486870591958-9b9d0d1dda99?w=800"
    },
    {
      name: "Adventure Tours",
      imageURL: "https://images.unsplash.com/photo-1527631746610-bca00a040d60?w=800"
    },
    {
      name: "Cultural Trips",
      imageURL: "https://images.unsplash.com/photo-1533669955142-6a73332af4db?w=800"
    },
    {
      name: "Road Trips",
      imageURL: "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800"
    },
    {
      name: "Cruises",
      imageURL: "https://images.unsplash.com/photo-1548574505-5e239809ee19?w=800"
    },
    {
      name: "Backpacking",
      imageURL: "https://images.unsplash.com/photo-1504025468847-0e438279542c?w=800"
    },
    {
      name: "Luxury Travel",
      imageURL: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800"
    },
    {
      name: "Eco Tourism",
      imageURL: "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800"
    }
  ],
  "Art": [
    {
      name: "Painting",
      imageURL: "https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=800"
    },
    {
      name: "Sculpture",
      imageURL: "https://images.unsplash.com/photo-1561839561-b13bcfe95249?w=800"
    },
    {
      name: "Photography",
      imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800"
    },
    {
      name: "Digital Art",
      imageURL: "https://images.unsplash.com/photo-1563089145-599997674d42?w=800"
    },
    {
      name: "Street Art",
      imageURL: "https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?w=800"
    },
    {
      name: "Ceramics",
      imageURL: "https://images.unsplash.com/photo-1493106641515-6b5631de4bb9?w=800"
    },
    {
      name: "Drawing",
      imageURL: "https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800"
    },
    {
      name: "Mixed Media",
      imageURL: "https://images.unsplash.com/photo-1515405295579-ba7b45403062?w=800"
    },
    {
      name: "Installation Art",
      imageURL: "https://images.unsplash.com/photo-1547826039-bfc35e0f1ea8?w=800"
    },
    {
      name: "Performance Art",
      imageURL: "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=800"
    }
  ],
  "Music": [
    {
      name: "Pop",
      imageURL: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800"
    },
    {
      name: "Rock",
      imageURL: "https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=800"
    },
    {
      name: "Hip Hop",
      imageURL: "https://images.unsplash.com/photo-1571609557682-c416b17d7c8f?w=800"
    },
    {
      name: "Jazz",
      imageURL: "https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=800"
    },
    {
      name: "Classical",
      imageURL: "https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=800"
    },
    {
      name: "Electronic",
      imageURL: "https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=800"
    },
    {
      name: "Country",
      imageURL: "https://images.unsplash.com/photo-1543699936-c901ddbf0c05?w=800"
    },
    {
      name: "R&B",
      imageURL: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800"
    },
    {
      name: "Metal",
      imageURL: "https://images.unsplash.com/photo-1508973379184-7517410fb0bc?w=800"
    },
    {
      name: "Indie",
      imageURL: "https://images.unsplash.com/photo-1524650359799-842906ca1c06?w=800"
    }
  ],
  "Movies": [
    {
      name: "Action",
      imageURL: "https://images.unsplash.com/photo-1535016120720-40c646be5580?w=800"
    },
    {
      name: "Comedy",
      imageURL: "https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=800"
    },
    {
      name: "Drama",
      imageURL: "https://images.unsplash.com/photo-1485846234645-a62644f84728?w=800"
    },
    {
      name: "Horror",
      imageURL: "https://images.unsplash.com/photo-1505533321630-975218a5f66f?w=800"
    },
    {
      name: "Sci-Fi",
      imageURL: "https://images.unsplash.com/photo-1506901437675-cde80ff9c746?w=800"
    },
    {
      name: "Romance",
      imageURL: "https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=800"
    },
    {
      name: "Documentary",
      imageURL: "https://images.unsplash.com/photo-1492724441997-5dc865305da7?w=800"
    },
    {
      name: "Animation",
      imageURL: "https://images.unsplash.com/photo-1534972195531-d756b9bfa9f2?w=800"
    },
    {
      name: "Thriller",
      imageURL: "https://images.unsplash.com/photo-1509347528160-9a9e33742cdb?w=800"
    },
    {
      name: "Fantasy",
      imageURL: "https://images.unsplash.com/photo-1500462918059-b1a0cb512f1d?w=800"
    }
  ],
  "Books": [
    {
      name: "Fiction",
      imageURL: "https://images.unsplash.com/photo-1474932430478-367dbb6832c1?w=800"
    },
    {
      name: "Non-Fiction",
      imageURL: "https://images.unsplash.com/photo-1495446815901-a7297e633e8d?w=800"
    },
    {
      name: "Mystery",
      imageURL: "https://images.unsplash.com/photo-1587876931567-564ce588bfbd?w=800"
    },
    {
      name: "Science Fiction",
      imageURL: "https://images.unsplash.com/photo-1518281420975-50db6e5d0a97?w=800"
    },
    {
      name: "Romance",
      imageURL: "https://images.unsplash.com/photo-1474552226712-ac0f0961a954?w=800"
    },
    {
      name: "Biography",
      imageURL: "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=800"
    },
    {
      name: "Self-Help",
      imageURL: "https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=800"
    },
    {
      name: "Fantasy",
      imageURL: "https://images.unsplash.com/photo-1479813183133-7252a2f29659?w=800"
    },
    {
      name: "History",
      imageURL: "https://images.unsplash.com/photo-1461360370896-922624d12aa1?w=800"
    },
    {
      name: "Poetry",
      imageURL: "https://images.unsplash.com/photo-1474631245212-32dc3c8310c6?w=800"
    }
  ],
  "Technology": [
    {
      name: "Smartphones",
      imageURL: "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800"
    },
    {
      name: "Laptops",
      imageURL: "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800"
    },
    {
      name: "Smart Home",
      imageURL: "https://images.unsplash.com/photo-1558002038-876f1d0aa8c1?w=800"
    },
    {
      name: "Gaming",
      imageURL: "https://images.unsplash.com/photo-1538481199705-c710c4e965fc?w=800"
    },
    {
      name: "Wearables",
      imageURL: "https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=800"
    },
    {
      name: "Audio",
      imageURL: "https://images.unsplash.com/photo-1484704849700-f032a568e944?w=800"
    },
    {
      name: "Cameras",
      imageURL: "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800"
    },
    {
      name: "TVs",
      imageURL: "https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=800"
    },
    {
      name: "Tablets",
      imageURL: "https://images.unsplash.com/photo-1561154464-82e9adf32764?w=800"
    },
    {
      name: "VR/AR",
      imageURL: "https://images.unsplash.com/photo-1622979135225-d2ba269cf1ac?w=800"
    }
  ],
  "Fashion": [
    {
      name: "Casual Wear",
      imageURL: "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800"
    },
    {
      name: "Formal Wear",
      imageURL: "https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800"
    },
    {
      name: "Streetwear",
      imageURL: "https://images.unsplash.com/photo-1523398002811-999ca8dec234?w=800"
    },
    {
      name: "Athletic Wear",
      imageURL: "https://images.unsplash.com/photo-1518459031867-a89b944bffe4?w=800"
    },
    {
      name: "Accessories",
      imageURL: "https://images.unsplash.com/photo-1523779917675-b6ed3a42a561?w=800"
    },
    {
      name: "Shoes",
      imageURL: "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800"
    },
    {
      name: "Designer",
      imageURL: "https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800"
    },
    {
      name: "Vintage",
      imageURL: "https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=800"
    },
    {
      name: "Sustainable",
      imageURL: "https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=800"
    },
    {
      name: "Jewelry",
      imageURL: "https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800"
    }
  ],
  "Pets": [
    {
      name: "Dogs",
      imageURL: "https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800"
    },
    {
      name: "Cats",
      imageURL: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800"
    },
    {
      name: "Fish",
      imageURL: "https://images.unsplash.com/photo-1522069169874-c58ec4b76be5?w=800"
    },
    {
      name: "Birds",
      imageURL: "https://images.unsplash.com/photo-1452570053594-1b985d6ea890?w=800"
    },
    {
      name: "Small Animals",
      imageURL: "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=800"
    },
    {
      name: "Reptiles",
      imageURL: "https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?w=800"
    },
    {
      name: "Exotic Pets",
      imageURL: "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=800"
    },
    {
      name: "Pet Supplies",
      imageURL: "https://images.unsplash.com/photo-1601758174114-e711c0cbaa69?w=800"
    },
    {
      name: "Pet Care",
      imageURL: "https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=800"
    },
    {
      name: "Pet Training",
      imageURL: "https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800"
    }
  ],
  "Home Decor": [
    {
      name: "Living Room",
      imageURL: "https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800"
    },
    {
      name: "Bedroom",
      imageURL: "https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800"
    },
    {
      name: "Kitchen",
      imageURL: "https://images.unsplash.com/photo-1556911220-bff31c812dba?w=800"
    },
    {
      name: "Bathroom",
      imageURL: "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800"
    },
    {
      name: "Outdoor",
      imageURL: "https://images.unsplash.com/photo-1600566752355-35792bedcfea?w=800"
    },
    {
      name: "Lighting",
      imageURL: "https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=800"
    },
    {
      name: "Wall Art",
      imageURL: "https://images.unsplash.com/photo-1526724038726-3007ffb8025f?w=800"
    },
    {
      name: "Furniture",
      imageURL: "https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=800"
    },
    {
      name: "Textiles",
      imageURL: "https://images.unsplash.com/photo-1590012314607-cda9d9b699ae?w=800"
    },
    {
      name: "Storage",
      imageURL: "https://images.unsplash.com/photo-1558997519-83c9716b1b07?w=800"
    }
  ],
  "Fitness": [
    {
      name: "Cardio",
      imageURL: "https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=800"
    },
    {
      name: "Strength Training",
      imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800"
    },
    {
      name: "Yoga",
      imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800"
    },
    {
      name: "Pilates",
      imageURL: "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800"
    },
    {
      name: "CrossFit",
      imageURL: "https://images.unsplash.com/photo-1534367610401-9f5ed68180aa?w=800"
    },
    {
      name: "Running",
      imageURL: "https://images.unsplash.com/photo-1538583526806-6c84f607f5f3?w=800"
    },
    {
      name: "Swimming",
      imageURL: "https://images.unsplash.com/photo-1530549387789-4c1017266635?w=800"
    },
    {
      name: "Cycling",
      imageURL: "https://images.unsplash.com/photo-1517649763962-0c623066013b?w=800"
    },
    {
      name: "HIIT",
      imageURL: "https://images.unsplash.com/photo-1549576490-b0b4831ef60a?w=800"
    },
    {
      name: "Martial Arts",
      imageURL: "https://images.unsplash.com/photo-1555597673-b21d5c935865?w=800"
    }
  ],
  "Gaming": [
    {
      name: "PC Gaming",
      imageURL: "https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=800"
    },
    {
      name: "Console Gaming",
      imageURL: "https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=800"
    },
    {
      name: "Mobile Gaming",
      imageURL: "https://images.unsplash.com/photo-1592155931584-901ac15763e3?w=800"
    },
    {
      name: "RPGs",
      imageURL: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=800"
    },
    {
      name: "FPS",
      imageURL: "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800"
    },
    {
      name: "Strategy",
      imageURL: "https://images.unsplash.com/photo-1611996575749-79a3a250f948?w=800"
    },
    {
      name: "Sports Games",
      imageURL: "https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=800"
    },
    {
      name: "Indie Games",
      imageURL: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800"
    },
    {
      name: "MMOs",
      imageURL: "https://images.unsplash.com/photo-1542751110-97427bbecf20?w=800"
    },
    {
      name: "Racing Games",
      imageURL: "https://images.unsplash.com/photo-1548687677-4ad4e6ebf86f?w=800"
    }
  ],
  "Beauty": [
    {
      name: "Skincare",
      imageURL: "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=800"
    },
    {
      name: "Makeup",
      imageURL: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800"
    },
    {
      name: "Hair Care",
      imageURL: "https://images.unsplash.com/photo-1522336284037-3cfa1c595175?w=800"
    },
    {
      name: "Nail Care",
      imageURL: "https://images.unsplash.com/photo-1519014816548-bf5fe059798b?w=800"
    },
    {
      name: "Fragrances",
      imageURL: "https://images.unsplash.com/photo-1541643600914-78b084683601?w=800"
    },
    {
      name: "Natural Beauty",
      imageURL: "https://images.unsplash.com/photo-1526947425960-945c6e72858f?w=800"
    },
    {
      name: "Tools",
      imageURL: "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800"
    },
    {
      name: "Body Care",
      imageURL: "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800"
    },
    {
      name: "Men's Grooming",
      imageURL: "https://images.unsplash.com/photo-1581467655410-0c2bf55d9d6c?w=800"
    },
    {
      name: "Anti-Aging",
      imageURL: "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=800"
    }
  ],
  "Cars": [
    {
      name: "Luxury",
      imageURL: "https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=800"
    },
    {
      name: "Sports Cars",
      imageURL: "https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800"
    },
    {
      name: "SUVs",
      imageURL: "https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?w=800"
    },
    {
      name: "Electric",
      imageURL: "https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800"
    },
    {
      name: "Hybrid",
      imageURL: "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=800"
    },
    {
      name: "Classic Cars",
      imageURL: "https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=800"
    },
    {
      name: "Trucks",
      imageURL: "https://images.unsplash.com/photo-1559416523-140ddc3d238c?w=800"
    },
    {
      name: "Sedans",
      imageURL: "https://images.unsplash.com/photo-1550355291-bbee04a92027?w=800"
    },
    {
      name: "Off-Road",
      imageURL: "https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?w=800"
    },
    {
      name: "Compact Cars",
      imageURL: "https://images.unsplash.com/photo-1549062572-544a64fb0c56?w=800"
    }
  ],
  "Photography": [
    {
      name: "Portrait",
      imageURL: "https://images.unsplash.com/photo-1542038784456-1ea8e935640e?w=800"
    },
    {
      name: "Landscape",
      imageURL: "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=800"
    },
    {
      name: "Street",
      imageURL: "https://images.unsplash.com/photo-1514539079130-25950c84af65?w=800"
    },
    {
      name: "Wildlife",
      imageURL: "https://images.unsplash.com/photo-1504006833117-8886a355efbf?w=800"
    },
    {
      name: "Macro",
      imageURL: "https://images.unsplash.com/photo-1550159930-40066082a4fc?w=800"
    },
    {
      name: "Fashion",
      imageURL: "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800"
    },
    {
      name: "Architecture",
      imageURL: "https://images.unsplash.com/photo-1487958449943-2429e8be8625?w=800"
    },
    {
      name: "Travel",
      imageURL: "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800"
    },
    {
      name: "Black & White",
      imageURL: "https://images.unsplash.com/photo-1502790671504-542ad42d5189?w=800"
    },
    {
      name: "Event",
      imageURL: "https://images.unsplash.com/photo-1511578314322-379afb476865?w=800"
    }
  ],
  "Nature": [
    {
      name: "Mountains",
      imageURL: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800"
    },
    {
      name: "Beaches",
      imageURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800"
    },
    {
      name: "Forests",
      imageURL: "https://images.unsplash.com/photo-1511497584788-876760111969?w=800"
    },
    {
      name: "Lakes",
      imageURL: "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800"
    },
    {
      name: "Wildlife",
      imageURL: "https://images.unsplash.com/photo-1504006833117-8886a355efbf?w=800"
    },
    {
      name: "National Parks",
      imageURL: "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800"
    },
    {
      name: "Gardens",
      imageURL: "https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800"
    },
    {
      name: "Waterfalls",
      imageURL: "https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=800"
    },
    {
      name: "Deserts",
      imageURL: "https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=800"
    },
    {
      name: "Islands",
      imageURL: "https://images.unsplash.com/photo-1559128010-7c1ad6e1b6a5?w=800"
    }
  ],
  "DIY": [
    {
      name: "Crafts",
      imageURL: "https://images.unsplash.com/photo-1499781350541-7783f6c6a0c8?w=800"
    },
    {
      name: "Home Improvement",
      imageURL: "https://images.unsplash.com/photo-1581235720704-06d3acfcb36f?w=800"
    },
    {
      name: "Woodworking",
      imageURL: "https://images.unsplash.com/photo-1533743363764-7534d2011c44?w=800"
    },
    {
      name: "Gardening",
      imageURL: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800"
    },
    {
      name: "Upcycling",
      imageURL: "https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=800"
    },
    {
      name: "Electronics",
      imageURL: "https://images.unsplash.com/photo-1601524909162-ae8725290836?w=800"
    },
    {
      name: "Sewing",
      imageURL: "https://images.unsplash.com/photo-1522661067900-ab829854a57f?w=800"
    },
    {
      name: "Art Projects",
      imageURL: "https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=800"
    },
    {
      name: "Furniture Making",
      imageURL: "https://images.unsplash.com/photo-1449247709967-d4461a6a6103?w=800"
    },
    {
      name: "Home Repairs",
      imageURL: "https://images.unsplash.com/photo-1581235720704-06d3acfcb36f?w=800"
    }
  ],
  "Politics": [
    {
      name: "Local Politics",
      imageURL: "https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800"
    },
    {
      name: "National Politics",
      imageURL: "https://images.unsplash.com/photo-1529107386315-e1a2ed48a620?w=800"
    },
    {
      name: "International Relations",
      imageURL: "https://images.unsplash.com/photo-1526470498-9ae73c665de8?w=800"
    },
    {
      name: "Economic Policy",
      imageURL: "https://images.unsplash.com/photo-1518186285589-2f7649de83e0?w=800"
    },
    {
      name: "Social Issues",
      imageURL: "https://images.unsplash.com/photo-1460518451285-97b6aa326961?w=800"
    },
    {
      name: "Environmental Policy",
      imageURL: "https://images.unsplash.com/photo-1497435334941-8c899ee9e694?w=800"
    },
    {
      name: "Education Policy",
      imageURL: "https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800"
    },
    {
      name: "Healthcare Policy",
      imageURL: "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800"
    },
    {
      name: "Foreign Policy",
      imageURL: "https://images.unsplash.com/photo-1526470498-9ae73c665de8?w=800"
    },
    {
      name: "Civil Rights",
      imageURL: "https://images.unsplash.com/photo-1591189824936-5cca9fca7608?w=800"
    }
  ]
};

async function createSubcategories() {
  try {
    // First, get all categories to map names to IDs
    const categoriesSnapshot = await db.collection('categories').get();
    
    const categoryIdMap = {};
    categoriesSnapshot.forEach(doc => {
      const data = doc.data();
      if (data.name) {
        categoryIdMap[data.name] = doc.id;
      }
    });
    
    console.log('Found categories:', categoryIdMap);
    
    // Clear existing subcategories
    const subcategoriesSnapshot = await db.collection('subCategories').get();
    const batch = db.batch();
    subcategoriesSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    await batch.commit();
    console.log('Cleared existing subcategories');
    
    // Create new subcategories
    const newBatch = db.batch();
    let count = 0;
    
    for (const [categoryName, subcategories] of Object.entries(categorySubcategories)) {
      const categoryId = categoryIdMap[categoryName];
      if (!categoryId) {
        console.log(`No ID found for category: ${categoryName}`);
        continue;
      }
      
      if (Array.isArray(subcategories)) {
        for (let i = 0; i < subcategories.length; i++) {
          const subcategory = typeof subcategories[i] === 'string' 
            ? {
                name: subcategories[i],
                imageURL: `https://source.unsplash.com/800x600/?${encodeURIComponent(subcategories[i])}`
              }
            : subcategories[i];
            
          const subcategoryRef = db.collection('subCategories').doc();
          const subcategoryData = {
            categoryId: categoryId,
            name: subcategory.name,
            imageURL: subcategory.imageURL,
            order: i,
            yayCount: 0,
            nayCount: 0,
            isActive: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
          };
          
          newBatch.set(subcategoryRef, subcategoryData);
          count++;
          
          // Firestore has a limit of 500 operations per batch
          if (count % 450 === 0) {
            await newBatch.commit();
            console.log(`Committed batch of ${count} subcategories`);
            count = 0;
          }
        }
      }
    }
    
    // Commit any remaining operations
    if (count > 0) {
      await newBatch.commit();
      console.log(`Committed final batch of ${count} subcategories`);
    }
    
    console.log('Successfully created all subcategories');
    
  } catch (error) {
    console.error('Error creating subcategories:', error);
  }
}

// Run the function
createSubcategories(); 