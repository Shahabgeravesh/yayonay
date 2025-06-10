// Constants
const DEFAULT_IMAGES = {
    category: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjYwIiBoZWlnaHQ9IjYwIiBmaWxsPSIjZTllY2VmIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtc2l6ZT0iMTIiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGFsaWdubWVudC1iYXNlbGluZT0ibWlkZGxlIiBmb250LWZhbWlseT0ic2Fucy1zZXJpZiIgZmlsbD0iIzZjNzU3ZCI+Q2F0ZWdvcnk8L3RleHQ+PC9zdmc+',
    subcategory: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjQwIiBoZWlnaHQ9IjQwIiBmaWxsPSIjZTllY2VmIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtc2l6ZT0iOCIgdGV4dC1hbmNob3I9Im1pZGRsZSIgYWxpZ25tZW50LWJhc2VsaW5lPSJtaWRkbGUiIGZvbnQtZmFtaWx5PSJzYW5zLXNlcmlmIiBmaWxsPSIjNmM3NTdkIj5TdWJjYXRlZ29yeTwvdGV4dD48L3N2Zz4='
};

// Add utility functions at the top of the file
function showWarning(message) {
    const toast = document.getElementById('warningToast');
    const messageEl = document.getElementById('warningToastMessage');
    if (toast && messageEl) {
        messageEl.textContent = message;
        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();
    } else {
        console.warn(message);
    }
}

function showLoading(message = 'Loading...') {
    document.getElementById('loadingMessage').textContent = message;
    document.getElementById('loadingOverlay').style.display = 'flex';
}

function hideLoading() {
    document.getElementById('loadingOverlay').style.display = 'none';
}

function showOperationStatus(message, details = '') {
    const statusDiv = document.querySelector('.operation-status');
    if (statusDiv) {
        const messageDiv = statusDiv.querySelector('.status-message');
        const detailsDiv = statusDiv.querySelector('.status-details');
        if (messageDiv) messageDiv.textContent = message;
        if (detailsDiv) detailsDiv.textContent = details;
        statusDiv.style.display = 'block';
    }
}

function hideOperationStatus() {
    const statusDiv = document.querySelector('.operation-status');
    if (statusDiv) {
        statusDiv.style.display = 'none';
    }
}

function setButtonLoading(button, isLoading) {
    if (!button) return;
    
    if (isLoading) {
        button.disabled = true;
        button.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Loading...';
    } else {
        button.disabled = false;
        button.innerHTML = button.getAttribute('data-original-text') || 'Save';
    }
}

function handleImageError(img, type) {
    img.onerror = null; // Prevent infinite loop
    img.src = window.DEFAULT_IMAGES[type];
}

function renderCategoryImage(imageURL, name, type = 'category') {
    const size = type === 'category' ? '60px' : '40px';
    return `<img src="${imageURL || window.DEFAULT_IMAGES[type]}" 
                 alt="${name}" 
                 class="category-image" 
                 style="${type === 'subcategory' ? `width: ${size}; height: ${size};` : ''}"
                 onerror="handleImageError(this, '${type}')">`;
}

// Debug logging function
function debugLog(...args) {
    if (process.env.NODE_ENV === 'development') {
        console.log('[DEBUG]', ...args);
    }
}

