// Test script for real-time search functionality
console.log('=== Testing Real-Time Search ===\n');

// Mock search database (same as in SearchScreen)
const searchDatabase = [
  {
    id: 1,
    title: 'IBD Diet Guidelines - Mayo Clinic',
    description: 'Comprehensive dietary recommendations for IBD patients. Learn about foods to avoid and nutritional strategies for managing inflammatory bowel disease.',
    url: 'https://www.mayoclinic.org/ibd-diet',
    source: 'Mayo Clinic',
    type: 'medical',
    tags: ['diet', 'nutrition', 'guidelines', 'foods'],
    relevance: 95,
  },
  {
    id: 2,
    title: 'Managing IBD Flare-ups - Crohn\'s & Colitis Foundation',
    description: 'Expert tips and strategies for managing IBD flare-ups. Learn about early warning signs and effective management techniques.',
    url: 'https://www.crohnscolitisfoundation.org/flare-management',
    source: 'Crohn\'s & Colitis Foundation',
    type: 'medical',
    tags: ['flare', 'management', 'symptoms', 'treatment'],
    relevance: 92,
  },
  {
    id: 3,
    title: 'IBD Medications Guide - WebMD',
    description: 'Complete guide to medications used in IBD treatment including biologics, immunomodulators, and other therapies.',
    url: 'https://www.webmd.com/ibd-medications',
    source: 'WebMD',
    type: 'medical',
    tags: ['medications', 'biologics', 'treatment', 'drugs'],
    relevance: 88,
  },
  {
    id: 4,
    title: 'Living with IBD - Patient Stories',
    description: 'Real patient experiences and tips for daily living with inflammatory bowel disease. Community support and advice.',
    url: 'https://www.ibdpatientstories.org',
    source: 'IBD Patient Community',
    type: 'community',
    tags: ['lifestyle', 'patient', 'stories', 'support'],
    relevance: 85,
  },
  {
    id: 5,
    title: 'IBD Research Updates - Nature',
    description: 'Latest research findings and treatment advances in inflammatory bowel disease from leading medical journals.',
    url: 'https://www.nature.com/ibd-research',
    source: 'Nature Medicine',
    type: 'research',
    tags: ['research', 'latest', 'advances', 'studies'],
    relevance: 82,
  },
  {
    id: 6,
    title: 'Crohn\'s Disease Symptoms and Treatment',
    description: 'Comprehensive guide to Crohn\'s disease symptoms, diagnosis, and treatment options.',
    url: 'https://www.crohnsdisease.com',
    source: 'Crohn\'s Disease Resource',
    type: 'medical',
    tags: ['crohns', 'symptoms', 'diagnosis', 'treatment'],
    relevance: 90,
  },
  {
    id: 7,
    title: 'Ulcerative Colitis Management',
    description: 'Complete guide to managing ulcerative colitis including diet, medications, and lifestyle changes.',
    url: 'https://www.ulcerativecolitis.org',
    source: 'UC Foundation',
    type: 'medical',
    tags: ['ulcerative', 'colitis', 'management', 'lifestyle'],
    relevance: 87,
  },
  {
    id: 8,
    title: 'IBD and Mental Health',
    description: 'Understanding the connection between IBD and mental health, including stress management and coping strategies.',
    url: 'https://www.ibdmentalhealth.org',
    source: 'IBD Mental Health',
    type: 'wellness',
    tags: ['mental', 'health', 'stress', 'coping'],
    relevance: 80,
  },
];

// Real-time search function (same as in SearchScreen)
const performInstantSearch = (query) => {
  console.log('Performing instant search for:', query);
  
  if (!query.trim()) {
    console.log('Empty query, no results');
    return [];
  }

  const searchTerm = query.toLowerCase();
  console.log('Search term:', searchTerm);
  
  // Simple search - just check if the term appears anywhere
  const results = searchDatabase.filter(item => {
    const titleMatch = item.title.toLowerCase().includes(searchTerm);
    const descMatch = item.description.toLowerCase().includes(searchTerm);
    const tagMatch = item.tags.some(tag => tag.toLowerCase().includes(searchTerm));
    
    const matches = titleMatch || descMatch || tagMatch;
    console.log(`"${item.title}": title=${titleMatch}, desc=${descMatch}, tag=${tagMatch}`);
    return matches;
  });

  console.log('Found results:', results.length);

  // Sort by relevance (title matches first, then tags, then description)
  const scoredResults = results.map(item => {
    let score = 0;
    const searchTerm = query.toLowerCase();
    
    if (item.title.toLowerCase().includes(searchTerm)) score += 10;
    if (item.tags.some(tag => tag.toLowerCase().includes(searchTerm))) score += 5;
    if (item.description.toLowerCase().includes(searchTerm)) score += 3;
    
    return { ...item, searchScore: score };
  });

  scoredResults.sort((a, b) => b.searchScore - a.searchScore);
  const topResults = scoredResults.slice(0, 5);
  
  console.log('Instant results:', topResults.length);
  return topResults;
};

// Test cases
const testQueries = [
  'diet',
  'flare',
  'medication',
  'crohn',
  'colitis',
  'mental',
  'treatment',
  'symptoms'
];

console.log('Testing search queries:\n');

testQueries.forEach(query => {
  console.log(`\n--- Testing: "${query}" ---`);
  const results = performInstantSearch(query);
  
  if (results.length > 0) {
    console.log(`✅ Found ${results.length} results:`);
    results.forEach((result, index) => {
      console.log(`  ${index + 1}. ${result.title} (Score: ${result.searchScore})`);
    });
  } else {
    console.log(`❌ No results found for "${query}"`);
  }
});

console.log('\n=== Real-Time Search Test Complete ===');
console.log('\nExpected behavior:');
console.log('✅ "diet" should find IBD Diet Guidelines');
console.log('✅ "flare" should find Managing IBD Flare-ups');
console.log('✅ "medication" should find IBD Medications Guide');
console.log('✅ "crohn" should find Crohn\'s Disease Symptoms');
console.log('✅ "colitis" should find Ulcerative Colitis Management');
console.log('✅ "mental" should find IBD and Mental Health'); 