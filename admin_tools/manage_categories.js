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