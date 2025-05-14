const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = getFirestore();

class DatabaseStats {
    // Get collection statistics
    async getCollectionStats(collection) {
        try {
            console.log(`📊 Gathering statistics for ${collection}...`);
            const snapshot = await db.collection(collection).get();
            
            // Basic stats
            const stats = {
                totalDocuments: snapshot.size,
                averageFieldsPerDoc: 0,
                createdToday: 0,
                createdThisWeek: 0,
                createdThisMonth: 0,
                lastCreated: null,
                lastUpdated: null
            };

            // Time ranges
            const now = new Date();
            const todayStart = new Date(now.setHours(0, 0, 0, 0));
            const weekStart = new Date(now.setDate(now.getDate() - 7));
            const monthStart = new Date(now.setDate(now.getDate() - 30));

            let totalFields = 0;

            // Process each document
            snapshot.docs.forEach(doc => {
                const data = doc.data();
                totalFields += Object.keys(data).length;

                const createdAt = data.createdAt?.toDate();
                const updatedAt = data.updatedAt?.toDate();

                if (createdAt) {
                    if (createdAt >= todayStart) stats.createdToday++;
                    if (createdAt >= weekStart) stats.createdThisWeek++;
                    if (createdAt >= monthStart) stats.createdThisMonth++;

                    if (!stats.lastCreated || createdAt > stats.lastCreated) {
                        stats.lastCreated = createdAt;
                    }
                }

                if (updatedAt && (!stats.lastUpdated || updatedAt > stats.lastUpdated)) {
                    stats.lastUpdated = updatedAt;
                }
            });

            stats.averageFieldsPerDoc = totalFields / (snapshot.size || 1);

            return stats;
        } catch (error) {
            console.error(`❌ Error getting stats for ${collection}:`, error);
            throw error;
        }
    }

    // Get relationship statistics
    async getRelationshipStats(parentCollection, childCollection, parentRefField) {
        try {
            console.log(`📊 Analyzing relationship between ${parentCollection} and ${childCollection}...`);
            
            const stats = {
                totalParents: 0,
                totalChildren: 0,
                averageChildrenPerParent: 0,
                parentsWithNoChildren: 0,
                orphanedChildren: 0,
                maxChildrenInParent: 0
            };

            // Get all documents
            const [parentDocs, childDocs] = await Promise.all([
                db.collection(parentCollection).get(),
                db.collection(childCollection).get()
            ]);

            stats.totalParents = parentDocs.size;
            stats.totalChildren = childDocs.size;

            // Create a map of parent IDs and their children count
            const parentChildCount = new Map();
            parentDocs.docs.forEach(doc => {
                parentChildCount.set(doc.id, 0);
            });

            // Count children for each parent
            childDocs.docs.forEach(doc => {
                const parentId = doc.data()[parentRefField];
                if (parentId) {
                    if (parentChildCount.has(parentId)) {
                        const currentCount = parentChildCount.get(parentId) + 1;
                        parentChildCount.set(parentId, currentCount);
                        stats.maxChildrenInParent = Math.max(stats.maxChildrenInParent, currentCount);
                    } else {
                        stats.orphanedChildren++;
                    }
                }
            });

            // Calculate statistics
            let totalChildren = 0;
            parentChildCount.forEach(count => {
                if (count === 0) stats.parentsWithNoChildren++;
                totalChildren += count;
            });

            stats.averageChildrenPerParent = totalChildren / (stats.totalParents || 1);

            return stats;
        } catch (error) {
            console.error(`❌ Error getting relationship stats:`, error);
            throw error;
        }
    }

    // Get user activity statistics
    async getUserActivityStats(timeRange = 30) {
        try {
            console.log(`📊 Analyzing user activity for the last ${timeRange} days...`);
            const startDate = new Date();
            startDate.setDate(startDate.getDate() - timeRange);

            const stats = {
                totalActiveUsers: 0,
                totalVotes: 0,
                averageVotesPerUser: 0,
                mostActiveUsers: [],
                activityByDay: {},
                peakActivityTime: null,
                peakActivityCount: 0
            };

            // Get votes within time range
            const votesSnapshot = await db.collection('votes')
                .where('createdAt', '>=', startDate)
                .get();

            // Process votes
            const userVotes = new Map();
            const activityByHour = new Map();

            votesSnapshot.docs.forEach(doc => {
                const data = doc.data();
                const userId = data.userId;
                const createdAt = data.createdAt?.toDate();

                if (userId && createdAt) {
                    // Count votes per user
                    userVotes.set(userId, (userVotes.get(userId) || 0) + 1);

                    // Count activity by day
                    const dayKey = createdAt.toISOString().split('T')[0];
                    stats.activityByDay[dayKey] = (stats.activityByDay[dayKey] || 0) + 1;

                    // Track hourly activity
                    const hour = createdAt.getHours();
                    const hourlyCount = (activityByHour.get(hour) || 0) + 1;
                    activityByHour.set(hour, hourlyCount);

                    if (hourlyCount > stats.peakActivityCount) {
                        stats.peakActivityCount = hourlyCount;
                        stats.peakActivityTime = hour;
                    }
                }
            });

            // Calculate statistics
            stats.totalVotes = votesSnapshot.size;
            stats.totalActiveUsers = userVotes.size;
            stats.averageVotesPerUser = stats.totalVotes / (stats.totalActiveUsers || 1);

            // Get most active users
            stats.mostActiveUsers = Array.from(userVotes.entries())
                .sort((a, b) => b[1] - a[1])
                .slice(0, 10)
                .map(([userId, votes]) => ({ userId, votes }));

            return stats;
        } catch (error) {
            console.error('❌ Error getting user activity stats:', error);
            throw error;
        }
    }

    // Get comprehensive database statistics
    async getFullDatabaseStats() {
        const stats = {
            collections: {},
            relationships: {},
            userActivity: {}
        };

        // Get collection statistics
        const collections = ['categories', 'subquestions', 'votes', 'users'];
        for (const collection of collections) {
            stats.collections[collection] = await this.getCollectionStats(collection);
        }

        // Get relationship statistics
        stats.relationships.categorySubquestions = await this.getRelationshipStats(
            'categories',
            'subquestions',
            'categoryId'
        );

        // Get user activity statistics
        stats.userActivity = await this.getUserActivityStats(30);

        return stats;
    }
}

module.exports = new DatabaseStats(); 