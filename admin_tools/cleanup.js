const databaseCleanup = require('./database-cleanup');
const databaseStats = require('./database-stats');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

async function promptUser(question) {
    return new Promise((resolve) => {
        rl.question(question, (answer) => {
            resolve(answer.toLowerCase());
        });
    });
}

async function runCleanup() {
    try {
        console.log('📊 Getting current database statistics...');
        const initialStats = await databaseStats.getFullDatabaseStats();
        
        console.log('\nCurrent Database State:');
        console.log('------------------------');
        console.log(`Categories: ${initialStats.collections.categories?.totalDocuments || 0}`);
        console.log(`Subquestions: ${initialStats.collections.subquestions?.totalDocuments || 0}`);
        console.log(`Votes: ${initialStats.collections.votes?.totalDocuments || 0}`);
        console.log(`Active Users: ${initialStats.userActivity?.totalActiveUsers || 0}`);
        
        const answer = await promptUser('\n⚠️ Are you sure you want to proceed with database cleanup? (yes/no): ');
        
        if (answer !== 'yes') {
            console.log('❌ Cleanup cancelled by user');
            rl.close();
            return;
        }

        console.log('\n🧹 Starting database cleanup...');
        
        // Run cleanup operations
        const cleanupResults = await databaseCleanup.runFullCleanup();
        
        // Get final statistics
        const finalStats = await databaseStats.getFullDatabaseStats();

        // Generate summary
        const summary = {
            documentsRemoved: {
                orphanedSubquestions: cleanupResults.orphanedDocs.subquestions?.orphanedDocsRemoved || 0,
                duplicateCategories: cleanupResults.duplicates.categories?.duplicatesRemoved || 0,
                expiredVotes: cleanupResults.expired.votes?.expiredDocsRemoved || 0
            },
            databaseState: {
                categories: {
                    before: initialStats.collections.categories?.totalDocuments || 0,
                    after: finalStats.collections.categories?.totalDocuments || 0,
                    difference: (initialStats.collections.categories?.totalDocuments || 0) - 
                              (finalStats.collections.categories?.totalDocuments || 0)
                },
                subquestions: {
                    before: initialStats.collections.subquestions?.totalDocuments || 0,
                    after: finalStats.collections.subquestions?.totalDocuments || 0,
                    difference: (initialStats.collections.subquestions?.totalDocuments || 0) - 
                              (finalStats.collections.subquestions?.totalDocuments || 0)
                },
                votes: {
                    before: initialStats.collections.votes?.totalDocuments || 0,
                    after: finalStats.collections.votes?.totalDocuments || 0,
                    difference: (initialStats.collections.votes?.totalDocuments || 0) - 
                              (finalStats.collections.votes?.totalDocuments || 0)
                }
            }
        };

        console.log('\n✅ Cleanup Complete!');
        console.log('\nCleanup Summary:');
        console.log('---------------');
        console.log(`Orphaned Subquestions Removed: ${summary.documentsRemoved.orphanedSubquestions}`);
        console.log(`Duplicate Categories Removed: ${summary.documentsRemoved.duplicateCategories}`);
        console.log(`Expired Votes Removed: ${summary.documentsRemoved.expiredVotes}`);
        
        console.log('\nDatabase State Changes:');
        console.log('----------------------');
        console.log(`Categories: ${summary.databaseState.categories.before} → ${summary.databaseState.categories.after} (${summary.databaseState.categories.difference} removed)`);
        console.log(`Subquestions: ${summary.databaseState.subquestions.before} → ${summary.databaseState.subquestions.after} (${summary.databaseState.subquestions.difference} removed)`);
        console.log(`Votes: ${summary.databaseState.votes.before} → ${summary.databaseState.votes.after} (${summary.databaseState.votes.difference} removed)`);

        console.log('\n📝 Note: All removed items have been backed up and can be restored if needed.');
        
    } catch (error) {
        console.error('❌ Error during cleanup:', error);
    } finally {
        rl.close();
    }
}

// Run the cleanup
if (require.main === module) {
    runCleanup().catch(console.error);
}

module.exports = runCleanup; 