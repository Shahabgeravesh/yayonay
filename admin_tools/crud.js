// Category CRUD Operations
async function addCategory(name, imageURL, order) {
    try {
        showOperationStatus('Adding new category...', 'Preparing data');
        debugLog('Adding new category:', { name, imageURL, order });

        // Check if Firebase is initialized (Safari-compatible check)
        if (!firebase || !firebase.app) {
            throw new Error('Firebase is not initialized');
        }

        // Check authentication status
        const currentUser = firebase.auth().currentUser;
        if (!currentUser) {
            throw new Error('User is not authenticated. Please log in again.');
        }
        debugLog('Current user:', currentUser.email);

        const categoryData = {
            name,
            imageURL: imageURL || 'https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_category.png?alt=media',
            order: parseInt(order),
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
            createdBy: currentUser.uid
        };

        showOperationStatus('Adding new category...', 'Connecting to database');
        const db = firebase.firestore();
        debugLog('Database instance obtained');
        
        // Verify database connection
        try {
            const testQuery = await db.collection('categories').limit(1).get();
            debugLog('Database connection verified, can read categories');
        } catch (dbError) {
            debugLog('Database connection error:', dbError);
            throw new Error('Database connection failed: ' + dbError.message);
        }
        
        showOperationStatus('Adding new category...', 'Saving category data');
        debugLog('Attempting to add category with data:', categoryData);

        try {
            const docRef = await db.collection('categories').add(categoryData);
            debugLog('Category added successfully with ID:', docRef.id);
            
            // Verify the category was actually created
            const newDoc = await docRef.get();
            if (!newDoc.exists) {
                throw new Error('Category document was not created');
            }
            debugLog('Category document verified to exist');

            showSuccess('Category added successfully!');
            
            showOperationStatus('Adding new category...', 'Refreshing category list');
            await loadCategories();
            
            hideOperationStatus();
            return docRef.id;
        } catch (writeError) {
            debugLog('Error writing to database:', writeError);
            throw new Error('Failed to write to database: ' + writeError.message);
        }
    } catch (error) {
        console.error('Error adding category:', error);
        debugLog('Error adding category:', error.message);
        showError('Error adding category: ' + error.message);
        hideOperationStatus();
        throw error;
    }
}

