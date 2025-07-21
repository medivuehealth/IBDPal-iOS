# AI-Powered Search Setup Guide

## 🚀 Real-Time AI Search for IBDPal

This guide will help you set up free AI-powered search using various free LLM APIs.

## 📋 Features

- **Real-time AI search** with intelligent responses
- **Free LLM APIs** integration (Hugging Face, OpenAI, Cohere)
- **Local AI fallback** when external APIs are unavailable
- **Intent classification** for better search results
- **Instant results** with AI insights

## 🔧 Setup Instructions

### 1. Hugging Face (Recommended - Completely Free)

1. Go to [Hugging Face](https://huggingface.co/)
2. Create a free account
3. Go to [Settings > Access Tokens](https://huggingface.co/settings/tokens)
4. Create a new token
5. Copy the token and add it to your environment variables

```bash
# Add to your .env file
HUGGING_FACE_TOKEN=hf_your_token_here
```

### 2. OpenAI API (Free Credits Available)

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Create an account
3. Go to [API Keys](https://platform.openai.com/api-keys)
4. Create a new API key
5. Add it to your environment variables

```bash
# Add to your .env file
OPENAI_API_KEY=sk-your_api_key_here
```

### 3. Cohere API (Free Tier)

1. Go to [Cohere Dashboard](https://dashboard.cohere.ai/)
2. Create a free account
3. Go to [API Keys](https://dashboard.cohere.ai/api-keys)
4. Create a new API key
5. Add it to your environment variables

```bash
# Add to your .env file
COHERE_API_KEY=your_cohere_api_key_here
```

## 🎯 How It Works

### AI Search Flow

1. **User types query** → Real-time processing
2. **Intent classification** → Determines search category
3. **AI processing** → Generates intelligent responses
4. **Results display** → Instant AI insights + web results

### Search Types

- **Instant Results**: Immediate database matches
- **AI Insights**: Intelligent responses from LLM
- **Web Results**: Enhanced web search results

## 🔍 Search Examples

### Example Queries and AI Responses

| Query | AI Intent | AI Response |
|-------|-----------|-------------|
| "diet" | Diet | Nutritional recommendations and food guidelines |
| "flare" | Flare | Flare management strategies and prevention |
| "medication" | Treatment | Treatment options and medication information |
| "symptoms" | Symptom | Symptom analysis and management tips |
| "stress" | Lifestyle | Stress management and mental health support |

## 🛠️ Configuration

### Update AI Search Config

Edit `src/config/ai-search-config.js`:

```javascript
// Add your API tokens
export const getFreeApiTokens = () => {
  return {
    HUGGING_FACE_TOKEN: 'your_hugging_face_token',
    OPENAI_API_KEY: 'your_openai_api_key',
    COHERE_API_KEY: 'your_cohere_api_key'
  };
};
```

### Environment Variables

Create a `.env` file in your IBDPal directory:

```env
# AI Search API Keys
HUGGING_FACE_TOKEN=hf_your_token_here
OPENAI_API_KEY=sk-your_openai_key_here
COHERE_API_KEY=your_cohere_key_here

# Search Settings
ENABLE_AI_SEARCH=true
ENABLE_INSTANT_SEARCH=true
ENABLE_WEB_SEARCH=true
```

## 🎨 UI Features

### Visual Indicators

- 🤖 **Robot icon**: AI-powered search
- ⚡ **Lightning bolt**: Instant results
- 🔍 **Magnifying glass**: Web search
- 📊 **Debug info**: Search statistics

### Result Types

- **AI Insights**: Intelligent responses with robot icon
- **Instant Results**: Quick database matches
- **Web Results**: Enhanced web search results

## 🔧 Troubleshooting

### Common Issues

1. **API Limit Reached**
   - Solution: Falls back to local AI processing
   - Check API usage limits

2. **Network Error**
   - Solution: Uses local AI processing
   - Check internet connection

3. **Invalid Token**
   - Solution: Uses local AI processing
   - Verify API token is correct

### Debug Information

The search screen shows debug information:
- Query being searched
- Number of instant results
- Number of AI results
- Number of web results

## 🚀 Free API Limits

### Hugging Face
- **Free tier**: Unlimited requests
- **Rate limit**: 30,000 requests/month
- **Models**: Access to thousands of models

### OpenAI
- **Free credits**: $5 worth of credits
- **Rate limit**: 3 requests/minute
- **Model**: GPT-3.5-turbo

### Cohere
- **Free tier**: 5 requests/minute
- **Rate limit**: 100 requests/day
- **Model**: Command model

## 📱 Testing the AI Search

1. **Start the app**
2. **Go to Search tab**
3. **Type a query** (e.g., "diet", "flare", "medication")
4. **Watch for AI insights** appearing
5. **Check debug info** for search statistics

## 🎯 Expected Behavior

### Real-time Search
- Results appear as you type
- AI insights show after 500ms delay
- Instant results show immediately
- Web results show after 200ms delay

### AI Responses
- Contextual to IBD
- Personalized to query
- Multiple response types
- Fallback to local AI

## 🔮 Future Enhancements

- **Voice search** integration
- **Image search** for symptoms
- **Multi-language** support
- **Personalized** AI responses
- **Offline AI** processing

## 📞 Support

If you encounter issues:

1. Check API tokens are correct
2. Verify internet connection
3. Check API usage limits
4. Review debug information
5. Test with simple queries first

## 🎉 Success!

Once configured, you'll have:
- ✅ Real-time AI-powered search
- ✅ Free LLM integration
- ✅ Intelligent responses
- ✅ Fallback processing
- ✅ Enhanced user experience

The search will now provide intelligent, contextual responses to user queries about IBD, making it a powerful tool for patients and caregivers. 