// CRUD operations for admin panel
const crud = {
    // Load data based on type
    async loadData(type) {
        try {
            showLoading('Loading data...');
            const db = firebase.firestore();
            let query;
            
            // Convert singular to plural for collection names
            let collectionType;
            switch (type) {
                case 'category':
                case 'categories':
                    collectionType = 'categories';
                    break;
                case 'subcategory':
                case 'subcategories':
                    collectionType = 'subcategories';
                    break;
                case 'subquestion':
                case 'subquestions':
                    collectionType = 'subquestions';
                    break;
                default:
                    throw new Error(`Invalid type: ${type}`);
            }
            
            switch(collectionType) {
                case 'categories':
                    query = db.collection('categories').orderBy('order');
                    break;
                case 'subcategories':
                    const categoryId = document.getElementById('categoryId')?.value;
                    if (!categoryId) {
                        throw new Error('Please select a category first');
                    }
                    query = db.collection('categories').doc(categoryId).collection('subcategories').orderBy('order');
                    break;
                case 'subquestions':
                    const subcategoryId = document.getElementById('subCategoryId')?.value;
                    if (!subcategoryId) {
                        throw new Error('Please select a subcategory first');
                    }
                    const categoryIdForSub = document.getElementById('categoryId')?.value;
                    if (!categoryIdForSub) {
                        throw new Error('Please select a category first');
                    }
                    query = db.collection('categories').doc(categoryIdForSub)
                        .collection('subcategories').doc(subcategoryId)
                        .collection('subquestions');
                    break;
                default:
                    throw new Error(`Invalid type: ${type}`);
            }

            const snapshot = await query.get();
            const items = [];
            snapshot.forEach(doc => {
                items.push({
                    id: doc.id,
                    ...doc.data()
                });
            });

            this.displayData(collectionType, items);
            hideLoading();
            return items;
        } catch (error) {
            console.error('Error loading data:', error);
            showError('Failed to load data: ' + error.message);
            hideLoading();
            throw error;
        }
    },

    // Add new item
    async addItem(type, data) {
        try {
            showLoading('Adding item...');
            const db = firebase.firestore();
            let docRef;

            switch (type) {
                case 'category':
                    docRef = await db.collection('categories').add({
                        name: data.name,
                        imageURL: data.imageURL || DEFAULT_IMAGES.category,
                        order: parseInt(data.order) || 0,
                        description: data.description || '',
                        featured: data.featured || false,
                        isTopCategory: data.isTopCategory || false,
                        votesCount: 0,
                        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    break;
                case 'subcategory':
                    if (!data.categoryId) throw new Error('Category ID is required');
                    docRef = await db.collection('categories').doc(data.categoryId).collection('subcategories').add({
                        name: data.name,
                        imageURL: data.imageURL || DEFAULT_IMAGES.subcategory,
                        order: parseInt(data.order) || 0,
                        yayCount: 0,
                        nayCount: 0,
                        attributes: data.attributes || {},
                        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    break;
                case 'subquestion':
                    if (!data.categoryId || !data.subCategoryId) throw new Error('Category ID and Subcategory ID are required');
                    docRef = await db.collection('categories').doc(data.categoryId).collection('subcategories').doc(data.subCategoryId).collection('subquestions').add({
                        question: data.question,
                        yayCount: 0,
                        nayCount: 0,
                        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    break;
                default:
                    throw new Error(`Invalid type: ${type}`);
            }

            showSuccess('Item added successfully!');
            await this.loadData(type);
            hideLoading();
            return docRef.id;
        } catch (error) {
            console.error('Error adding item:', error);
            showError('Failed to add item: ' + error.message);
            hideLoading();
            throw error;
        }
    },

    // Update existing item
    async updateItem(type, id, data) {
        try {
            showLoading('Updating item...');
            const db = firebase.firestore();
            let docRef;

            // Convert singular to plural for collection names
            let collectionType;
            switch (type) {
                case 'category':
                case 'categories':
                    collectionType = 'categories';
                    break;
                case 'subcategory':
                case 'subcategories':
                    collectionType = 'subcategories';
                    break;
                case 'subquestion':
                case 'subquestions':
                    collectionType = 'subquestions';
                    break;
                default:
                    throw new Error(`Invalid type: ${type}`);
            }

            switch (type) {
                case 'category':
                    docRef = db.collection('categories').doc(id);
                    await docRef.update({
                        name: data.name,
                        imageURL: data.imageURL,
                        order: parseInt(data.order) || 0,
                        description: data.description || '',
                        featured: data.featured || false,
                        isTopCategory: data.isTopCategory || false,
                        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    break;
                case 'subcategory':
                    if (!data.categoryId) throw new Error('Category ID is required');
                    docRef = db.collection('categories').doc(data.categoryId).collection('subcategories').doc(id);
                    await docRef.update({
                        name: data.name,
                        imageURL: data.imageURL,
                        order: parseInt(data.order) || 0,
                        attributes: data.attributes || {},
                        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    break;
                case 'subquestion':
                    if (!data.categoryId || !data.subCategoryId) throw new Error('Category ID and Subcategory ID are required');
                    docRef = db.collection('categories').doc(data.categoryId).collection('subcategories').doc(data.subCategoryId).collection('subquestions').doc(id);
                    await docRef.update({
                        question: data.question,
                        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    break;
                default:
                    throw new Error(`Invalid type: ${type}`);
            }

            showSuccess('Item updated successfully!');
            await this.loadData(collectionType);
            hideLoading();
        } catch (error) {
            console.error('Error updating item:', error);
            showError('Failed to update item: ' + error.message);
            hideLoading();
        }
    },

    // Delete item
    async deleteItem(type, id, data) {
        try {
            showLoading('Deleting item...');
            const db = firebase.firestore();
            let docRef;

            // Convert singular to plural for collection names
            let collectionType;
            switch (type) {
                case 'category':
                case 'categories':
                    collectionType = 'categories';
                    break;
                case 'subcategory':
                case 'subcategories':
                    collectionType = 'subcategories';
                    break;
                case 'subquestion':
                case 'subquestions':
                    collectionType = 'subquestions';
                    break;
                default:
                    throw new Error(`Invalid type: ${type}`);
            }

            switch (type) {
                case 'category':
                    // Delete all subcategories and their subquestions
                    const subcategoriesSnapshot = await db.collection('categories').doc(id).collection('subcategories').get();
                    const batch = db.batch();
                    
                    for (const subcategoryDoc of subcategoriesSnapshot.docs) {
                        // Delete all subquestions
                        const subquestionsSnapshot = await subcategoryDoc.ref.collection('subquestions').get();
                        subquestionsSnapshot.docs.forEach(doc => {
                            batch.delete(doc.ref);
                        });
                        // Delete subcategory
                        batch.delete(subcategoryDoc.ref);
                    }
                    
                    // Delete category
                    batch.delete(db.collection('categories').doc(id));
                    await batch.commit();
                    break;
                case 'subcategory':
                    if (!data.categoryId) throw new Error('Category ID is required');
                    // Delete all subquestions
                    const subquestionsSnapshot = await db.collection('categories').doc(data.categoryId).collection('subcategories').doc(id).collection('subquestions').get();
                    const subBatch = db.batch();
                    subquestionsSnapshot.docs.forEach(doc => {
                        subBatch.delete(doc.ref);
                    });
                    // Delete subcategory
                    subBatch.delete(db.collection('categories').doc(data.categoryId).collection('subcategories').doc(id));
                    await subBatch.commit();
                    break;
                case 'subquestion':
                    if (!data.categoryId || !data.subCategoryId) throw new Error('Category ID and Subcategory ID are required');
                    await db.collection('categories').doc(data.categoryId).collection('subcategories').doc(data.subCategoryId).collection('subquestions').doc(id).delete();
                    break;
                default:
                    throw new Error(`Invalid type: ${type}`);
            }

            showSuccess('Item deleted successfully!');
            await this.loadData(collectionType);
            hideLoading();
        } catch (error) {
            console.error('Error deleting item:', error);
            showError('Failed to delete item: ' + error.message);
            hideLoading();
            throw error;
        }
    },

    // Display data in the table
    displayData(type, data) {
        const tableId = `${type}Table`;
        const tbody = document.querySelector(`#${tableId} tbody`);
        if (!tbody) return;

        tbody.innerHTML = '';
        data.forEach(item => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${item.name || item.question || ''}</td>
                <td>${item.subcategories || item.category || ''}</td>
                <td>${item.subquestions || ''}</td>
                <td>
                    <button class="btn btn-sm btn-primary edit-btn" data-id="${item.id}" data-type="${type}">
                        <i class="fas fa-edit"></i> Edit
                    </button>
                    <button class="btn btn-sm btn-danger delete-btn" data-id="${item.id}" data-type="${type}">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </td>
            `;
            tbody.appendChild(row);
        });

        // Add event listeners for edit and delete buttons
        tbody.querySelectorAll('.edit-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = e.target.closest('.edit-btn').dataset.id;
                const type = e.target.closest('.edit-btn').dataset.type;
                const item = data.find(item => item.id === id);
                if (item) {
                    showEditModal(type, id, item);
                }
            });
        });

        tbody.querySelectorAll('.delete-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const id = e.target.closest('.delete-btn').dataset.id;
                const type = e.target.closest('.delete-btn').dataset.type;
                const item = data.find(item => item.id === id);
                if (item) {
                    showConfirmDelete(type, id, item.name || item.question);
                }
            });
        });
    },

    // Edit item (opens modal)
    editItem(type, id, data) {
        const modal = document.getElementById('itemModal');
        const modalTitle = modal.querySelector('.modal-title');
        const form = document.getElementById('itemForm');

        modalTitle.textContent = `Edit ${type.charAt(0).toUpperCase() + type.slice(1)}`;
        form.innerHTML = this.getFormFields(type, data);
        form.dataset.id = id;
        form.dataset.type = type;

        const modalInstance = new bootstrap.Modal(modal);
        modalInstance.show();
    },

    // Get form fields based on type
    getFormFields(type, data = {}) {
        switch (type) {
            case 'category':
                return `
                    <div class="mb-3">
                        <label for="name" class="form-label">Name</label>
                        <input type="text" class="form-control" id="name" name="name" value="${data.name || ''}" required>
                    </div>
                    <div class="mb-3">
                        <label for="imageURL" class="form-label">Image URL</label>
                        <input type="url" class="form-control" id="imageURL" name="imageURL" value="${data.imageURL || ''}">
                    </div>
                    <div class="mb-3">
                        <label for="order" class="form-label">Order</label>
                        <input type="number" class="form-control" id="order" name="order" value="${data.order || 0}" required>
                    </div>
                    <div class="mb-3">
                        <label for="description" class="form-label">Description</label>
                        <textarea class="form-control" id="description" name="description">${data.description || ''}</textarea>
                    </div>
                    <div class="mb-3 form-check">
                        <input type="checkbox" class="form-check-input" id="featured" name="featured" ${data.featured ? 'checked' : ''}>
                        <label class="form-check-label" for="featured">Featured</label>
                    </div>
                    <div class="mb-3 form-check">
                        <input type="checkbox" class="form-check-input" id="isTopCategory" name="isTopCategory" ${data.isTopCategory ? 'checked' : ''}>
                        <label class="form-check-label" for="isTopCategory">Top Category</label>
                    </div>
                `;
            case 'subcategory':
                return `
                    <div class="mb-3">
                        <label for="categoryId" class="form-label">Category</label>
                        <select class="form-select" id="categoryId" name="categoryId" required>
                            <option value="">Select Category</option>
                            ${this.getCategoryOptions(data.categoryId)}
                        </select>
                    </div>
                    <div class="mb-3">
                        <label for="name" class="form-label">Name</label>
                        <input type="text" class="form-control" id="name" name="name" value="${data.name || ''}" required>
                    </div>
                    <div class="mb-3">
                        <label for="imageURL" class="form-label">Image URL</label>
                        <input type="url" class="form-control" id="imageURL" name="imageURL" value="${data.imageURL || ''}">
                    </div>
                    <div class="mb-3">
                        <label for="order" class="form-label">Order</label>
                        <input type="number" class="form-control" id="order" name="order" value="${data.order || 0}" required>
                    </div>
                    <div class="mb-3">
                        <label for="attributes" class="form-label">Attributes (JSON)</label>
                        <textarea class="form-control" id="attributes" name="attributes">${JSON.stringify(data.attributes || {}, null, 2)}</textarea>
                    </div>
                `;
            case 'subquestion':
                return `
                    <div class="mb-3">
                        <label for="categoryId" class="form-label">Category</label>
                        <select class="form-select" id="categoryId" name="categoryId" required>
                            <option value="">Select Category</option>
                            ${this.getCategoryOptions(data.categoryId)}
                        </select>
                    </div>
                    <div class="mb-3">
                        <label for="subCategoryId" class="form-label">Subcategory</label>
                        <select class="form-select" id="subCategoryId" name="subCategoryId" required>
                            <option value="">Select Subcategory</option>
                            ${this.getSubcategoryOptions(data.categoryId, data.subCategoryId)}
                        </select>
                    </div>
                    <div class="mb-3">
                        <label for="question" class="form-label">Question</label>
                        <input type="text" class="form-control" id="question" name="question" value="${data.question || ''}" required>
                    </div>
                `;
            default:
                throw new Error(`Invalid type: ${type}`);
        }
    },

    // Get category options for dropdown
    async getCategoryOptions(selectedId = '') {
        const db = firebase.firestore();
        const categoriesSnapshot = await db.collection('categories').orderBy('order').get();
        let options = '';
        categoriesSnapshot.docs.forEach(doc => {
            const data = doc.data();
            options += `<option value="${doc.id}" ${doc.id === selectedId ? 'selected' : ''}>${data.name}</option>`;
        });
        return options;
    },

    // Get subcategory options for dropdown
    async getSubcategoryOptions(categoryId, selectedId = '') {
        if (!categoryId) return '';
        const db = firebase.firestore();
        const subcategoriesSnapshot = await db.collection('categories').doc(categoryId).collection('subcategories').orderBy('order').get();
        let options = '';
        subcategoriesSnapshot.docs.forEach(doc => {
            const data = doc.data();
            options += `<option value="${doc.id}" ${doc.id === selectedId ? 'selected' : ''}>${data.name}</option>`;
        });
        return options;
    }
};

// Save item (called from modal)
async function saveItem() {
    const form = document.getElementById('itemForm');
    if (!form) return;

    try {
        const type = form.dataset.type;
        const id = form.dataset.id;
        const formData = new FormData(form);
        const data = {};

        // Debug logging
        console.log('Form type:', type);
        console.log('Form ID:', id);
        console.log('Form elements:', form.elements);

        // Log all form data
        for (const [key, value] of formData.entries()) {
            console.log(`Form field - ${key}:`, value);
        }

        // Validate required fields based on type
        const requiredFields = type === 'subquestion' ? ['question'] : ['name'];
        console.log('Required fields:', requiredFields);

        for (const field of requiredFields) {
            const value = formData.get(field);
            console.log(`Checking required field ${field}:`, value);
            if (!value) {
                throw new Error(`${field.charAt(0).toUpperCase() + field.slice(1)} is required`);
            }
            data[field] = value;
        }

        // Collect other fields
        for (const [key, value] of formData.entries()) {
            console.log(`Processing field ${key}:`, value);
            if (key === 'featured' || key === 'isTopCategory' || key === 'isActive') {
                data[key] = value === 'on';
            } else if (key === 'attributes') {
                try {
                    data[key] = JSON.parse(value);
                } catch (e) {
                    data[key] = {};
                }
            } else if (key === 'order') {
                data[key] = parseInt(value) || 0;
            } else if (key === 'imageURL') {
                data[key] = value || DEFAULT_IMAGES[type];
            } else if (!requiredFields.includes(key)) { // Skip required fields as they're already handled
                data[key] = value;
            }
        }

        // Add default values for required fields
        if (!data.imageURL) {
            data.imageURL = DEFAULT_IMAGES[type];
        }
        if (typeof data.order !== 'number') {
            data.order = 0;
        }
        if (typeof data.featured !== 'boolean') {
            data.featured = false;
        }
        if (typeof data.isTopCategory !== 'boolean') {
            data.isTopCategory = false;
        }

        console.log('Final data object:', data);

        if (!type) {
            throw new Error('Type is required');
        }

        if (id) {
            await crud.updateItem(type, id, data);
        } else {
            await crud.addItem(type, data);
        }

        const modal = bootstrap.Modal.getInstance(document.getElementById('itemModal'));
        modal.hide();
    } catch (error) {
        console.error('Error saving item:', error);
        showError('Failed to save item: ' + error.message);
    }
}

// Show add modal
function showAddModal(type) {
    const modal = document.getElementById('itemModal');
    const modalTitle = modal.querySelector('.modal-title');
    const form = document.getElementById('itemForm');

    modalTitle.textContent = `Add ${type.charAt(0).toUpperCase() + type.slice(1)}`;
    form.innerHTML = crud.getFormFields(type);
    form.dataset.id = '';
    form.dataset.type = type;

    const modalInstance = new bootstrap.Modal(modal);
    modalInstance.show();
}

// Initialize CRUD operations
document.addEventListener('DOMContentLoaded', function() {
    crud.loadData('categories');
});

// Category CRUD Operations
async function addCategory(data) {
    try {
        showLoading('Adding new category...');
        const db = firebase.firestore();
        
        const categoryData = {
            name: data.name,
            imageURL: data.imageURL || DEFAULT_IMAGES.category,
            order: parseInt(data.order) || 0,
            description: data.description || '',
            featured: data.featured || false,
            isTopCategory: data.isTopCategory || false,
            votesCount: 0,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        const docRef = await db.collection('categories').add(categoryData);
        showSuccess('Category added successfully!');
        await loadCategories();
        return docRef.id;
    } catch (error) {
        console.error('Error adding category:', error);
        showError('Error adding category: ' + error.message);
        throw error;
    } finally {
        hideLoading();
    }
}

async function updateCategory(categoryId, data) {
    try {
        showLoading('Updating category...');
        const db = firebase.firestore();
        
        const categoryData = {
            name: data.name,
            imageURL: data.imageURL,
            order: parseInt(data.order) || 0,
            description: data.description,
            featured: data.featured,
            isTopCategory: data.isTopCategory,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        await db.collection('categories').doc(categoryId).update(categoryData);
        showSuccess('Category updated successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error updating category:', error);
        showError('Error updating category: ' + error.message);
        throw error;
    } finally {
        hideLoading();
    }
}

async function deleteCategory(categoryId) {
    if (!confirm('Are you sure you want to delete this category? This will also delete all subcategories and subquestions.')) {
        return;
    }

    try {
        showLoading('Deleting category...');
        const db = firebase.firestore();
        
        // Get all subcategories
        const subcategoriesSnapshot = await db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .get();

        // Delete all subquestions for each subcategory
        const batch = db.batch();
        for (const subcategoryDoc of subcategoriesSnapshot.docs) {
            const subquestionsSnapshot = await subcategoryDoc.ref.collection('subquestions').get();
            subquestionsSnapshot.docs.forEach(doc => {
                batch.delete(doc.ref);
            });
            batch.delete(subcategoryDoc.ref);
        }

        // Delete the category
        batch.delete(db.collection('categories').doc(categoryId));
        
        await batch.commit();
        showSuccess('Category deleted successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error deleting category:', error);
        showError('Error deleting category: ' + error.message);
        throw error;
    } finally {
        hideLoading();
    }
}

// Subcategory CRUD Operations
async function addSubcategory(categoryId, data) {
    try {
        showLoading('Adding new subcategory...');
        const db = firebase.firestore();
        
        const subcategoryData = {
            name: data.name,
            imageURL: data.imageURL || DEFAULT_IMAGES.subcategory,
            order: parseInt(data.order) || 0,
            yayCount: 0,
            nayCount: 0,
            attributes: data.attributes || {},
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        const docRef = await db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .add(subcategoryData);

        showSuccess('Subcategory added successfully!');
        await loadCategories();
        return docRef.id;
    } catch (error) {
        console.error('Error adding subcategory:', error);
        showError('Error adding subcategory: ' + error.message);
        throw error;
    } finally {
        hideLoading();
    }
}

async function updateSubcategory(categoryId, subcategoryId, data) {
    try {
        showLoading('Updating subcategory...');
        const db = firebase.firestore();
        
        const subcategoryData = {
            name: data.name,
            imageURL: data.imageURL,
            order: parseInt(data.order) || 0,
            attributes: data.attributes,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        await db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .update(subcategoryData);

        showSuccess('Subcategory updated successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error updating subcategory:', error);
        showError('Error updating subcategory: ' + error.message);
        throw error;
    } finally {
        hideLoading();
    }
}

async function deleteSubcategory(categoryId, subcategoryId) {
    if (!confirm('Are you sure you want to delete this subcategory? This will also delete all subquestions.')) {
        return;
    }

    try {
        showLoading('Deleting subcategory...');
        const db = firebase.firestore();
        
        // Get all subquestions
        const subquestionsSnapshot = await db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('subquestions')
            .get();

        // Delete all subquestions and the subcategory
        const batch = db.batch();
        subquestionsSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        batch.delete(db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId));

        await batch.commit();
        showSuccess('Subcategory deleted successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error deleting subcategory:', error);
        showError('Error deleting subcategory: ' + error.message);
        throw error;
    } finally {
        hideLoading();
    }
}

// Subquestion CRUD Operations
async function addSubquestion(categoryId, subcategoryId, data) {
    try {
        showLoading('Adding new subquestion...');
        const db = firebase.firestore();
        
        const subquestionData = {
            question: data.question,
            yayCount: 0,
            nayCount: 0,
            createdAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        const docRef = await db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('subquestions')
            .add(subquestionData);

        showSuccess('Subquestion added successfully!');
        await loadCategories();
        return docRef.id;
    } catch (error) {
        console.error('Error adding subquestion:', error);
        showError('Error adding subquestion: ' + error.message);
        throw error;
    } finally {
        hideLoading();
    }
}

async function updateSubquestion(categoryId, subcategoryId, subquestionId, data) {
    try {
        showLoading('Updating subquestion...');
        const db = firebase.firestore();
        
        const subquestionData = {
            question: data.question,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        await db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('subquestions')
            .doc(subquestionId)
            .update(subquestionData);

        showSuccess('Subquestion updated successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error updating subquestion:', error);
        showError('Error updating subquestion: ' + error.message);
        throw error;
    } finally {
        hideLoading();
    }
}

async function deleteSubquestion(categoryId, subcategoryId, subquestionId) {
    if (!confirm('Are you sure you want to delete this subquestion?')) {
        return;
    }

    try {
        showLoading('Deleting subquestion...');
        const db = firebase.firestore();
        
        await db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('subquestions')
            .doc(subquestionId)
            .delete();

        showSuccess('Subquestion deleted successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error deleting subquestion:', error);
        showError('Error deleting subquestion: ' + error.message);
        throw error;
    } finally {
        hideLoading();
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

function showAddSubcategoryModal(categoryId) {
    const modal = document.getElementById('subcategoryModal');
    if (!modal) return;

    const title = document.querySelector('#subcategoryModal .modal-title');
    const form = document.getElementById('subcategoryForm');
    
    if (title) title.textContent = 'Add New Subcategory';
    if (form) {
        form.innerHTML = `
            <input type="hidden" id="subcategoryId" value="">
            <input type="hidden" id="parentCategoryId" value="${categoryId}">
            <div class="mb-3">
                <label for="subcategoryName" class="form-label">Name</label>
                <input type="text" class="form-control" id="subcategoryName" required>
            </div>
            <div class="mb-3">
                <label for="subcategoryImage" class="form-label">Image URL</label>
                <input type="url" class="form-control" id="subcategoryImage">
            </div>
            <div class="mb-3">
                <label for="subcategoryOrder" class="form-label">Order</label>
                <input type="number" class="form-control" id="subcategoryOrder" value="0" required>
            </div>
            <div class="mb-3">
                <div class="form-check">
                    <input type="checkbox" class="form-check-input" id="subcategoryActive" checked>
                    <label class="form-check-label" for="subcategoryActive">Active</label>
                </div>
            </div>
        `;
    }

    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
}

function showEditSubcategoryModal(categoryId, subcategory) {
    const modal = document.getElementById('subcategoryModal');
    if (!modal) return;

    const title = document.querySelector('#subcategoryModal .modal-title');
    const form = document.getElementById('subcategoryForm');
    
    if (title) title.textContent = 'Edit Subcategory';
    if (form) {
        form.innerHTML = `
            <input type="hidden" id="subcategoryId" value="${subcategory.id}">
            <input type="hidden" id="parentCategoryId" value="${categoryId}">
            <div class="mb-3">
                <label for="subcategoryName" class="form-label">Name</label>
                <input type="text" class="form-control" id="subcategoryName" value="${subcategory.name || ''}" required>
            </div>
            <div class="mb-3">
                <label for="subcategoryImage" class="form-label">Image URL</label>
                <input type="url" class="form-control" id="subcategoryImage" value="${subcategory.imageURL || ''}">
            </div>
            <div class="mb-3">
                <label for="subcategoryOrder" class="form-label">Order</label>
                <input type="number" class="form-control" id="subcategoryOrder" value="${subcategory.order || 0}" required>
            </div>
            <div class="mb-3">
                <div class="form-check">
                    <input type="checkbox" class="form-check-input" id="subcategoryActive" ${subcategory.active !== false ? 'checked' : ''}>
                    <label class="form-check-label" for="subcategoryActive">Active</label>
                </div>
            </div>
        `;
    }

    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
}

function showEditModal(collection, id, data) {
    const modal = document.getElementById('itemModal');
    if (!modal) return;

    const title = document.querySelector('#itemModal .modal-title');
    const form = document.getElementById('itemForm');
    
    // Convert collection name to singular type
    let type;
    switch (collection) {
        case 'categories':
            type = 'category';
            break;
        case 'subcategories':
            type = 'subcategory';
            break;
        case 'subquestions':
            type = 'subquestion';
            break;
        default:
            throw new Error(`Invalid collection: ${collection}`);
    }
    
    if (title) title.textContent = `Edit ${type.charAt(0).toUpperCase() + type.slice(1)}`;
    if (form) {
        form.innerHTML = `
            <input type="hidden" id="itemId" value="${id}">
            <div class="mb-3">
                <label for="name" class="form-label">Name</label>
                <input type="text" class="form-control" id="name" name="name" value="${data.name || ''}" required>
            </div>
            <div class="mb-3">
                <label for="imageURL" class="form-label">Image URL</label>
                <input type="url" class="form-control" id="imageURL" name="imageURL" value="${data.imageURL || ''}">
            </div>
            <div class="mb-3">
                <label for="order" class="form-label">Order</label>
                <input type="number" class="form-control" id="order" name="order" value="${data.order || 0}" required>
            </div>
            <div class="mb-3 form-check">
                <input type="checkbox" class="form-check-input" id="featured" name="featured" ${data.featured ? 'checked' : ''}>
                <label class="form-check-label" for="featured">Featured</label>
            </div>
            <div class="mb-3 form-check">
                <input type="checkbox" class="form-check-input" id="isTopCategory" name="isTopCategory" ${data.isTopCategory ? 'checked' : ''}>
                <label class="form-check-label" for="isTopCategory">Top Category</label>
            </div>
        `;
        form.dataset.id = id;
        form.dataset.type = type;
    }

    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
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
                        ${renderCategoryImage(category.imageURL, category.name)}
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
                                        ${renderCategoryImage(subcategory.imageURL, subcategory.name, 'subcategory')}
                                        <div class="flex-grow-1">
                                            <h6 class="mb-0">${subcategory.name}</h6>
                                            <div class="mt-2">
                                                <button class="btn btn-outline-primary btn-sm" onclick="showAddSubquestionModal('${category.id}', '${subcategory.id}')">
                                                    <i class="fas fa-plus"></i> Add Question
                                                </button>
                                                <button class="btn btn-outline-info btn-sm" onclick="showSubquestionsList('${category.id}', '${subcategory.id}')">
                                                    <i class="fas fa-list"></i> View Questions
                                                </button>
                                            </div>
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

async function saveSubquestion() {
    const button = event.target;
    try {
        setButtonLoading(button, true);
        showLoading('Validating form data...');

        const form = document.getElementById('subquestionForm');
        if (!form.checkValidity()) {
            form.classList.add('was-validated');
            showError('Please fill in all required fields correctly');
            return;
        }

        const subquestionId = document.getElementById('subquestionId').value;
        const categoryId = document.getElementById('subquestionCategoryId').value;
        const subcategoryId = document.getElementById('subquestionSubcategoryId').value;
        const questionText = document.getElementById('subquestionText').value.trim();
        const order = parseInt(document.getElementById('subquestionOrder').value);
        const isActive = document.getElementById('subquestionActive').checked;

        if (!categoryId || !subcategoryId) {
            showError('Category and subcategory are required');
            return;
        }

        if (!questionText) {
            showError('Question text is required');
            return;
        }

        debugLog('Saving subquestion:', { categoryId, subcategoryId, questionText, order, isActive });
        showLoading(subquestionId ? 'Updating subquestion...' : 'Adding new subquestion...');

        const subquestionData = {
            question: questionText,
            order: order,
            isActive: isActive,
            categoryId: categoryId,
            subCategoryId: subcategoryId
        };

        if (!subquestionId) {
            // Adding new subquestion
            await window.subquestionsCRUD.create(categoryId, subcategoryId, subquestionData);
            debugLog('New subquestion created successfully');
        } else {
            // Updating existing subquestion
            await window.subquestionsCRUD.update(categoryId, subcategoryId, subquestionId, subquestionData);
            debugLog('Subquestion updated successfully');
        }

        // Close the modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('subquestionModal'));
        if (modal) {
            modal.hide();
        }

        showSuccess(subquestionId ? 'Subquestion updated successfully!' : 'Subquestion added successfully!');
        
        // Refresh the view
        if (document.getElementById('subquestionsListModal').classList.contains('show')) {
            await showSubquestionsList(categoryId, subcategoryId);
        } else {
            await loadCategories();
        }
    } catch (error) {
        console.error('Error saving subquestion:', error);
        debugLog('Error saving subquestion:', error.message);
        showError('Failed to save subquestion: ' + error.message);
    } finally {
        setButtonLoading(button, false);
        hideLoading();
    }
}

function showAddSubquestionModal(categoryId, subcategoryId) {
    try {
        debugLog('Opening add subquestion modal:', { categoryId, subcategoryId });
        
        // Validate parameters
        if (!categoryId || !subcategoryId) {
            throw new Error('Category ID and Subcategory ID are required');
        }

        // Get the modal element
        const modal = document.getElementById('subquestionModal');
        if (!modal) {
            throw new Error('Subquestion modal not found');
        }

        // Reset and prepare the form
        const form = document.getElementById('subquestionForm');
        form.reset();
        form.classList.remove('was-validated');

        // Set the modal title
        document.getElementById('subquestionModalTitle').textContent = 'Add New Subquestion';
        
        // Set the hidden fields
        document.getElementById('subquestionId').value = '';
        document.getElementById('subquestionCategoryId').value = categoryId;
        document.getElementById('subquestionSubcategoryId').value = subcategoryId;
        
        // Set default values
        document.getElementById('subquestionActive').checked = true;
        document.getElementById('subquestionOrder').value = 0;
        document.getElementById('subquestionText').value = '';

        // Show the modal
        const bsModal = new bootstrap.Modal(modal);
        bsModal.show();

        debugLog('Add subquestion modal opened successfully');
    } catch (error) {
        console.error('Error showing add subquestion modal:', error);
        debugLog('Error showing add subquestion modal:', error.message);
        showError('Failed to open add subquestion modal: ' + error.message);
    }
}

function showEditSubquestionModal(categoryId, subcategoryId, subquestion) {
    document.getElementById('subquestionModalTitle').textContent = 'Edit Subquestion';
    document.getElementById('subquestionId').value = subquestion.id;
    document.getElementById('subquestionCategoryId').value = categoryId;
    document.getElementById('subquestionSubcategoryId').value = subcategoryId;
    document.getElementById('subquestionText').value = subquestion.question;
    document.getElementById('subquestionOrder').value = subquestion.order || 0;
    document.getElementById('subquestionActive').checked = subquestion.isActive !== false;

    new bootstrap.Modal(document.getElementById('subquestionModal')).show();
}

async function showSubquestionsList(categoryId, subcategoryId) {
    try {
        showLoading('Loading subquestions...');
        
        const db = firebase.firestore();
        const subquestionsRef = db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('subquestions')
            .orderBy('order');
            
        const snapshot = await subquestionsRef.get();
        const subquestions = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        // Get subcategory name
        const subcategoryDoc = await db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .get();
        
        const subcategoryName = subcategoryDoc.exists ? subcategoryDoc.data().name : 'Unknown Subcategory';

        const modal = new bootstrap.Modal(document.getElementById('subquestionsListModal'));
        const modalBody = document.querySelector('#subquestionsListModal .modal-body');
        
        modalBody.innerHTML = `
            <h6 class="mb-3">Subquestions for: ${subcategoryName}</h6>
            ${subquestions.length === 0 ? `
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    No subquestions found. Click "Add Question" to create your first subquestion.
                </div>
            ` : `
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Order</th>
                                <th>Question</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${subquestions.map(subquestion => `
                                <tr>
                                    <td>${subquestion.order || 0}</td>
                                    <td>${subquestion.question}</td>
                                    <td>
                                        <span class="badge bg-${subquestion.isActive ? 'success' : 'danger'}">
                                            ${subquestion.isActive ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    <td>
                                        <div class="btn-group btn-group-sm">
                                            <button class="btn btn-outline-primary" onclick="showEditSubquestionModal('${categoryId}', '${subcategoryId}', ${JSON.stringify(subquestion).replace(/"/g, '&quot;')})">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button class="btn btn-outline-danger" onclick="deleteSubquestion('${categoryId}', '${subcategoryId}', '${subquestion.id}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `}
            <div class="mt-3">
                <button class="btn btn-primary" onclick="showAddSubquestionModal('${categoryId}', '${subcategoryId}')">
                    <i class="fas fa-plus"></i> Add Question
                </button>
            </div>
        `;

        modal.show();
        hideLoading();
    } catch (error) {
        console.error('Error loading subquestions:', error);
        showError('Failed to load subquestions: ' + error.message);
        hideLoading();
    }
}

async function deleteSubquestion(categoryId, subcategoryId, subquestionId) {
    try {
        if (!confirm('Are you sure you want to delete this subquestion? This action cannot be undone.')) {
            return;
        }

        showLoading('Deleting subquestion...');
        await window.subquestionsCRUD.delete(categoryId, subcategoryId, subquestionId);
        showSuccess('Subquestion deleted successfully!');
        
        // Refresh the current view
        if (document.getElementById('subquestionsListModal').classList.contains('show')) {
            await showSubquestionsList(categoryId, subcategoryId);
        } else {
            await loadCategories();
        }
    } catch (error) {
        console.error('Error deleting subquestion:', error);
        showError('Failed to delete subquestion: ' + error.message);
    } finally {
        hideLoading();
    }
}

// UI Helper Functions
function showLoading(message) {
    const overlay = document.getElementById('loadingOverlay');
    const messageEl = document.getElementById('loadingMessage');
    if (overlay && messageEl) {
        messageEl.textContent = message;
        overlay.style.display = 'flex';
    }
}

function hideLoading() {
    const overlay = document.getElementById('loadingOverlay');
    if (overlay) {
        overlay.style.display = 'none';
    }
}

function showError(message) {
    const toast = document.getElementById('errorToast');
    const messageEl = document.getElementById('errorToastMessage');
    if (toast && messageEl) {
        messageEl.textContent = message;
        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();
    }
}

function showSuccess(message) {
    const toast = document.getElementById('successToast');
    const messageEl = document.getElementById('successToastMessage');
    if (toast && messageEl) {
        messageEl.textContent = message;
        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();
    } else {
        console.log('Success:', message);
    }
}

// Make loadData available globally
window.loadData = crud.loadData.bind(crud);

// Confirmation dialog
function showConfirmDelete(collection, id, name) {
    const modal = document.getElementById('confirmDeleteModal');
    if (!modal) return;

    const messageEl = document.getElementById('confirmDeleteMessage');
    if (messageEl) {
        messageEl.textContent = `Are you sure you want to delete "${name}"?`;
    }

    const confirmButton = document.getElementById('confirmDeleteButton');
    if (confirmButton) {
        confirmButton.onclick = async () => {
            try {
                setButtonLoading(confirmButton, true);
                showLoading('Deleting item...');
                
                // Map collection name to type
                let type;
                switch (collection) {
                    case 'categories':
                        type = 'category';
                        break;
                    case 'subcategories':
                        type = 'subcategory';
                        break;
                    case 'subquestions':
                        type = 'subquestion';
                        break;
                    default:
                        throw new Error(`Invalid collection: ${collection}`);
                }

                await crud.deleteItem(type, id, {});
                const bsModal = bootstrap.Modal.getInstance(modal);
                if (bsModal) {
                    bsModal.hide();
                }
                await crud.loadData(collection);
                showSuccess('Item deleted successfully!');
            } catch (error) {
                console.error('Error deleting item:', error);
                showError('Failed to delete item: ' + error.message);
            } finally {
                setButtonLoading(confirmButton, false);
                hideLoading();
            }
        };
    }

    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
}

// Subcategory management
async function showSubcategories(categoryId) {
    try {
        showLoading('Loading subcategories...');
        const db = firebase.firestore();
        const subcategoriesRef = db.collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .orderBy('order');
            
        const snapshot = await subcategoriesRef.get();
        const subcategories = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        // Get category name
        const categoryDoc = await db.collection('categories').doc(categoryId).get();
        const categoryName = categoryDoc.exists ? categoryDoc.data().name : 'Unknown Category';

        const modal = new bootstrap.Modal(document.getElementById('subcategoriesModal'));
        const modalBody = document.querySelector('#subcategoriesModal .modal-body');
        
        modalBody.innerHTML = `
            <h6 class="mb-3">Subcategories for: ${categoryName}</h6>
            ${subcategories.length === 0 ? `
                <div class="alert alert-info">
                    <i class="fas fa-info-circle me-2"></i>
                    No subcategories found. Click "Add Subcategory" to create your first subcategory.
                </div>
            ` : `
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Order</th>
                                <th>Name</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${subcategories.map(subcategory => `
                                <tr>
                                    <td>${subcategory.order || 0}</td>
                                    <td>${subcategory.name}</td>
                                    <td>
                                        <span class="badge bg-${subcategory.active ? 'success' : 'danger'}">
                                            ${subcategory.active ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    <td>
                                        <div class="btn-group btn-group-sm">
                                            <button class="btn btn-outline-primary" onclick="showEditSubcategoryModal('${categoryId}', ${JSON.stringify(subcategory).replace(/"/g, '&quot;')})">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button class="btn btn-outline-danger" onclick="showConfirmDelete('subcategories', '${subcategory.id}', '${subcategory.name}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `}
            <div class="mt-3">
                <button class="btn btn-primary" onclick="showAddSubcategoryModal('${categoryId}')">
                    <i class="fas fa-plus"></i> Add Subcategory
                </button>
            </div>
        `;

        modal.show();
        hideLoading();
    } catch (error) {
        console.error('Error loading subcategories:', error);
        showError('Failed to load subcategories: ' + error.message);
        hideLoading();
    }
}