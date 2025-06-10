// Automated CRUD Operations for YayoNay Admin Dashboard
const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = getFirestore();

class AutomatedCRUD {
    constructor() {
        this.batchSize = 500; // Firestore batch limit
        this.listeners = new Map();
    }

    // Validate data before operations
    validateData(data, requiredFields) {
        const errors = [];
        requiredFields.forEach(field => {
            if (!data[field]) {
                errors.push(`Missing required field: ${field}`);
            }
        });
        return errors;
    }

    // Create with automatic ID generation and validation
    async createDocument(collection, data, requiredFields = []) {
        try {
            // Validate data
            const validationErrors = this.validateData(data, requiredFields);
            if (validationErrors.length > 0) {
                throw new Error(`Validation failed: ${validationErrors.join(', ')}`);
            }

            // Add metadata
            const enrichedData = {
                ...data,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            const docRef = await db.collection(collection).add(enrichedData);
            console.log(`✅ Document created successfully with ID: ${docRef.id}`);
            return { id: docRef.id, ...enrichedData };
        } catch (error) {
            console.error('❌ Error creating document:', error);
            throw error;
        }
    }

    // Bulk create with progress tracking
    async bulkCreate(collection, items, requiredFields = []) {
        try {
            const results = [];
            let batch = db.batch();
            let operationCount = 0;

            for (let i = 0; i < items.length; i++) {
                const validationErrors = this.validateData(items[i], requiredFields);
                if (validationErrors.length > 0) {
                    console.warn(`⚠️ Skipping item ${i + 1} due to validation errors:`, validationErrors);
                    continue;
                }

                const enrichedData = {
                    ...items[i],
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                };

                const docRef = db.collection(collection).doc();
                batch.set(docRef, enrichedData);
                results.push({ id: docRef.id, ...enrichedData });
                operationCount++;

                if (operationCount === this.batchSize) {
                    await batch.commit();
                    batch = db.batch();
                    operationCount = 0;
                    console.log(`✅ Batch committed: ${i + 1}/${items.length} items processed`);
                }
            }

            if (operationCount > 0) {
                await batch.commit();
                console.log('✅ Final batch committed');
            }

            return results;
        } catch (error) {
            console.error('❌ Error in bulk create:', error);
            throw error;
        }
    }

    // Read with advanced querying
    async readDocuments(collection, queryParams = {}) {
        try {
            let query = db.collection(collection);

            // Apply filters
            if (queryParams.filters) {
                queryParams.filters.forEach(filter => {
                    query = query.where(filter.field, filter.operator, filter.value);
                });
            }

            // Apply ordering
            if (queryParams.orderBy) {
                query = query.orderBy(queryParams.orderBy.field, queryParams.orderBy.direction || 'asc');
            }

            // Apply pagination
            if (queryParams.limit) {
                query = query.limit(queryParams.limit);
            }
            if (queryParams.startAfter) {
                query = query.startAfter(queryParams.startAfter);
            }

            const snapshot = await query.get();
            return snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
        } catch (error) {
            console.error('❌ Error reading documents:', error);
            throw error;
        }
    }

    // Update with validation and partial updates
    async updateDocument(collection, docId, data, requiredFields = []) {
        try {
            const validationErrors = this.validateData(data, requiredFields);
            if (validationErrors.length > 0) {
                throw new Error(`Validation failed: ${validationErrors.join(', ')}`);
            }

            const enrichedData = {
                ...data,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            await db.collection(collection).doc(docId).update(enrichedData);
            console.log(`✅ Document ${docId} updated successfully`);
            return { id: docId, ...enrichedData };
        } catch (error) {
            console.error(`❌ Error updating document ${docId}:`, error);
            throw error;
        }
    }

    // Bulk update with progress tracking
    async bulkUpdate(collection, updates) {
        try {
            let batch = db.batch();
            let operationCount = 0;
            const results = [];

            for (let i = 0; i < updates.length; i++) {
                const { id, data } = updates[i];
                const enrichedData = {
                    ...data,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                };

                const docRef = db.collection(collection).doc(id);
                batch.update(docRef, enrichedData);
                results.push({ id, ...enrichedData });
                operationCount++;

                if (operationCount === this.batchSize) {
                    await batch.commit();
                    batch = db.batch();
                    operationCount = 0;
                    console.log(`✅ Batch updated: ${i + 1}/${updates.length} items processed`);
                }
            }

            if (operationCount > 0) {
                await batch.commit();
                console.log('✅ Final update batch committed');
            }

            return results;
        } catch (error) {
            console.error('❌ Error in bulk update:', error);
            throw error;
        }
    }

    // Safe delete with backup
    async deleteDocument(collection, docId) {
        try {
            // Backup document before deletion
            const docRef = db.collection(collection).doc(docId);
            const doc = await docRef.get();
            if (!doc.exists) {
                throw new Error(`Document ${docId} not found`);
            }

            const backupData = {
                ...doc.data(),
                originalId: docId,
                deletedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            // Store backup
            await db.collection(`${collection}_deleted`).add(backupData);

            // Delete original document
            await docRef.delete();
            console.log(`✅ Document ${docId} deleted and backed up successfully`);
            return { success: true, id: docId };
        } catch (error) {
            console.error(`❌ Error deleting document ${docId}:`, error);
            throw error;
        }
    }

    // Bulk delete with backup
    async bulkDelete(collection, docIds) {
        try {
            let batch = db.batch();
            let backupBatch = db.batch();
            let operationCount = 0;
            const results = [];

            for (let i = 0; i < docIds.length; i++) {
                const docId = docIds[i];
                const docRef = db.collection(collection).doc(docId);
                const doc = await docRef.get();

                if (doc.exists) {
                    // Backup document
                    const backupData = {
                        ...doc.data(),
                        originalId: docId,
                        deletedAt: admin.firestore.FieldValue.serverTimestamp()
                    };
                    const backupRef = db.collection(`${collection}_deleted`).doc();
                    backupBatch.set(backupRef, backupData);

                    // Delete original
                    batch.delete(docRef);
                    results.push({ success: true, id: docId });
                    operationCount++;

                    if (operationCount === this.batchSize) {
                        await Promise.all([batch.commit(), backupBatch.commit()]);
                        batch = db.batch();
                        backupBatch = db.batch();
                        operationCount = 0;
                        console.log(`✅ Batch deleted: ${i + 1}/${docIds.length} items processed`);
                    }
                }
            }

            if (operationCount > 0) {
                await Promise.all([batch.commit(), backupBatch.commit()]);
                console.log('✅ Final deletion batch committed');
            }

            return results;
        } catch (error) {
            console.error('❌ Error in bulk delete:', error);
            throw error;
        }
    }

    // Restore deleted document
    async restoreDocument(collection, originalId) {
        try {
            // Find backup
            const backupSnapshot = await db
                .collection(`${collection}_deleted`)
                .where('originalId', '==', originalId)
                .orderBy('deletedAt', 'desc')
                .limit(1)
                .get();

            if (backupSnapshot.empty) {
                throw new Error(`No backup found for document ${originalId}`);
            }

            const backupDoc = backupSnapshot.docs[0];
            const backupData = backupDoc.data();

            // Remove metadata fields
            const { originalId: _, deletedAt: __, ...restoreData } = backupData;

            // Restore document
            await db.collection(collection).doc(originalId).set({
                ...restoreData,
                restoredAt: admin.firestore.FieldValue.serverTimestamp()
            });

            // Delete backup
            await backupDoc.ref.delete();

            console.log(`✅ Document ${originalId} restored successfully`);
            return { success: true, id: originalId };
        } catch (error) {
            console.error(`❌ Error restoring document ${originalId}:`, error);
            throw error;
        }
    }

    // Add real-time listener for subcategories
    addSubcategoryListener(categoryId, callback) {
        if (this.listeners.has(categoryId)) {
            console.log(`ℹ️ Listener already exists for category ${categoryId}`);
            return;
        }

        const listener = db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .onSnapshot(snapshot => {
                const changes = [];
                snapshot.docChanges().forEach(change => {
                    const data = change.doc.data();
                    const id = change.doc.id;
                    
                    switch (change.type) {
                        case 'added':
                            changes.push({ type: 'added', id, data });
                            console.log(`✨ Subcategory added: ${data.name}`);
                            break;
                        case 'modified':
                            changes.push({ type: 'modified', id, data });
                            console.log(`📝 Subcategory modified: ${data.name}`);
                            break;
                        case 'removed':
                            changes.push({ type: 'removed', id, data });
                            console.log(`🗑️ Subcategory removed: ${data.name}`);
                            break;
                    }
                });

                callback(changes);
            }, error => {
                console.error(`❌ Error in subcategory listener: ${error}`);
            });

        this.listeners.set(categoryId, listener);
        console.log(`✅ Added listener for category ${categoryId}`);
    }

    // Remove listener
    removeSubcategoryListener(categoryId) {
        const listener = this.listeners.get(categoryId);
        if (listener) {
            listener();
            this.listeners.delete(categoryId);
            console.log(`✅ Removed listener for category ${categoryId}`);
        }
    }

    // Create subcategory with real-time update
    async createSubcategory(categoryId, data, requiredFields = []) {
        try {
            const validationErrors = this.validateData(data, requiredFields);
            if (validationErrors.length > 0) {
                throw new Error(`Validation failed: ${validationErrors.join(', ')}`);
            }

            const enrichedData = {
                ...data,
                categoryId,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                yayCount: 0,
                nayCount: 0,
                order: data.order || 0
            };

            // Create a batch to ensure atomic operations
            const batch = db.batch();

            // Add to nested subcategories collection
            const nestedRef = db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc();

            // Add to root subcategories collection with the same ID
            const rootRef = db.collection('subcategories').doc(nestedRef.id);

            // Set data in both locations
            batch.set(nestedRef, enrichedData);
            batch.set(rootRef, enrichedData);

            // Commit the batch
            await batch.commit();

            console.log(`✅ Subcategory created successfully with ID: ${nestedRef.id}`);
            return { id: nestedRef.id, ...enrichedData };
        } catch (error) {
            console.error('❌ Error creating subcategory:', error);
            throw error;
        }
    }

    // Update subcategory with real-time update
    async updateSubcategory(categoryId, subcategoryId, data, requiredFields = []) {
        try {
            const validationErrors = this.validateData(data, requiredFields);
            if (validationErrors.length > 0) {
                throw new Error(`Validation failed: ${validationErrors.join(', ')}`);
            }

            const enrichedData = {
                ...data,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            await db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId)
                .update(enrichedData);

            console.log(`✅ Subcategory ${subcategoryId} updated successfully`);
            return { id: subcategoryId, ...enrichedData };
        } catch (error) {
            console.error(`❌ Error updating subcategory ${subcategoryId}:`, error);
            throw error;
        }
    }

    // Delete subcategory with real-time update
    async deleteSubcategory(categoryId, subcategoryId) {
        try {
            const docRef = db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId);

            const doc = await docRef.get();
            if (!doc.exists) {
                throw new Error(`Subcategory ${subcategoryId} not found`);
            }

            // Backup before deletion
            const backupData = {
                ...doc.data(),
                originalId: subcategoryId,
                categoryId,
                deletedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            await db.collection('subcategories_deleted').add(backupData);
            await docRef.delete();

            console.log(`✅ Subcategory ${subcategoryId} deleted and backed up successfully`);
            return { success: true, id: subcategoryId };
        } catch (error) {
            console.error(`❌ Error deleting subcategory ${subcategoryId}:`, error);
            throw error;
        }
    }

    // Bulk create subcategories with real-time updates
    async bulkCreateSubcategories(categoryId, items, requiredFields = []) {
        try {
            const results = [];
            let batch = db.batch();
            let operationCount = 0;

            for (let i = 0; i < items.length; i++) {
                const validationErrors = this.validateData(items[i], requiredFields);
                if (validationErrors.length > 0) {
                    console.warn(`⚠️ Skipping item ${i + 1} due to validation errors:`, validationErrors);
                    continue;
                }

                const enrichedData = {
                    ...items[i],
                    categoryId,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                    yayCount: 0,
                    nayCount: 0
                };

                const docRef = db.collection('categories')
                    .doc(categoryId)
                    .collection('subcategories')
                    .doc();

                batch.set(docRef, enrichedData);
                results.push({ id: docRef.id, ...enrichedData });
                operationCount++;

                if (operationCount === this.batchSize) {
                    await batch.commit();
                    batch = db.batch();
                    operationCount = 0;
                    console.log(`✅ Batch committed: ${i + 1}/${items.length} items processed`);
                }
            }

            if (operationCount > 0) {
                await batch.commit();
                console.log('✅ Final batch committed');
            }

            return results;
        } catch (error) {
            console.error('❌ Error in bulk create:', error);
            throw error;
        }
    }
}

// Sync subcategories between nested and root collections
async function syncSubcategories() {
    try {
        console.log('Starting subcategory sync...');
        const batch = db.batch();
        let updateCount = 0;

        // Get all categories
        const categories = await db.collection('categories').get();
        
        // First, gather all nested subcategories
        const nestedSubcategories = new Map();
        for (const category of categories.docs) {
            const subcategories = await category.ref.collection('subcategories').get();
            subcategories.forEach(doc => {
                nestedSubcategories.set(doc.id, {
                    data: doc.data(),
                    categoryId: category.id
                });
            });
        }

        // Get all root subcategories
        const rootSubcategories = await db.collection('subcategories').get();
        
        // Sync root to nested
        for (const doc of rootSubcategories.docs) {
            const data = doc.data();
            const nestedData = nestedSubcategories.get(doc.id);
            
            if (!nestedData && data.categoryId) {
                // Root subcategory missing from nested
                batch.set(
                    db.collection('categories')
                        .doc(data.categoryId)
                        .collection('subcategories')
                        .doc(doc.id),
                    data
                );
                updateCount++;
            } else if (nestedData && JSON.stringify(data) !== JSON.stringify(nestedData.data)) {
                // Update nested to match root
                batch.set(
                    db.collection('categories')
                        .doc(data.categoryId)
                        .collection('subcategories')
                        .doc(doc.id),
                    data
                );
                updateCount++;
            }
        }

        // Sync nested to root
        for (const [id, {data, categoryId}] of nestedSubcategories) {
            const rootDoc = rootSubcategories.docs.find(doc => doc.id === id);
            if (!rootDoc) {
                // Nested subcategory missing from root
                batch.set(
                    db.collection('subcategories').doc(id),
                    {...data, categoryId}
                );
                updateCount++;
            }
        }

        if (updateCount > 0) {
            await batch.commit();
            console.log(`✅ Synchronized ${updateCount} subcategories`);
        } else {
            console.log('✅ All subcategories are already in sync');
        }

        return updateCount;
    } catch (error) {
        console.error('❌ Error syncing subcategories:', error);
        throw error;
    }
}

module.exports = new AutomatedCRUD(); 