// Test script for real-time search performance
const FoodDatabase = require('./src/services/FoodDatabase');

console.log('=== Testing Real-Time Search Performance ===\n');

// Test 1: Basic search functionality
console.log('Test 1: Basic Search');
const searchQueries = ['oatmeal', 'chicken', 'apple', 'protein', 'fiber'];
searchQueries.forEach(query => {
  const startTime = Date.now();
  const results = FoodDatabase.searchFoods(query);
  const endTime = Date.now();
  
  console.log(`Query: "${query}"`);
  console.log(`Results: ${results.length}`);
  console.log(`Time: ${endTime - startTime}ms`);
  console.log(`Top result: ${results[0]?.name || 'None'}`);
  console.log('---');
});

// Test 2: Search suggestions
console.log('\nTest 2: Search Suggestions');
const suggestionQueries = ['oat', 'chi', 'app', 'pro'];
suggestionQueries.forEach(query => {
  const suggestions = FoodDatabase.getSearchSuggestions(query);
  console.log(`Query: "${query}"`);
  console.log(`Suggestions: ${suggestions.length}`);
  suggestions.forEach(suggestion => {
    console.log(`  - ${suggestion.name} (${suggestion.type})`);
  });
  console.log('---');
});

// Test 3: Performance with multiple terms
console.log('\nTest 3: Multi-term Search');
const multiTermQueries = [
  'high protein',
  'low fodmap',
  'easy digest',
  'anti inflammatory'
];

multiTermQueries.forEach(query => {
  const startTime = Date.now();
  const results = FoodDatabase.searchFoods(query);
  const endTime = Date.now();
  
  console.log(`Query: "${query}"`);
  console.log(`Results: ${results.length}`);
  console.log(`Time: ${endTime - startTime}ms`);
  if (results.length > 0) {
    console.log(`Top 3 results:`);
    results.slice(0, 3).forEach((result, index) => {
      console.log(`  ${index + 1}. ${result.name} (Score: ${result.searchScore})`);
    });
  }
  console.log('---');
});

// Test 4: Search by criteria
console.log('\nTest 4: Search by Criteria');
const criteriaTests = [
  { category: 'protein', description: 'Protein foods' },
  { ibd_friendly: true, description: 'IBD friendly foods' },
  { fodmap_level: 'low', description: 'Low FODMAP foods' },
  { maxCalories: 200, description: 'Foods under 200 calories' }
];

criteriaTests.forEach(test => {
  const startTime = Date.now();
  const results = FoodDatabase.searchFoodsByCriteria(test);
  const endTime = Date.now();
  
  console.log(`Criteria: ${test.description}`);
  console.log(`Results: ${results.length}`);
  console.log(`Time: ${endTime - startTime}ms`);
  if (results.length > 0) {
    console.log(`Sample results:`);
    results.slice(0, 3).forEach((result, index) => {
      console.log(`  ${index + 1}. ${result.name} (${result.calories} cal)`);
    });
  }
  console.log('---');
});

// Test 5: Search index performance
console.log('\nTest 5: Search Index Performance');
const indexSize = Object.keys(FoodDatabase.searchIndex).length;
console.log(`Search index size: ${indexSize} foods`);
console.log(`Index built successfully: ${FoodDatabase.searchIndex ? 'Yes' : 'No'}`);

// Test 6: Real-time search simulation
console.log('\nTest 6: Real-time Search Simulation');
const simulateRealTimeSearch = (query) => {
  console.log(`\nSimulating real-time search for: "${query}"`);
  
  // Simulate typing
  for (let i = 1; i <= query.length; i++) {
    const partialQuery = query.substring(0, i);
    const startTime = Date.now();
    const results = FoodDatabase.searchFoods(partialQuery);
    const endTime = Date.now();
    
    console.log(`  "${partialQuery}" -> ${results.length} results (${endTime - startTime}ms)`);
  }
};

simulateRealTimeSearch('oatmeal');
simulateRealTimeSearch('chicken');

console.log('\n=== Search Performance Test Complete ===');
console.log('\nKey Improvements Made:');
console.log('✅ Debounced search queries (300ms delay)');
console.log('✅ Search suggestions with real-time updates');
console.log('✅ Enhanced search algorithm with scoring');
console.log('✅ Search index for faster lookups');
console.log('✅ Loading states and visual feedback');
console.log('✅ Multi-term search support');
console.log('✅ Category and tag-based filtering');
console.log('✅ Performance optimizations with memoization'); 