async function updateCategory(categoryId, name, imageURL, order) {
    try {
        const categoryData = {
            name,
            imageURL,
            order: parseInt(order),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        await firebase.firestore().collection('categories').doc(categoryId).update(categoryData);
        showSuccess('Category updated successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error updating category:', error);
        showError('Error updating category: ' + error.message);
    }
}

async function deleteCategory(categoryId) {
    try {
        // First, delete all subcategories
        const subcategoriesSnapshot = await firebase.firestore()
            .collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .get();

        const batch = firebase.firestore().batch();
        subcategoriesSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        // Then delete the category
        batch.delete(firebase.firestore().collection('categories').doc(categoryId));
        
        await batch.commit();
        showSuccess('Category deleted successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error deleting category:', error);
        showError('Error deleting category: ' + error.message);
    }
}

// Subcategory CRUD Operations
async function addSubcategory(categoryId, name, imageURL, order) {
    try {
        showOperationStatus('Adding new subcategory...', 'Preparing data');
        debugLog('Adding new subcategory:', { categoryId, name, imageURL, order });

        // Check if Firebase is initialized
        if (!firebase || !firebase.app) {
            throw new Error('Firebase is not initialized');
        }

        // Check authentication status
        const currentUser = firebase.auth().currentUser;
        if (!currentUser) {
            throw new Error('User is not authenticated. Please log in again.');
        }
        debugLog('Current user:', currentUser.email);

        const subcategoryData = {
            name,
            imageURL: imageURL || 'https://firebasestorage.googleapis.com/v0/b/yayonay-e7f58.appspot.com/o/default_subcategory.png?alt=media',
            order: parseInt(order),
            categoryId,
            yayCount: 0,
            nayCount: 0,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
            createdBy: currentUser.uid
        };

        showOperationStatus('Adding new subcategory...', 'Connecting to database');
        const db = firebase.firestore();
        debugLog('Database instance obtained');

        // Verify database connection and category existence
        try {
            const categoryDoc = await db.collection('categories').doc(categoryId).get();
            if (!categoryDoc.exists) {
                throw new Error('Parent category does not exist');
            }
            debugLog('Parent category verified');
        } catch (dbError) {
            debugLog('Database verification error:', dbError);
            throw new Error('Database verification failed: ' + dbError.message);
        }

        showOperationStatus('Adding new subcategory...', 'Saving subcategory data');
        debugLog('Attempting to add subcategory with data:', subcategoryData);

        // Create in both locations using a batch
        const batch = db.batch();
        
        // Create in root subcategories collection
        const rootRef = db.collection('subcategories').doc();
        batch.set(rootRef, subcategoryData);
        
        // Create in nested subcategories collection
        const nestedRef = db
            .collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(rootRef.id);
        batch.set(nestedRef, subcategoryData);

        await batch.commit();
        debugLog('Subcategory added successfully with ID:', rootRef.id);

        // Verify the subcategory was actually created
        const newDoc = await nestedRef.get();
        if (!newDoc.exists) {
            throw new Error('Subcategory document was not created');
        }
        debugLog('Subcategory document verified to exist');

        showSuccess('Subcategory added successfully!');
        
        showOperationStatus('Adding new subcategory...', 'Refreshing category list');
        await loadCategories();
        
        hideOperationStatus();
        return rootRef.id;
    } catch (error) {
        console.error('Error adding subcategory:', error);
        debugLog('Error adding subcategory:', error.message);
        showError('Error adding subcategory: ' + error.message);
        hideOperationStatus();
        throw error;
    }
}

async function updateSubcategory(categoryId, subcategoryId, name, imageURL, order) {
    try {
        showOperationStatus('Updating subcategory...', 'Preparing data');
        debugLog('Updating subcategory:', { categoryId, subcategoryId, name, imageURL, order });

        const subcategoryData = {
            name,
            imageURL,
            order: parseInt(order),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        const db = firebase.firestore();

        // Verify subcategory exists
        const subcategoryDoc = await db
            .collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .get();

        if (!subcategoryDoc.exists) {
            throw new Error('Subcategory does not exist');
        }

        showOperationStatus('Updating subcategory...', 'Saving changes');

        // Update in both locations using a batch
        const batch = db.batch();
        
        // Update in root subcategories collection
        batch.update(
            db.collection('subcategories').doc(subcategoryId),
            subcategoryData
        );
        
        // Update in nested subcategories collection
        batch.update(
            db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId),
            subcategoryData
        );

        await batch.commit();
        debugLog('Subcategory updated successfully');

        showSuccess('Subcategory updated successfully!');
        await loadCategories();
        hideOperationStatus();
    } catch (error) {
        console.error('Error updating subcategory:', error);
        debugLog('Error updating subcategory:', error.message);
        showError('Error updating subcategory: ' + error.message);
        hideOperationStatus();
    }
}

async function deleteSubcategory(categoryId, subcategoryId) {
    try {
        showOperationStatus('Deleting subcategory...', 'Verifying data');
        debugLog('Deleting subcategory:', { categoryId, subcategoryId });

        const db = firebase.firestore();

        // Verify subcategory exists
        const subcategoryDoc = await db
            .collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .get();

        if (!subcategoryDoc.exists) {
            throw new Error('Subcategory does not exist');
        }

        showOperationStatus('Deleting subcategory...', 'Removing data');

        // Delete from both locations using a batch
        const batch = db.batch();
        
        // Delete from root subcategories collection
        batch.delete(db.collection('subcategories').doc(subcategoryId));
        
        // Delete from nested subcategories collection
        batch.delete(
            db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId)
        );

        await batch.commit();
        debugLog('Subcategory deleted successfully');

        showSuccess('Subcategory deleted successfully!');
        await loadCategories();
        hideOperationStatus();
    } catch (error) {
        console.error('Error deleting subcategory:', error);
        debugLog('Error deleting subcategory:', error.message);
        showError('Error deleting subcategory: ' + error.message);
        hideOperationStatus();
    }
}

