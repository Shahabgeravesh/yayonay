// Database Management Functions
const dbManagement = {
    // User Management
    async getUserStats() {
        const stats = {
            totalUsers: 0,
            activeUsers: 0,
            totalVotes: 0,
            totalShares: 0,
            usersByCountry: {},
            activityLast30Days: 0
        };

        try {
            const usersSnapshot = await db.collection('users').get();
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

            for (const userDoc of usersSnapshot.docs) {
                stats.totalUsers++;
                const userData = userDoc.data();
                
                // Count active users
                if (userData.lastActive && userData.lastActive.toDate() > thirtyDaysAgo) {
                    stats.activeUsers++;
                    stats.activityLast30Days++;
                }

                // Count by country
                if (userData.country) {
                    stats.usersByCountry[userData.country] = (stats.usersByCountry[userData.country] || 0) + 1;
                }

                // Count votes and shares
                const votesSnapshot = await db.collection(`users/${userDoc.id}/votes`).get();
                const sharesSnapshot = await db.collection(`users/${userDoc.id}/shares`).get();
                stats.totalVotes += votesSnapshot.size;
                stats.totalShares += sharesSnapshot.size;
            }

            return stats;
        } catch (error) {
            console.error('Error getting user stats:', error);
            throw error;
        }
    },

    // Content Management
    async getContentStats() {
        const stats = {
            categories: 0,
            subcategories: 0,
            topicsTotal: 0,
            topicsActive: 0,
            topicsByCategory: {},
            averageVotesPerTopic: 0,
            mostPopularTopics: []
        };

        try {
            // Get categories and subcategories
            const [categoriesSnapshot, subcategoriesSnapshot, topicsSnapshot] = await Promise.all([
                db.collection('categories').get(),
                db.collection('subcategories').get(),
                db.collection('topics').get()
            ]);

            stats.categories = categoriesSnapshot.size;
            stats.subcategories = subcategoriesSnapshot.size;
            stats.topicsTotal = topicsSnapshot.size;

            // Process topics
            for (const topicDoc of topicsSnapshot.docs) {
                const topicData = topicDoc.data();
                
                if (topicData.isActive) {
                    stats.topicsActive++;
                }

                if (topicData.categoryId) {
                    stats.topicsByCategory[topicData.categoryId] = (stats.topicsByCategory[topicData.categoryId] || 0) + 1;
                }

                if (topicData.votesCount) {
                    stats.averageVotesPerTopic += topicData.votesCount;
                }

                stats.mostPopularTopics.push({
                    id: topicDoc.id,
                    title: topicData.title,
                    votes: topicData.votesCount || 0
                });
            }

            // Calculate average votes
            if (stats.topicsTotal > 0) {
                stats.averageVotesPerTopic = Math.round(stats.averageVotesPerTopic / stats.topicsTotal);
            }

            // Sort and limit most popular topics
            stats.mostPopularTopics.sort((a, b) => b.votes - a.votes);
            stats.mostPopularTopics = stats.mostPopularTopics.slice(0, 10);

            return stats;
        } catch (error) {
            console.error('Error getting content stats:', error);
            throw error;
        }
    },

    // Database Maintenance
    async performDatabaseMaintenance() {
        const maintenance = {
            orphanedRecords: 0,
            fixedRecords: 0,
            errors: []
        };

        try {
            const batch = db.batch();

            // Check for orphaned votes (where topic doesn't exist)
            const usersSnapshot = await db.collection('users').get();
            for (const userDoc of usersSnapshot.docs) {
                const votesSnapshot = await db.collection(`users/${userDoc.id}/votes`).get();
                
                for (const voteDoc of votesSnapshot.docs) {
                    const topicRef = db.collection('topics').doc(voteDoc.data().topicId);
                    const topicExists = await topicRef.get();
                    
                    if (!topicExists.exists) {
                        batch.delete(voteDoc.ref);
                        maintenance.orphanedRecords++;
                    }
                }
            }

            // Check for topics with invalid categories
            const topicsSnapshot = await db.collection('topics').get();
            for (const topicDoc of topicsSnapshot.docs) {
                const topicData = topicDoc.data();
                
                if (topicData.categoryId) {
                    const categoryExists = await db.collection('categories').doc(topicData.categoryId).get();
                    if (!categoryExists.exists) {
                        maintenance.errors.push(`Topic ${topicDoc.id} has invalid category ${topicData.categoryId}`);
                    }
                }
            }

            // Commit changes
            if (maintenance.orphanedRecords > 0) {
                await batch.commit();
                maintenance.fixedRecords = maintenance.orphanedRecords;
            }

            return maintenance;
        } catch (error) {
            console.error('Error during maintenance:', error);
            throw error;
        }
    },

    // Export Database
    async exportDatabase() {
        const exportData = {
            metadata: {
                timestamp: new Date().toISOString(),
                version: '1.0'
            },
            categories: [],
            subcategories: [],
            topics: [],
            users: []
        };

        try {
            // Export categories
            const categoriesSnapshot = await db.collection('categories').get();
            categoriesSnapshot.forEach(doc => {
                exportData.categories.push({
                    id: doc.id,
                    ...doc.data()
                });
            });

            // Export subcategories
            const subcategoriesSnapshot = await db.collection('subcategories').get();
            subcategoriesSnapshot.forEach(doc => {
                exportData.subcategories.push({
                    id: doc.id,
                    ...doc.data()
                });
            });

            // Export topics
            const topicsSnapshot = await db.collection('topics').get();
            topicsSnapshot.forEach(doc => {
                exportData.topics.push({
                    id: doc.id,
                    ...doc.data()
                });
            });

            // Export users (excluding sensitive data)
            const usersSnapshot = await db.collection('users').get();
            for (const userDoc of usersSnapshot.docs) {
                const userData = userDoc.data();
                const userExport = {
                    id: userDoc.id,
                    createdAt: userData.createdAt,
                    lastActive: userData.lastActive,
                    country: userData.country,
                    votesCount: 0,
                    sharesCount: 0
                };

                // Count votes and shares
                const votesSnapshot = await db.collection(`users/${userDoc.id}/votes`).get();
                const sharesSnapshot = await db.collection(`users/${userDoc.id}/shares`).get();
                userExport.votesCount = votesSnapshot.size;
                userExport.sharesCount = sharesSnapshot.size;

                exportData.users.push(userExport);
            }

            return exportData;
        } catch (error) {
            console.error('Error exporting database:', error);
            throw error;
        }
    },

    // Import Database
    async importDatabase(importData) {
        const result = {
            categoriesImported: 0,
            subcategoriesImported: 0,
            topicsImported: 0,
            errors: []
        };

        try {
            // Validate import data
            if (!importData.metadata || !importData.categories || !importData.subcategories || !importData.topics) {
                throw new Error('Invalid import data format');
            }

            // Import categories
            for (const category of importData.categories) {
                try {
                    await db.collection('categories').doc(category.id).set({
                        name: category.name,
                        order: category.order,
                        imageURL: category.imageURL,
                        featured: category.featured,
                        createdAt: firebase.firestore.Timestamp.fromDate(new Date(category.createdAt)),
                        updatedAt: firebase.firestore.Timestamp.fromDate(new Date())
                    });
                    result.categoriesImported++;
                } catch (error) {
                    result.errors.push(`Error importing category ${category.id}: ${error.message}`);
                }
            }

            // Import subcategories
            for (const subcategory of importData.subcategories) {
                try {
                    await db.collection('subcategories').doc(subcategory.id).set({
                        name: subcategory.name,
                        parentId: subcategory.parentId,
                        order: subcategory.order,
                        imageURL: subcategory.imageURL,
                        createdAt: firebase.firestore.Timestamp.fromDate(new Date(subcategory.createdAt)),
                        updatedAt: firebase.firestore.Timestamp.fromDate(new Date())
                    });
                    result.subcategoriesImported++;
                } catch (error) {
                    result.errors.push(`Error importing subcategory ${subcategory.id}: ${error.message}`);
                }
            }

            // Import topics
            for (const topic of importData.topics) {
                try {
                    await db.collection('topics').doc(topic.id).set({
                        title: topic.title,
                        categoryId: topic.categoryId,
                        subcategoryId: topic.subcategoryId,
                        isActive: topic.isActive,
                        votesCount: topic.votesCount || 0,
                        createdAt: firebase.firestore.Timestamp.fromDate(new Date(topic.createdAt)),
                        updatedAt: firebase.firestore.Timestamp.fromDate(new Date())
                    });
                    result.topicsImported++;
                } catch (error) {
                    result.errors.push(`Error importing topic ${topic.id}: ${error.message}`);
                }
            }

            return result;
        } catch (error) {
            console.error('Error importing database:', error);
            throw error;
        }
    }
}; 