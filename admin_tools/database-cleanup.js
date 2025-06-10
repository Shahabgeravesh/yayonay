const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = getFirestore();

class DatabaseCleanup {
    constructor() {
        this.batchSize = 500;
    }

    // Remove orphaned documents (documents referencing non-existent parents)
    async cleanupOrphanedDocuments(parentCollection, childCollection, parentRefField) {
        try {
            console.log(`🧹 Starting cleanup of orphaned documents in ${childCollection}...`);
            const orphanedDocs = [];
            let totalProcessed = 0;

            // Get all child documents
            const childDocs = await db.collection(childCollection).get();
            
            for (const childDoc of childDocs.docs) {
                const parentId = childDoc.data()[parentRefField];
                if (!parentId) continue;

                // Check if parent exists
                const parentDoc = await db.collection(parentCollection).doc(parentId).get();
                if (!parentDoc.exists) {
                    orphanedDocs.push({
                        id: childDoc.id,
                        data: childDoc.data()
                    });
                }
                totalProcessed++;
                if (totalProcessed % 100 === 0) {
                    console.log(`📊 Processed ${totalProcessed}/${childDocs.size} documents`);
                }
            }

            // Backup and delete orphaned documents
            if (orphanedDocs.length > 0) {
                console.log(`🗑️ Found ${orphanedDocs.length} orphaned documents`);
                let batch = db.batch();
                let batchCount = 0;

                for (const doc of orphanedDocs) {
                    // Backup document
                    const backupRef = db.collection(`${childCollection}_deleted`).doc();
                    batch.set(backupRef, {
                        ...doc.data,
                        originalId: doc.id,
                        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                        reason: 'orphaned_document_cleanup'
                    });

                    // Delete original
                    const docRef = db.collection(childCollection).doc(doc.id);
                    batch.delete(docRef);

                    batchCount++;
                    if (batchCount === this.batchSize) {
                        await batch.commit();
                        batch = db.batch();
                        batchCount = 0;
                    }
                }

                if (batchCount > 0) {
                    await batch.commit();
                }
                console.log(`✅ Cleaned up ${orphanedDocs.length} orphaned documents`);
            } else {
                console.log('✅ No orphaned documents found');
            }

            return {
                totalProcessed,
                orphanedDocsRemoved: orphanedDocs.length
            };
        } catch (error) {
            console.error('❌ Error in cleanup:', error);
            throw error;
        }
    }

    // Clean up duplicate entries
    async cleanupDuplicates(collection, uniqueField) {
        try {
            console.log(`🧹 Starting duplicate cleanup in ${collection} based on ${uniqueField}...`);
            const snapshot = await db.collection(collection).get();
            const valueMap = new Map();
            const duplicates = [];

            // Find duplicates
            snapshot.docs.forEach(doc => {
                const value = doc.data()[uniqueField];
                if (!value) return;

                if (!valueMap.has(value)) {
                    valueMap.set(value, doc.id);
                } else {
                    duplicates.push({
                        id: doc.id,
                        data: doc.data()
                    });
                }
            });

            // Backup and remove duplicates
            if (duplicates.length > 0) {
                console.log(`🗑️ Found ${duplicates.length} duplicates`);
                let batch = db.batch();
                let batchCount = 0;

                for (const doc of duplicates) {
                    // Backup document
                    const backupRef = db.collection(`${collection}_deleted`).doc();
                    batch.set(backupRef, {
                        ...doc.data,
                        originalId: doc.id,
                        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                        reason: 'duplicate_cleanup'
                    });

                    // Delete original
                    const docRef = db.collection(collection).doc(doc.id);
                    batch.delete(docRef);

                    batchCount++;
                    if (batchCount === this.batchSize) {
                        await batch.commit();
                        batch = db.batch();
                        batchCount = 0;
                    }
                }

                if (batchCount > 0) {
                    await batch.commit();
                }
                console.log(`✅ Cleaned up ${duplicates.length} duplicate documents`);
            } else {
                console.log('✅ No duplicates found');
            }

            return {
                totalProcessed: snapshot.size,
                duplicatesRemoved: duplicates.length
            };
        } catch (error) {
            console.error('❌ Error in duplicate cleanup:', error);
            throw error;
        }
    }

    // Clean up old/expired documents
    async cleanupExpiredDocuments(collection, expiryField, expiryDays) {
        try {
            console.log(`🧹 Starting cleanup of expired documents in ${collection}...`);
            const expiryDate = new Date();
            expiryDate.setDate(expiryDate.getDate() - expiryDays);

            const snapshot = await db.collection(collection)
                .where(expiryField, '<=', expiryDate)
                .get();

            if (!snapshot.empty) {
                console.log(`🗑️ Found ${snapshot.size} expired documents`);
                let batch = db.batch();
                let batchCount = 0;

                for (const doc of snapshot.docs) {
                    // Backup document
                    const backupRef = db.collection(`${collection}_deleted`).doc();
                    batch.set(backupRef, {
                        ...doc.data(),
                        originalId: doc.id,
                        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
                        reason: 'expiry_cleanup'
                    });

                    // Delete original
                    batch.delete(doc.ref);

                    batchCount++;
                    if (batchCount === this.batchSize) {
                        await batch.commit();
                        batch = db.batch();
                        batchCount = 0;
                    }
                }

                if (batchCount > 0) {
                    await batch.commit();
                }
                console.log(`✅ Cleaned up ${snapshot.size} expired documents`);
            } else {
                console.log('✅ No expired documents found');
            }

            return {
                totalProcessed: snapshot.size,
                expiredDocsRemoved: snapshot.size
            };
        } catch (error) {
            console.error('❌ Error in expiry cleanup:', error);
            throw error;
        }
    }

    // Run all cleanup operations
    async runFullCleanup() {
        const results = {
            orphanedDocs: {},
            duplicates: {},
            expired: {}
        };

        // Clean up orphaned subquestions
        results.orphanedDocs.subquestions = await this.cleanupOrphanedDocuments(
            'categories',
            'subquestions',
            'categoryId'
        );

        // Clean up duplicate categories
        results.duplicates.categories = await this.cleanupDuplicates(
            'categories',
            'name'
        );

        // Clean up expired votes (older than 90 days)
        results.expired.votes = await this.cleanupExpiredDocuments(
            'votes',
            'createdAt',
            90
        );

        return results;
    }
}

module.exports = new DatabaseCleanup(); 