// Modal Functions
function showAddCategoryModal() {
    document.getElementById('modalTitle').textContent = 'Add New Category';
    document.getElementById('categoryId').value = '';
    document.getElementById('categoryForm').reset();
    new bootstrap.Modal(document.getElementById('categoryModal')).show();
}

function showEditCategoryModal(category) {
    document.getElementById('modalTitle').textContent = 'Edit Category';
    document.getElementById('categoryId').value = category.id;
    document.getElementById('categoryName').value = category.name;
    document.getElementById('categoryImage').value = category.imageURL;
    document.getElementById('categoryOrder').value = category.order;
    new bootstrap.Modal(document.getElementById('categoryModal')).show();
}

function showAddSubcategoryModal() {
    document.getElementById('subcategoryModalTitle').textContent = 'Add New Subcategory';
    document.getElementById('subcategoryId').value = '';
    document.getElementById('subcategoryForm').reset();
    new bootstrap.Modal(document.getElementById('subcategoryModal')).show();
}

function showEditSubcategoryModal(categoryId, subcategory) {
    document.getElementById('subcategoryModalTitle').textContent = 'Edit Subcategory';
    document.getElementById('subcategoryId').value = subcategory.id;
    document.getElementById('parentCategory').value = categoryId;
    document.getElementById('subcategoryName').value = subcategory.name;
    document.getElementById('subcategoryImage').value = subcategory.imageURL;
    document.getElementById('subcategoryOrder').value = subcategory.order;
    new bootstrap.Modal(document.getElementById('subcategoryModal')).show();
}

// Form Submission Handlers
async function saveCategory() {
    const button = event.target;
    try {
        setButtonLoading(button, true);
        showLoading('Validating form data...');

        const form = document.getElementById('categoryForm');
        if (!form.checkValidity()) {
            form.classList.add('was-validated');
            showWarning('Please fill in all required fields correctly');
            return;
        }

        const categoryId = document.getElementById('categoryId').value;
        const name = document.getElementById('categoryName').value.trim();
        const imageURL = document.getElementById('categoryImage').value.trim();
        const order = parseInt(document.getElementById('categoryOrder').value);

        if (!name) {
            showError('Category name is required');
            return;
        }

        if (order < 0) {
            showError('Order must be a positive number');
            return;
        }

        showLoading(categoryId ? 'Updating category...' : 'Adding new category...');
        debugLog('Saving category:', { name, imageURL, order });

        if (categoryId) {
            await updateCategory(categoryId, name, imageURL, order);
        } else {
            await addCategory(name, imageURL, order);
        }

        form.classList.remove('was-validated');
        
        const modal = bootstrap.Modal.getInstance(document.getElementById('categoryModal'));
        if (modal) {
            modal.hide();
        }

        await loadCategories();
        
        debugLog('Category saved successfully');
        showSuccess(categoryId ? 'Category updated successfully!' : 'Category added successfully!');
    } catch (error) {
        console.error('Error saving category:', error);
        debugLog('Error saving category: ' + error.message);
        showError('Failed to save category: ' + error.message);
    } finally {
        setButtonLoading(button, false);
        hideLoading();
    }
}

