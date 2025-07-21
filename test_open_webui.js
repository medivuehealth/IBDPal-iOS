const { AI_SEARCH_CONFIG, getFreeApiTokens } = require('./src/config/ai-search-config');

// Test Open WebUI API integration
async function testOpenWebUI() {
  console.log('🧪 Testing Open WebUI API Integration for IBDPal\n');

  const tokens = getFreeApiTokens();
  
  // Check if Open WebUI API key is configured
  if (tokens.OPEN_WEBUI_API_KEY === '[OPEN_WEBUI_API_KEY]') {
    console.log('❌ Open WebUI API key not configured');
    console.log('Please set your Open WebUI API key in the configuration');
    console.log('You can get an API key from your Open WebUI instance at http://localhost:8080');
    return;
  }

  console.log('✅ Open WebUI API key found');
  console.log('🔗 Base URL:', AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.baseUrl);
  console.log('🤖 Model:', AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.models.chat);

  // Test 1: Check if Open WebUI is running
  console.log('\n📡 Test 1: Checking Open WebUI connection...');
  
  try {
    const healthCheck = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.baseUrl}/models`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${tokens.OPEN_WEBUI_API_KEY}`,
        'Content-Type': 'application/json',
      }
    });

    if (healthCheck.ok) {
      const models = await healthCheck.json();
      console.log('✅ Open WebUI is running');
      console.log('📋 Available models:', models.data?.length || 0);
      
      if (models.data && models.data.length > 0) {
        console.log('📝 Model list:');
        models.data.forEach(model => {
          console.log(`   - ${model.id} (${model.object})`);
        });
      }
    } else {
      console.log('❌ Open WebUI connection failed');
      console.log('Status:', healthCheck.status);
      console.log('Response:', await healthCheck.text());
    }
  } catch (error) {
    console.log('❌ Connection error:', error.message);
    console.log('💡 Make sure Open WebUI is running on http://localhost:8080');
  }

  // Test 2: Test AI search functionality
  console.log('\n🤖 Test 2: Testing AI search with IBD query...');
  
  const testQuery = 'diet recommendations for Crohn\'s disease';
  console.log('🔍 Test query:', testQuery);

  try {
    const aiResponse = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${tokens.OPEN_WEBUI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.models.chat,
        messages: [
          {
            role: 'system',
            content: 'You are a helpful AI assistant specializing in inflammatory bowel disease (IBD). Provide accurate, helpful information about IBD symptoms, treatments, diet, and lifestyle management.'
          },
          {
            role: 'user',
            content: `Search query: ${testQuery} related to inflammatory bowel disease (IBD). Provide relevant information about symptoms, treatments, diet, and lifestyle.`
          }
        ],
        ...AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.settings
      })
    });

    if (aiResponse.ok) {
      const aiData = await aiResponse.json();
      console.log('✅ AI search successful');
      console.log('📊 Response details:');
      console.log('   - Model used:', aiData.model);
      console.log('   - Tokens used:', aiData.usage?.total_tokens || 'N/A');
      console.log('   - Response length:', aiData.choices?.[0]?.message?.content?.length || 0, 'characters');
      
      if (aiData.choices?.[0]?.message?.content) {
        console.log('\n📝 AI Response:');
        console.log('─'.repeat(50));
        console.log(aiData.choices[0].message.content);
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
      const response = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${tokens.OPEN_WEBUI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.models.chat,
          messages: [
            {
              role: 'system',
              content: 'You are a helpful AI assistant specializing in inflammatory bowel disease (IBD). Provide accurate, helpful information about IBD symptoms, treatments, diet, and lifestyle management.'
            },
            {
              role: 'user',
              content: `Search query: ${query} related to inflammatory bowel disease (IBD). Provide relevant information about symptoms, treatments, diet, and lifestyle.`
            }
          ],
          max_tokens: 200, // Shorter for testing
          temperature: 0.7
        })
      });

      if (response.ok) {
        const data = await response.json();
        const content = data.choices?.[0]?.message?.content;
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
    const response = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${tokens.OPEN_WEBUI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.models.chat,
        messages: [
          {
            role: 'system',
            content: 'You are a helpful AI assistant specializing in inflammatory bowel disease (IBD).'
          },
          {
            role: 'user',
            content: 'What are the main symptoms of IBD?'
          }
        ],
        max_tokens: 100,
        temperature: 0.5
      })
    });

    const endTime = Date.now();
    const duration = endTime - startTime;

    if (response.ok) {
      console.log('✅ Performance test successful');
      console.log('⏱️  Response time:', duration, 'ms');
      
      if (duration < 2000) {
        console.log('🚀 Excellent performance (< 2 seconds)');
      } else if (duration < 5000) {
        console.log('👍 Good performance (< 5 seconds)');
      } else {
        console.log('⚠️  Slow performance (> 5 seconds)');
        console.log('💡 Consider using a smaller model for better speed');
      }
    } else {
      console.log('❌ Performance test failed');
    }
  } catch (error) {
    console.log('❌ Performance test error:', error.message);
  }

  // Summary
  console.log('\n📋 Integration Summary:');
  console.log('✅ Open WebUI API integration configured');
  console.log('🔗 Base URL:', AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.baseUrl);
  console.log('🤖 Default model:', AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.models.chat);
  console.log('⚙️  Settings:', JSON.stringify(AI_SEARCH_CONFIG.FREE_LLM_APIS.OPEN_WEBUI.settings, null, 2));
  
  console.log('\n🎉 Open WebUI integration test completed!');
  console.log('💡 You can now use Open WebUI for AI-powered search in IBDPal');
}

// Run the test
testOpenWebUI().catch(console.error); 