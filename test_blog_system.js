const axios = require('axios');

const API_BASE_URL = 'http://localhost:3004/api';
let authToken = '';

// Test user credentials
const testUser = {
    email: 'test@example.com',
    password: 'testpassword123'
};

async function testBlogSystem() {
    console.log('🧪 Testing IBDPal Blog System...\n');

    try {
        // Step 1: Login to get auth token
        console.log('1. Testing user login...');
        const loginResponse = await axios.post(`${API_BASE_URL}/auth/login`, testUser);
        authToken = loginResponse.data.token;
        console.log('✅ Login successful\n');

        // Step 2: Test getting stories
        console.log('2. Testing get stories...');
        const storiesResponse = await axios.get(`${API_BASE_URL}/blogs/stories`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log(`✅ Retrieved ${storiesResponse.data.data.stories.length} stories\n`);

        // Step 3: Test creating a story
        console.log('3. Testing create story...');
        const newStory = {
            title: 'My IBD Journey - Test Story',
            content: 'This is a test story about living with IBD. I wanted to share my experience with the community.',
            diseaseType: 'crohns',
            tags: ['test', 'journey', 'support'],
            isAnonymous: false
        };

        const createStoryResponse = await axios.post(`${API_BASE_URL}/blogs/stories`, newStory, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        const storyId = createStoryResponse.data.data.id;
        console.log(`✅ Story created with ID: ${storyId}\n`);

        // Step 4: Test getting a specific story
        console.log('4. Testing get specific story...');
        const storyResponse = await axios.get(`${API_BASE_URL}/blogs/stories/${storyId}`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log(`✅ Retrieved story: ${storyResponse.data.data.story.title}\n`);

        // Step 5: Test adding a comment
        console.log('5. Testing add comment...');
        const newComment = {
            content: 'Thank you for sharing your story! This is very helpful.',
            isAnonymous: false
        };

        const commentResponse = await axios.post(`${API_BASE_URL}/blogs/stories/${storyId}/comments`, newComment, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        const commentId = commentResponse.data.data.id;
        console.log(`✅ Comment added with ID: ${commentId}\n`);

        // Step 6: Test liking a story
        console.log('6. Testing like story...');
        await axios.post(`${API_BASE_URL}/blogs/stories/${storyId}/like`, {}, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log('✅ Story liked\n');

        // Step 7: Test getting popular tags
        console.log('7. Testing get popular tags...');
        const tagsResponse = await axios.get(`${API_BASE_URL}/blogs/tags`);
        console.log(`✅ Retrieved ${tagsResponse.data.data.length} popular tags\n`);

        // Step 8: Test getting user stories
        console.log('8. Testing get user stories...');
        const userStoriesResponse = await axios.get(`${API_BASE_URL}/blogs/stories/user/${testUser.email}`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log(`✅ Retrieved ${userStoriesResponse.data.data.stories.length} user stories\n`);

        // Step 9: Test updating a story
        console.log('9. Testing update story...');
        const updateData = {
            title: 'My IBD Journey - Updated Test Story',
            content: 'This is an updated test story about living with IBD. I wanted to share my experience with the community.',
            tags: ['test', 'journey', 'support', 'updated']
        };

        await axios.put(`${API_BASE_URL}/blogs/stories/${storyId}`, updateData, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log('✅ Story updated\n');

        // Step 10: Test unlike story
        console.log('10. Testing unlike story...');
        await axios.post(`${API_BASE_URL}/blogs/stories/${storyId}/like`, {}, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log('✅ Story unliked\n');

        // Step 11: Test deleting the story
        console.log('11. Testing delete story...');
        await axios.delete(`${API_BASE_URL}/blogs/stories/${storyId}`, {
            headers: { Authorization: `Bearer ${authToken}` }
        });
        console.log('✅ Story deleted\n');

        console.log('🎉 All blog system tests passed successfully!');

    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        
        if (error.response?.status === 401) {
            console.log('💡 Make sure the user exists and credentials are correct');
        } else if (error.response?.status === 500) {
            console.log('💡 Check if the database is running and tables are created');
        }
    }
}

// Run the tests
testBlogSystem(); 