async function saveSubcategory() {
    const button = event.target;
    try {
        setButtonLoading(button, true);
        showLoading('Validating form data...');

        const form = document.getElementById('subcategoryForm');
        if (!form.checkValidity()) {
            form.classList.add('was-validated');
            showWarning('Please fill in all required fields correctly');
            return;
        }

        const subcategoryId = document.getElementById('subcategoryId').value;
        const categoryId = document.getElementById('parentCategory').value;
        const name = document.getElementById('subcategoryName').value.trim();
        const imageURL = document.getElementById('subcategoryImage').value.trim();
        const order = document.getElementById('subcategoryOrder').value;

        if (!categoryId) {
            showError('Parent category is required');
            return;
        }

        if (!name) {
            showError('Subcategory name is required');
            return;
        }

        showLoading(subcategoryId ? 'Updating subcategory...' : 'Adding new subcategory...');

        if (subcategoryId) {
            await updateSubcategory(categoryId, subcategoryId, name, imageURL, order);
        } else {
            await addSubcategory(categoryId, name, imageURL, order);
        }

        const modal = bootstrap.Modal.getInstance(document.getElementById('subcategoryModal'));
        if (modal) {
            modal.hide();
        }

        showSuccess(subcategoryId ? 'Subcategory updated successfully!' : 'Subcategory added successfully!');
    } catch (error) {
        console.error('Error saving subcategory:', error);
        showError('Failed to save subcategory: ' + error.message);
    } finally {
        setButtonLoading(button, false);
        hideLoading();
    }
}

