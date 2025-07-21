const { AI_SEARCH_CONFIG, getFreeApiTokens } = require('./src/config/ai-search-config');

// Test AI search integration for IBDPal
async function testAiSearch() {
  console.log('🧪 Testing AI Search Integration for IBDPal\n');
  console.log('📋 Current Setup: Hugging Face API (Local Development)\n');

  const tokens = getFreeApiTokens();
  
  // Check if Hugging Face token is configured
  if (tokens.HUGGING_FACE_TOKEN === 'YOUR_HUGGING_FACE_TOKEN') {
    console.log('❌ Hugging Face token not configured');
    console.log('Please set your Hugging Face token in the configuration');
    return;
  }

  console.log('✅ Hugging Face token found');
  console.log('🔗 Base URL:', AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.baseUrl);
  console.log('🤖 Model:', AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.models.textGeneration);

  // Test 1: Check Hugging Face API connection
  console.log('\n📡 Test 1: Checking Hugging Face API connection...');
  
  try {
    const healthCheck = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.baseUrl}/models/${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.models.textGeneration}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${tokens.HUGGING_FACE_TOKEN}`,
        'Content-Type': 'application/json',
      }
    });

    if (healthCheck.ok) {
      console.log('✅ Hugging Face API is accessible');
    } else {
      console.log('❌ Hugging Face API connection failed');
      console.log('Status:', healthCheck.status);
    }
  } catch (error) {
    console.log('❌ Connection error:', error.message);
  }

  // Test 2: Test AI search functionality
  console.log('\n🤖 Test 2: Testing AI search with IBD query...');
  
  const testQuery = 'diet recommendations for Crohn\'s disease';
  console.log('🔍 Test query:', testQuery);

  try {
    const aiResponse = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.baseUrl}/models/${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.models.textGeneration}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${tokens.HUGGING_FACE_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        inputs: `Search query: ${testQuery} related to inflammatory bowel disease (IBD). Provide relevant information about symptoms, treatments, diet, and lifestyle.`,
        parameters: {
          max_length: 200,
          num_return_sequences: 3,
          temperature: 0.7,
          do_sample: true
        }
      })
    });

    if (aiResponse.ok) {
      const aiData = await aiResponse.json();
      console.log('✅ AI search successful');
      console.log('📊 Response details:');
      console.log('   - Response type:', Array.isArray(aiData) ? 'Array' : 'Single object');
      console.log('   - Number of results:', Array.isArray(aiData) ? aiData.length : 1);
      
      if (Array.isArray(aiData) && aiData.length > 0) {
        console.log('\n📝 AI Response Preview:');
        console.log('─'.repeat(50));
        aiData.forEach((result, index) => {
          console.log(`Result ${index + 1}:`);
          console.log(result.generated_text || result.summary_text || 'No text content');
          console.log('─'.repeat(30));
        });
      } else if (aiData.generated_text || aiData.summary_text) {
        console.log('\n📝 AI Response:');
        console.log('─'.repeat(50));
        console.log(aiData.generated_text || aiData.summary_text);
        console.log('─'.repeat(50));
      }
    } else {
      console.log('❌ AI search failed');
      console.log('Status:', aiResponse.status);
      const errorText = await aiResponse.text();
      console.log('Error:', errorText);
    }
  } catch (error) {
    console.log('❌ AI search error:', error.message);
  }

  // Test 3: Test different query types
  console.log('\n🔬 Test 3: Testing different query types...');
  
  const testQueries = [
    'flare up symptoms',
    'medication side effects',
    'stress management techniques',
    'nutritional supplements'
  ];

  for (const query of testQueries) {
    console.log(`\n🔍 Testing: "${query}"`);
    
    try {
      const response = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.baseUrl}/models/${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.models.textGeneration}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${tokens.HUGGING_FACE_TOKEN}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          inputs: `Search query: ${query} related to inflammatory bowel disease (IBD). Provide relevant information about symptoms, treatments, diet, and lifestyle.`,
          parameters: {
            max_length: 150,
            num_return_sequences: 1,
            temperature: 0.7,
            do_sample: true
          }
        })
      });

      if (response.ok) {
        const data = await response.json();
        const content = Array.isArray(data) ? data[0]?.generated_text : data.generated_text;
        console.log('✅ Success - Response length:', content?.length || 0, 'characters');
        
        if (content) {
          console.log('📝 Preview:', content.substring(0, 100) + '...');
        }
      } else {
        console.log('❌ Failed - Status:', response.status);
      }
    } catch (error) {
      console.log('❌ Error:', error.message);
    }
  }

  // Test 4: Performance test
  console.log('\n⚡ Test 4: Performance test...');
  
  const startTime = Date.now();
  
  try {
    const response = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.baseUrl}/models/${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.models.textGeneration}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${tokens.HUGGING_FACE_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        inputs: 'What are the main symptoms of IBD?',
        parameters: {
          max_length: 100,
          num_return_sequences: 1,
          temperature: 0.5,
          do_sample: true
        }
      })
    });

    const endTime = Date.now();
    const duration = endTime - startTime;

    if (response.ok) {
      console.log('✅ Performance test successful');
      console.log('⏱️  Response time:', duration, 'ms');
      
      if (duration < 3000) {
        console.log('🚀 Excellent performance (< 3 seconds)');
      } else if (duration < 5000) {
        console.log('👍 Good performance (< 5 seconds)');
      } else {
        console.log('⚠️  Slow performance (> 5 seconds)');
      }
    } else {
      console.log('❌ Performance test failed');
    }
  } catch (error) {
    console.log('❌ Performance test error:', error.message);
  }

  // Summary
  console.log('\n📋 Integration Summary:');
  console.log('✅ Hugging Face API integration configured for local development');
  console.log('🔗 Base URL:', AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.baseUrl);
  console.log('🤖 Model:', AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.models.textGeneration);
  console.log('🔑 Token Status: Configured');
  
  console.log('\n💡 Deployment Strategy:');
  console.log('   - Local Development: Hugging Face API (current)');
  console.log('   - Cloud Production: Open WebUI (future)');
  
  console.log('\n🎉 AI search integration test completed!');
  console.log('💡 You can now use Hugging Face for AI-powered search in IBDPal');
}

// Run the test
testAiSearch().catch(console.error); 