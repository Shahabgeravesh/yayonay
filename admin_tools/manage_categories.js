// Browser-compatible category management functions
async function addCategory(name, imageURL, order) {
    try {
        showOperationStatus('Adding new category...', 'Preparing data');
        debugLog('Adding new category:', { name, imageURL, order });

        // Check if Firebase is initialized
        if (!firebase || !firebase.apps.length) {
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

        const db = firebase.firestore();
        await db.collection('categories').add(categoryData);
        showSuccess('Category added successfully!');
        await loadCategories();
    } catch (error) {
        console.error('Error adding category:', error);
        showError('Error adding category: ' + error.message);
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

// Authentication and Event Management Functions
async function login(email, password) {
    try {
        debugLog('Attempting login...');
        const userCredential = await firebase.auth().signInWithEmailAndPassword(email, password);
        debugLog('Login successful');
        showSuccess('Login successful!');
        return userCredential;
    } catch (error) {
        console.error('Login error:', error);
        debugLog('Login error: ' + error.message);
        showError('Login failed: ' + error.message);
        throw error;
    }
}

function logout() {
    return firebase.auth().signOut()
        .then(() => {
            showSuccess('Logged out successfully');
            window.location.reload();
        })
        .catch((error) => {
            showError('Error logging out: ' + error.message);
        });
}

// Event Listeners
document.addEventListener('DOMContentLoaded', function() {
    // Login form handler
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            const email = document.getElementById('email').value;
            const password = document.getElementById('password').value;
            try {
                await login(email, password);
            } catch (error) {
                console.error('Login failed:', error);
            }
        });
    }

    // Category form handler
    const categoryForm = document.getElementById('categoryForm');
    if (categoryForm) {
        categoryForm.addEventListener('submit', function(e) {
            e.preventDefault();
            handleSaveCategory();
        });
    }

    // Subcategory form handler
    const subcategoryForm = document.getElementById('subcategoryForm');
    if (subcategoryForm) {
        subcategoryForm.addEventListener('submit', function(e) {
            e.preventDefault();
            handleSaveSubcategory();
        });
    }

    // Subquestion form handler
    const subquestionForm = document.getElementById('subquestionForm');
    if (subquestionForm) {
        subquestionForm.addEventListener('submit', function(e) {
            e.preventDefault();
            handleSaveSubquestion();
        });
    }

    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Add click handlers for navigation buttons
    document.querySelectorAll('[data-nav]').forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            const section = this.getAttribute('data-nav');
            showSection(section);
        });
    });

    // Add click handlers for modal buttons
    document.querySelectorAll('[data-modal]').forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            const modalFunction = this.getAttribute('data-modal');
            if (typeof window[modalFunction] === 'function') {
                window[modalFunction]();
            }
        });
    });

    // Add click handlers for action buttons
    document.querySelectorAll('[data-action]').forEach(button => {
        button.addEventListener('click', async function(e) {
            e.preventDefault();
            const action = this.getAttribute('data-action');
            const id = this.getAttribute('data-id');
            const parentId = this.getAttribute('data-parent-id');
            
            try {
                setButtonLoading(this, true);
                if (typeof window[action] === 'function') {
                    if (parentId) {
                        await window[action](parentId, id);
                    } else {
                        await window[action](id);
                    }
                }
            } finally {
                setButtonLoading(this, false);
            }
        });
    });
});

// Subquestions Management
async function showAddSubquestionModal(categoryId, subcategoryId) {
    document.getElementById('subquestionId').value = '';
    document.getElementById('subquestionCategory').value = categoryId || '';
    document.getElementById('subquestionSubcategory').value = subcategoryId || '';
    document.getElementById('subquestionText').value = '';
    document.getElementById('subquestionOrder').value = '0';
    document.getElementById('subquestionActive').checked = true;

    if (categoryId) {
        document.getElementById('subquestionCategory').disabled = true;
        if (subcategoryId) {
            document.getElementById('subquestionSubcategory').disabled = true;
        } else {
            await loadSubcategoriesForCategory(categoryId);
        }
    } else {
        document.getElementById('subquestionCategory').disabled = false;
        document.getElementById('subquestionSubcategory').disabled = false;
        // Load categories for dropdown
        const categories = await loadCategories();
        const categorySelect = document.getElementById('subquestionCategory');
        categorySelect.innerHTML = '<option value="">Select a category</option>';
        categories.forEach(category => {
            categorySelect.innerHTML += `<option value="${category.id}">${category.name}</option>`;
        });
    }

    const modal = new bootstrap.Modal(document.getElementById('subquestionModal'));
    modal.show();
}

