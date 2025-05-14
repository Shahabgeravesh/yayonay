// Examples of using the automated CRUD operations
const automatedCRUD = require('./automated-crud');

// Example usage for categories
async function categoryExamples() {
    try {
        // 1. Create a single category
        const newCategory = await automatedCRUD.createDocument(
            'categories',
            {
                name: 'Sports',
                description: 'Sports related questions',
                imageUrl: 'https://example.com/sports.jpg'
            },
            ['name'] // Required fields
        );
        console.log('Created category:', newCategory);

        // 2. Bulk create categories
        const categories = [
            { name: 'Music', description: 'Music related questions' },
            { name: 'Movies', description: 'Movie related questions' }
        ];
        const createdCategories = await automatedCRUD.bulkCreate('categories', categories, ['name']);
        console.log('Bulk created categories:', createdCategories);

        // 3. Read categories with filters
        const queryParams = {
            filters: [
                { field: 'name', operator: '>=', value: 'M' }
            ],
            orderBy: { field: 'name', direction: 'asc' },
            limit: 10
        };
        const filteredCategories = await automatedCRUD.readDocuments('categories', queryParams);
        console.log('Filtered categories:', filteredCategories);

        // 4. Update a category
        const updateResult = await automatedCRUD.updateDocument(
            'categories',
            newCategory.id,
            { description: 'Updated sports description' }
        );
        console.log('Updated category:', updateResult);

        // 5. Bulk update categories
        const updates = createdCategories.map(cat => ({
            id: cat.id,
            data: { verified: true }
        }));
        const bulkUpdateResult = await automatedCRUD.bulkUpdate('categories', updates);
        console.log('Bulk updated categories:', bulkUpdateResult);

        // 6. Delete a category (with automatic backup)
        const deleteResult = await automatedCRUD.deleteDocument('categories', newCategory.id);
        console.log('Deleted category:', deleteResult);

        // 7. Restore a deleted category
        const restoreResult = await automatedCRUD.restoreDocument('categories', newCategory.id);
        console.log('Restored category:', restoreResult);

    } catch (error) {
        console.error('Error in category examples:', error);
    }
}

// Example usage for subquestions
async function subquestionExamples() {
    try {
        // 1. Create a subquestion
        const newSubquestion = await automatedCRUD.createDocument(
            'subquestions',
            {
                categoryId: 'sports123',
                question: 'Who won the World Cup 2022?',
                options: ['Argentina', 'France', 'Brazil', 'Germany'],
                correctAnswer: 0
            },
            ['question', 'options', 'correctAnswer'] // Required fields
        );
        console.log('Created subquestion:', newSubquestion);

        // 2. Bulk create subquestions
        const subquestions = [
            {
                categoryId: 'sports123',
                question: 'Which team has won the most Champions League titles?',
                options: ['Real Madrid', 'AC Milan', 'Bayern Munich', 'Liverpool'],
                correctAnswer: 0
            },
            {
                categoryId: 'sports123',
                question: 'Who holds the record for most Olympic medals?',
                options: ['Michael Phelps', 'Usain Bolt', 'Simone Biles', 'Carl Lewis'],
                correctAnswer: 0
            }
        ];
        const createdSubquestions = await automatedCRUD.bulkCreate('subquestions', subquestions, ['question', 'options', 'correctAnswer']);
        console.log('Bulk created subquestions:', createdSubquestions);

        // 3. Read subquestions for a specific category
        const queryParams = {
            filters: [
                { field: 'categoryId', operator: '==', value: 'sports123' }
            ],
            orderBy: { field: 'createdAt', direction: 'desc' },
            limit: 10
        };
        const categorySubquestions = await automatedCRUD.readDocuments('subquestions', queryParams);
        console.log('Category subquestions:', categorySubquestions);

    } catch (error) {
        console.error('Error in subquestion examples:', error);
    }
}

// Run examples
async function runExamples() {
    console.log('Running Category Examples...');
    await categoryExamples();
    
    console.log('\nRunning Subquestion Examples...');
    await subquestionExamples();
}

// Execute if running directly
if (require.main === module) {
    runExamples().catch(console.error);
} 