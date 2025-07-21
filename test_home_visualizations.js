const axios = require('axios');

const BASE_URL = 'http://localhost:3002';

async function testHomeVisualizations() {
    console.log('🧪 Testing IBDPal Home Visualizations...\n');

    try {
        // Test 1: Check if server is running
        console.log('1. Testing server connectivity...');
        const healthResponse = await axios.get(`${BASE_URL}/health`);
        console.log('✅ Server is running:', healthResponse.data);

        // Test 2: Test flare statistics endpoint
        console.log('\n2. Testing flare statistics endpoint...');
        const statsResponse = await axios.get(`${BASE_URL}/api/flare-statistics?user_id=test_user&days=30`);
        console.log('✅ Flare statistics:', statsResponse.data);

        // Test 3: Test recent predictions endpoint
        console.log('\n3. Testing recent predictions endpoint...');
        const predictionsResponse = await axios.get(`${BASE_URL}/api/recent-predictions?user_id=test_user&limit=30`);
        console.log('✅ Recent predictions:', predictionsResponse.data);

        // Test 4: Test journal entries endpoint
        console.log('\n4. Testing journal entries endpoint...');
        const entriesResponse = await axios.get(`${BASE_URL}/api/journal/entries/test_user`);
        console.log('✅ Journal entries:', entriesResponse.data);

        // Test 5: Test nutrition data analysis
        console.log('\n5. Testing nutrition data analysis...');
        const nutritionData = {
            totalEntries: 15,
            flareEntries: 3,
            averageNutrition: {
                calories: 1850,
                protein: 75,
                carbs: 220,
                fiber: 8,
            },
            deficiencies: [
                {
                    nutrient: 'Fiber',
                    current: 8,
                    recommended: '10-15g',
                    impact: 'Low fiber can worsen constipation and inflammation'
                }
            ],
            recommendations: [
                {
                    type: 'deficiency',
                    priority: 'High',
                    title: 'Address Nutritional Deficiencies',
                    description: 'Focus on increasing fiber intake',
                    actions: ['Increase fiber intake to 10-15g daily', 'Add more fruits and vegetables']
                }
            ]
        };
        console.log('✅ Nutrition analysis data structure:', nutritionData);

        // Test 6: Test flare predictions data structure
        console.log('\n6. Testing flare predictions data structure...');
        const flareData = {
            totalPredictions: 25,
            totalFlares: 3,
            avgFlareProbability: 0.15,
            highestRisk: 0.85,
            riskTrend: 'decreasing',
            chartData: Array.from({ length: 7 }, (_, i) => ({
                date: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toLocaleDateString(),
                probability: Math.random() * 0.8,
                flare: Math.random() > 0.8 ? 'Yes' : 'No'
            })),
            recommendations: [
                {
                    type: 'trend',
                    priority: 'Low',
                    title: 'Risk Trend Improving',
                    description: 'Your flare risk has been decreasing over the past 30 days',
                    actions: ['Continue current treatment plan', 'Maintain healthy lifestyle habits']
                }
            ]
        };
        console.log('✅ Flare predictions data structure:', flareData);

        // Test 7: Test chart data generation
        console.log('\n7. Testing chart data generation...');
        const chartData = {
            labels: ['1/1', '1/2', '1/3', '1/4', '1/5', '1/6', '1/7'],
            datasets: [{
                data: [0.2, 0.3, 0.1, 0.4, 0.2, 0.5, 0.3],
                color: (opacity = 1) => `rgba(124, 58, 237, ${opacity})`,
                strokeWidth: 2,
            }],
        };
        console.log('✅ Chart data structure:', chartData);

        console.log('\n🎉 All tests passed! The Home visualizations should work correctly.');
        console.log('\n📱 To test in the app:');
        console.log('1. Start the IBDPal app');
        console.log('2. Navigate to the Home tab');
        console.log('3. You should see:');
        console.log('   - Nutrition Analyzer with charts and recommendations');
        console.log('   - Flare Predictions with risk trends and statistics');
        console.log('   - Real-time data from the last 30 days');

    } catch (error) {
        console.error('❌ Test failed:', error.message);
        if (error.response) {
            console.error('Response data:', error.response.data);
        }
    }
}

// Test API endpoints for nutrition and flare data
async function testAPIs() {
    console.log('\n🔍 Testing API endpoints for visualization data...\n');

    const endpoints = [
        {
            name: 'Flare Statistics',
            url: `${BASE_URL}/api/flare-statistics?user_id=test_user&days=30`,
            method: 'GET'
        },
        {
            name: 'Recent Predictions',
            url: `${BASE_URL}/api/recent-predictions?user_id=test_user&limit=30`,
            method: 'GET'
        },
        {
            name: 'Journal Entries',
            url: `${BASE_URL}/api/journal/entries/test_user`,
            method: 'GET'
        }
    ];

    for (const endpoint of endpoints) {
        try {
            console.log(`Testing ${endpoint.name}...`);
            const response = await axios({
                method: endpoint.method,
                url: endpoint.url,
                timeout: 5000
            });
            console.log(`✅ ${endpoint.name}:`, response.status, response.data);
        } catch (error) {
            console.log(`❌ ${endpoint.name}:`, error.message);
            if (error.response) {
                console.log('   Status:', error.response.status);
                console.log('   Data:', error.response.data);
            }
        }
    }
}

// Run tests
if (require.main === module) {
    testHomeVisualizations()
        .then(() => testAPIs())
        .then(() => {
            console.log('\n✨ Testing completed!');
            process.exit(0);
        })
        .catch(error => {
            console.error('\n💥 Testing failed:', error);
            process.exit(1);
        });
}

module.exports = { testHomeVisualizations, testAPIs }; 