async function loadSubcategoriesForCategory(categoryId) {
    if (!categoryId) return;
    
    try {
        const subcategoriesSnapshot = await firebase.firestore()
            .collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .get();
            
        const subcategorySelect = document.getElementById('subquestionSubcategory');
        subcategorySelect.innerHTML = '<option value="">Select a subcategory</option>';
        
        subcategoriesSnapshot.forEach(doc => {
            const data = doc.data();
            subcategorySelect.innerHTML += `<option value="${doc.id}">${data.name}</option>`;
        });
    } catch (error) {
        console.error('Error loading subcategories:', error);
        showError('Error loading subcategories: ' + error.message);
    }
}

async function handleSaveSubquestion() {
    const button = event.target;
    try {
        setButtonLoading(button, true);
        showLoading('Validating form data...');

        const form = document.getElementById('subquestionForm');
        if (!form.checkValidity()) {
            form.classList.add('was-validated');
            showWarning('Please fill in all required fields correctly');
            return;
        }

        const subquestionId = document.getElementById('subquestionId').value;
        const categoryId = document.getElementById('subquestionCategory').value;
        const subcategoryId = document.getElementById('subquestionSubcategory').value;
        const question = document.getElementById('subquestionText').value.trim();
        const order = parseInt(document.getElementById('subquestionOrder').value);
        const active = document.getElementById('subquestionActive').checked;

        if (!categoryId || !subcategoryId) {
            showError('Category and subcategory are required');
            return;
        }

        if (!question) {
            showError('Question text is required');
            return;
        }

        if (isNaN(order) || order < 0) {
            showError('Order must be a positive number');
            return;
        }

        showLoading(subquestionId ? 'Updating subquestion...' : 'Adding new subquestion...');
        debugLog('Saving subquestion:', { categoryId, subcategoryId, question, order, active });

        const subquestionData = {
            question,
            order,
            active
        };

        if (subquestionId) {
            await window.subquestionsCRUD.update(categoryId, subcategoryId, subquestionId, subquestionData);
        } else {
            await window.subquestionsCRUD.create(categoryId, subcategoryId, subquestionData);
        }

        form.classList.remove('was-validated');
        
        const modal = bootstrap.Modal.getInstance(document.getElementById('subquestionModal'));
        if (modal) {
            modal.hide();
        }

        await loadCategories();
        
        debugLog('Subquestion saved successfully');
        showSuccess(subquestionId ? 'Subquestion updated successfully!' : 'Subquestion added successfully!');
    } catch (error) {
        console.error('Error saving subquestion:', error);
        debugLog('Error saving subquestion: ' + error.message);
        showError('Failed to save subquestion: ' + error.message);
    } finally {
        setButtonLoading(button, false);
        hideLoading();
    }
}

async function showSubquestionsList() {
    try {
        const modal = new bootstrap.Modal(document.getElementById('subquestionsListModal'));
        modal.show();
        
        // Load categories for filter
        const categories = await loadCategories();
        const filterSelect = document.getElementById('subquestionFilterCategory');
        if (filterSelect) {
            filterSelect.innerHTML = '<option value="">All Categories</option>';
            categories.forEach(category => {
                filterSelect.innerHTML += `<option value="${category.id}">${category.name}</option>`;
            });
        }
        
        await loadSubquestionsList();
    } catch (error) {
        console.error('Error showing subquestions list:', error);
        showError('Error loading subquestions: ' + error.message);
    }
}