// Category Management Functions
async function loadCategories() {
    try {
        debugLog('Starting to load categories...');
        const categoryList = document.getElementById('categoryList');
        if (!categoryList) {
            throw new Error('Category list element not found');
        }

        showLoading('Loading categories...');
        categoryList.innerHTML = '<div class="text-center"><div class="spinner-border" role="status"></div><div class="mt-2">Loading categories...</div></div>';

        // Check authentication
        const currentUser = firebase.auth().currentUser;
        if (!currentUser) {
            throw new Error('User is not authenticated. Please log in again.');
        }
        debugLog('Current user:', currentUser.email);

        const db = firebase.firestore();
        showOperationStatus('Loading categories...', 'Fetching from database');
        
        debugLog('Executing categories query...');
        const snapshot = await db.collection('categories').orderBy('order').get();
        debugLog(`Found ${snapshot.size} categories`);
        
        const categories = [];

        showOperationStatus('Loading categories...', 'Processing category data');
        for (const doc of snapshot.docs) {
            const category = { id: doc.id, ...doc.data() };
            debugLog('Processing category:', category.name);
            
            showOperationStatus('Loading categories...', `Loading subcategories for ${category.name}`);
            const subcategoriesSnapshot = await db.collection('categories')
                .doc(doc.id)
                .collection('subcategories')
                .orderBy('order')
                .get();
            
            category.subcategories = subcategoriesSnapshot.docs.map(subdoc => ({
                id: subdoc.id,
                ...subdoc.data()
            }));
            
            debugLog(`Found ${category.subcategories.length} subcategories for ${category.name}`);
            categories.push(category);
        }

        debugLog('Categories loaded:', categories.length);
        showOperationStatus('Loading categories...', 'Rendering category list');

        if (categories.length === 0) {
            debugLog('No categories found in database');
            categoryList.innerHTML = `
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    No categories found. Click the "Add Category" button to create your first category.
                </div>
            `;
        } else {
            // Display categories
            categoryList.innerHTML = categories.map(category => `
                <div class="category-card" data-category-id="${category.id}">
                    <div class="d-flex align-items-center">
                        <span class="order-number">${category.order}</span>
                        <img src="${category.imageURL || 'https://via.placeholder.com/60'}" alt="${category.name}" class="category-image">
                        <div class="flex-grow-1">
                            <h5 class="mb-0">${category.name}</h5>
                            <small class="text-muted">${category.subcategories?.length || 0} subcategories</small>
                        </div>
                        <div class="btn-group">
                            <button class="btn btn-outline-primary btn-sm" onclick="showEditCategoryModal(${JSON.stringify(category).replace(/"/g, '&quot;')})">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button class="btn btn-outline-danger btn-sm" onclick="deleteCategory('${category.id}')">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    </div>
                    ${category.subcategories?.length ? `
                        <div class="subcategory-list">
                            ${category.subcategories.map(subcategory => `
                                <div class="subcategory-card" data-subcategory-id="${subcategory.id}">
                                    <div class="d-flex align-items-center">
                                        <span class="order-number">${subcategory.order}</span>
                                        <img src="${subcategory.imageURL || 'https://via.placeholder.com/40'}" alt="${subcategory.name}" class="category-image" style="width: 40px; height: 40px;">
                                        <div class="flex-grow-1">
                                            <h6 class="mb-0">${subcategory.name}</h6>
                                        </div>
                                        <div class="btn-group">
                                            <button class="btn btn-outline-primary btn-sm" onclick="showEditSubcategoryModal('${category.id}', ${JSON.stringify(subcategory).replace(/"/g, '&quot;')})">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button class="btn btn-outline-danger btn-sm" onclick="deleteSubcategory('${category.id}', '${subcategory.id}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    ` : ''}
                </div>
            `).join('');
        }

        hideOperationStatus();
        hideLoading();
        showSuccess(`Loaded ${categories.length} categories successfully`);
    } catch (error) {
        console.error('Error loading categories:', error);
        debugLog('Error loading categories:', error.message);
        showError('Error loading categories: ' + error.message);
        
        if (categoryList) {
            categoryList.innerHTML = `
                <div class="alert alert-danger">
                    <i class="fas fa-exclamation-circle"></i> Failed to load categories: ${error.message}
                    <button class="btn btn-outline-danger btn-sm mt-2" onclick="loadCategories()">
                        <i class="fas fa-sync"></i> Retry
                    </button>
                </div>
            `;
        }
        hideLoading();
        hideOperationStatus();
    }
}

// Subquestions CRUD Operations
window.subquestionsCRUD = {
    create: async function(categoryId, subcategoryId, data) {
        try {
            if (!categoryId || !subcategoryId || !data.question) {
                throw new Error('Missing required fields');
            }

            const db = firebase.firestore();
            const subquestionsRef = db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId)
                .collection('subquestions');

            // Add timestamp and defaults
            const subquestionData = {
                ...data,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
                yayCount: 0,
                nayCount: 0,
                votesMetadata: {
                    totalVotes: 0,
                    uniqueVoters: 0
                }
            };

            const docRef = await subquestionsRef.add(subquestionData);
            return docRef.id;
        } catch (error) {
            console.error('Error creating subquestion:', error);
            throw error;
        }
    },

    update: async function(categoryId, subcategoryId, subquestionId, data) {
        try {
            if (!categoryId || !subcategoryId || !subquestionId) {
                throw new Error('Missing required IDs');
            }

            const db = firebase.firestore();
            const subquestionRef = db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId)
                .collection('subquestions')
                .doc(subquestionId);

            // Add updated timestamp
            const updateData = {
                ...data,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            await subquestionRef.update(updateData);
        } catch (error) {
            console.error('Error updating subquestion:', error);
            throw error;
        }
    },

    delete: async function(categoryId, subcategoryId, subquestionId) {
        try {
            if (!categoryId || !subcategoryId || !subquestionId) {
                throw new Error('Missing required IDs');
            }

            const db = firebase.firestore();
            const subquestionRef = db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId)
                .collection('subquestions')
                .doc(subquestionId);

            await subquestionRef.delete();
        } catch (error) {
            console.error('Error deleting subquestion:', error);
            throw error;
        }
    },

    get: async function(categoryId, subcategoryId, subquestionId) {
        try {
            if (!categoryId || !subcategoryId || !subquestionId) {
                throw new Error('Missing required IDs');
            }

            const db = firebase.firestore();
            const subquestionRef = db.collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId)
                .collection('subquestions')
                .doc(subquestionId);

            const doc = await subquestionRef.get();
            if (!doc.exists) {
                throw new Error('Subquestion not found');
            }

            return {
                id: doc.id,
                ...doc.data()
            };
        } catch (error) {
            console.error('Error getting subquestion:', error);
            throw error;
        }
    }
};