async function loadSubquestionsList(categoryId = null, subCategoryId = null) {
    try {
        const tableBody = document.getElementById('subquestionsTableBody');
        if (!tableBody) return;
        
        tableBody.innerHTML = '<tr><td colspan="6" class="text-center">Loading...</td></tr>';
        
        if (!categoryId) {
            tableBody.innerHTML = '<tr><td colspan="6" class="text-center">Please select a category and subcategory</td></tr>';
            return;
        }
        
        if (!subCategoryId) {
            tableBody.innerHTML = '<tr><td colspan="6" class="text-center">Please select a subcategory</td></tr>';
            return;
        }
        
        const subquestions = await window.subquestionsCRUD.get(categoryId, subCategoryId, {
            orderBy: { field: 'order', direction: 'asc' }
        });
        
        if (subquestions.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="6" class="text-center">No subquestions found</td></tr>';
            return;
        }
        
        tableBody.innerHTML = subquestions.map(sq => `
            <tr>
                <td>${sq.question}</td>
                <td>${sq.order}</td>
                <td>${sq.active ? 'Yes' : 'No'}</td>
                <td>${sq.yayCount}</td>
                <td>${sq.nayCount}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary me-1" onclick="editSubquestion('${sq.id}', '${categoryId}', '${subCategoryId}')">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-danger" onclick="deleteSubquestionWithConfirm('${sq.id}', '${categoryId}', '${subCategoryId}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    } catch (error) {
        console.error('Error loading subquestions list:', error);
        showError('Error loading subquestions: ' + error.message);
    }
}

async function editSubquestion(categoryId, subcategoryId, subquestionId) {
    try {
        showLoading('Loading subquestion...');
        const subquestion = await window.subquestionsCRUD.get(categoryId, subcategoryId, subquestionId);
        
        document.getElementById('subquestionId').value = subquestionId;
        document.getElementById('subquestionCategory').value = categoryId;
        document.getElementById('subquestionCategory').disabled = true;
        
        document.getElementById('subquestionSubcategory').value = subcategoryId;
        document.getElementById('subquestionSubcategory').disabled = true;
        
        document.getElementById('subquestionText').value = subquestion.question;
        document.getElementById('subquestionOrder').value = subquestion.order || 0;
        document.getElementById('subquestionActive').checked = subquestion.active !== false;
        
        const modal = new bootstrap.Modal(document.getElementById('subquestionModal'));
        modal.show();
    } catch (error) {
        console.error('Error loading subquestion:', error);
        showError('Error loading subquestion: ' + error.message);
    } finally {
        hideLoading();
    }
}

async function deleteSubquestionWithConfirm(categoryId, subcategoryId, subquestionId) {
    if (confirm('Are you sure you want to delete this subquestion? This action cannot be undone.')) {
        try {
            showLoading('Deleting subquestion...');
            await window.subquestionsCRUD.delete(categoryId, subcategoryId, subquestionId);
            showSuccess('Subquestion deleted successfully!');
            await loadCategories();
        } catch (error) {
            console.error('Error deleting subquestion:', error);
            showError('Error deleting subquestion: ' + error.message);
        } finally {
            hideLoading();
        }
    }
}

async function showBulkSubquestionUpload() {
    const modal = new bootstrap.Modal(document.getElementById('bulkSubquestionUploadModal'));
    modal.show();
}

async function uploadBulkSubquestions() {
    try {
        const fileInput = document.getElementById('bulkSubquestionFile');
        const file = fileInput.files[0];
        if (!file) {
            throw new Error('Please select a file');
        }
        
        const reader = new FileReader();
        reader.onload = async function(e) {
            try {
                const questions = JSON.parse(e.target.result);
                if (!Array.isArray(questions)) {
                    throw new Error('Invalid file format. Expected an array of questions');
                }
                
                const categoryId = document.getElementById('bulkUploadCategory').value;
                const subCategoryId = document.getElementById('bulkUploadSubcategory').value;
                
                if (!categoryId || !subCategoryId) {
                    throw new Error('Please select a category and subcategory');
                }
                
                const results = await window.subquestionsCRUD.bulkCreate(categoryId, subCategoryId, questions);
                showSuccess(`Successfully uploaded ${results.length} subquestions`);
                
                bootstrap.Modal.getInstance(document.getElementById('bulkSubquestionUploadModal')).hide();
                await showSubquestionsList();
            } catch (error) {
                console.error('Error processing bulk upload:', error);
                showError('Error processing bulk upload: ' + error.message);
            }
        };
        reader.readAsText(file);
    } catch (error) {
        console.error('Error uploading subquestions:', error);
        showError('Error uploading subquestions: ' + error.message);
    }
}

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
            
            category.subcategories = [];
            
            // Load subcategories and their subquestions
            for (const subdoc of subcategoriesSnapshot.docs) {
                const subcategory = { id: subdoc.id, ...subdoc.data() };
                
                // Load subquestions for this subcategory
                const subquestionsSnapshot = await db.collection('categories')
                    .doc(doc.id)
                    .collection('subcategories')
                    .doc(subdoc.id)
                    .collection('subquestions')
                    .orderBy('order')
                    .get();
                
                subcategory.subquestions = subquestionsSnapshot.docs.map(questionDoc => ({
                    id: questionDoc.id,
                    ...questionDoc.data()
                }));
                
                category.subcategories.push(subcategory);
            }
            
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
            // Display categories with subcategories and subquestions
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
                                            <button class="btn btn-outline-success btn-sm" onclick="showAddSubquestionModal('${category.id}', '${subcategory.id}')">
                                                <i class="fas fa-plus"></i> Add Question
                                            </button>
                                            <button class="btn btn-outline-primary btn-sm" onclick="showEditSubcategoryModal('${category.id}', ${JSON.stringify(subcategory).replace(/"/g, '&quot;')})">
                                                <i class="fas fa-edit"></i>
                                            </button>
                                            <button class="btn btn-outline-danger btn-sm" onclick="deleteSubcategory('${category.id}', '${subcategory.id}')">
                                                <i class="fas fa-trash"></i>
                                            </button>
                                        </div>
                                    </div>
                                    
                                    <!-- Subquestions List -->
                                    <div class="subquestions-list mt-2">
                                        ${subcategory.subquestions?.length ? `
                                            <div class="table-responsive">
                                                <table class="table table-sm">
                                                    <thead>
                                                        <tr>
                                                            <th>Question</th>
                                                            <th>Order</th>
                                                            <th>Active</th>
                                                            <th>Actions</th>
                                                        </tr>
                                                    </thead>
                                                    <tbody>
                                                        ${subcategory.subquestions.map(subquestion => `
                                                            <tr>
                                                                <td>${subquestion.question}</td>
                                                                <td>${subquestion.order}</td>
                                                                <td>
                                                                    <div class="form-check form-switch">
                                                                        <input class="form-check-input" type="checkbox" 
                                                                            ${subquestion.active ? 'checked' : ''} 
                                                                            onchange="toggleSubquestionActive('${category.id}', '${subcategory.id}', '${subquestion.id}', this.checked)">
                                                                    </div>
                                                                </td>
                                                                <td>
                                                                    <div class="btn-group btn-group-sm">
                                                                        <button class="btn btn-outline-primary btn-sm" 
                                                                            onclick="editSubquestion('${category.id}', '${subcategory.id}', '${subquestion.id}')">
                                                                            <i class="fas fa-edit"></i>
                                                                        </button>
                                                                        <button class="btn btn-outline-danger btn-sm" 
                                                                            onclick="deleteSubquestionWithConfirm('${category.id}', '${subcategory.id}', '${subquestion.id}')">
                                                                            <i class="fas fa-trash"></i>
                                                                        </button>
                                                                    </div>
                                                                </td>
                                                            </tr>
                                                        `).join('')}
                                                    </tbody>
                                                </table>
                                            </div>
                                        ` : '<div class="text-muted small">No subquestions yet</div>'}
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

// Toggle Subquestion Active State
async function toggleSubquestionActive(categoryId, subcategoryId, subquestionId, active) {
    try {
        showLoading('Updating subquestion...');
        
        await window.subquestionsCRUD.update(categoryId, subcategoryId, subquestionId, {
            active: active
        });
        
        showSuccess('Subquestion updated successfully!');
    } catch (error) {
        console.error('Error updating subquestion:', error);
        showError('Failed to update subquestion: ' + error.message);
    } finally {
        hideLoading();
    }
} 