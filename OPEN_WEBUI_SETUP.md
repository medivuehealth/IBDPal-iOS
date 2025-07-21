# Open WebUI 0.6.5 Integration Guide for IBDPal

This guide explains how to set up and use Open WebUI 0.6.5 API as a free and open-source AI search option for IBDPal.

## What is Open WebUI?

Open WebUI is a free, open-source web UI for Ollama and other LLM APIs. It provides:
- **Free and Open Source**: No usage limits or costs
- **Local Deployment**: Run on your own hardware
- **Multiple Model Support**: Compatible with various LLM models
- **REST API**: Easy integration with applications
- **Customizable**: Full control over models and settings

## Prerequisites

1. **Docker** (recommended) or direct installation
2. **At least 4GB RAM** for running LLM models
3. **Stable internet connection** for initial model downloads

## Installation Options

### Option 1: Docker (Recommended)

```bash
# Pull and run Open WebUI with Docker
docker run -d \
  --name open-webui \
  -p 8080:8080 \
  -v open-webui:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

### Option 2: Direct Installation

```bash
# Clone the repository
git clone https://github.com/open-webui/open-webui.git
cd open-webui

# Install dependencies
npm install

# Start the application
npm start
```

## Initial Setup

1. **Access Open WebUI**: Open your browser and go to `http://localhost:8080`

2. **Create Admin Account**: 
   - Click "Sign Up" to create your first account (this becomes admin)
   - Use a strong password

3. **Add Your First Model**:
   - Go to "Settings" → "Models"
   - Click "Add Model"
   - Choose a model (recommended: `llama3.2-3b-instruct` for speed)
   - Wait for download to complete

4. **Generate API Key**:
   - Go to "Settings" → "API Keys"
   - Click "Generate New Key"
   - Copy the generated key (you'll need this for IBDPal)

## IBDPal Integration

### Step 1: Update Configuration

Edit `IBDPal/src/config/ai-search-config.js`:

```javascript
// Update the Open WebUI configuration
OPEN_WEBUI: {
  baseUrl: 'http://localhost:8080/api/v1', // Your Open WebUI URL
  models: {
    chat: 'llama3.2-3b-instruct', // Your chosen model
    textGeneration: 'llama3.2-3b-instruct',
    summarization: 'llama3.2-3b-instruct'
  },
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_OPEN_WEBUI_API_KEY' // Your API key
  },
  settings: {
    temperature: 0.7,
    max_tokens: 500,
    top_p: 0.9,
    frequency_penalty: 0.0,
    presence_penalty: 0.0
  }
}
```

### Step 2: Set Environment Variable

Create or update your environment file:

```bash
# In your IBDPal project root
echo "OPEN_WEBUI_API_KEY=your_api_key_here" >> .env
```

### Step 3: Test the Integration

Run the test script:

```bash
node test_open_webui.js
```

## Available Models

Open WebUI supports many models. For IBDPal, we recommend:

### Fast Models (Good for real-time search):
- `llama3.2-3b-instruct` (3B parameters, very fast)
- `llama3.2-1b-instruct` (1B parameters, fastest)
- `phi-3-mini` (3.8B parameters, good balance)

### Quality Models (Better responses):
- `llama3.2-8b-instruct` (8B parameters, better quality)
- `llama3.2-70b-instruct` (70B parameters, best quality)
- `qwen2.5-7b-instruct` (7B parameters, good quality)

## Configuration Options

### Model Settings

You can customize the AI behavior in `ai-search-config.js`:

```javascript
settings: {
  temperature: 0.7,        // 0.0-1.0 (creativity vs consistency)
  max_tokens: 500,         // Maximum response length
  top_p: 0.9,             // 0.0-1.0 (nucleus sampling)
  frequency_penalty: 0.0,  // -2.0 to 2.0 (reduce repetition)
  presence_penalty: 0.0    // -2.0 to 2.0 (encourage new topics)
}
```

### System Prompt

The system prompt is optimized for IBD queries:

```javascript
{
  role: 'system',
  content: 'You are a helpful AI assistant specializing in inflammatory bowel disease (IBD). Provide accurate, helpful information about IBD symptoms, treatments, diet, and lifestyle management.'
}
```

## Troubleshooting

### Common Issues

1. **Connection Refused**:
   - Ensure Open WebUI is running on port 8080
   - Check firewall settings
   - Verify Docker container is running

2. **API Key Invalid**:
   - Regenerate API key in Open WebUI settings
   - Update the key in your configuration
   - Check for extra spaces or characters

3. **Model Not Found**:
   - Add the model in Open WebUI settings
   - Wait for download to complete
   - Verify model name in configuration

4. **Slow Responses**:
   - Use smaller models (1B-3B parameters)
   - Reduce `max_tokens` setting
   - Check your hardware resources

### Performance Optimization

1. **For Better Speed**:
   ```javascript
   settings: {
     temperature: 0.5,
     max_tokens: 200,
     top_p: 0.8
   }
   ```

2. **For Better Quality**:
   ```javascript
   settings: {
     temperature: 0.8,
     max_tokens: 800,
     top_p: 0.95
   }
   ```

## Security Considerations

1. **API Key Security**:
   - Never commit API keys to version control
   - Use environment variables
   - Rotate keys regularly

2. **Network Security**:
   - Use HTTPS in production
   - Configure firewall rules
   - Monitor API usage

3. **Data Privacy**:
   - Open WebUI runs locally
   - No data sent to external services
   - Full control over your data

## Production Deployment

### Docker Compose Setup

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    ports:
      - "8080:8080"
    volumes:
      - open-webui-data:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    restart: unless-stopped

  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama-data:/root/.ollama
    restart: unless-stopped

volumes:
  open-webui-data:
  ollama-data:
```

### Environment Variables

```bash
# Production environment
OPEN_WEBUI_BASE_URL=https://your-domain.com
OPEN_WEBUI_API_KEY=your_production_api_key
```

## Monitoring and Logs

### Check Open WebUI Status

```bash
# Check if container is running
docker ps | grep open-webui

# View logs
docker logs open-webui

# Check API endpoint
curl http://localhost:8080/api/v1/models
```

### IBDPal Integration Logs

The SearchScreen includes detailed logging:

```javascript
console.log('Trying Open WebUI API...');
console.log('Open WebUI AI response:', openWebUIData);
console.log('Open WebUI API failed, trying Hugging Face...');
```

## Benefits of Open WebUI

1. **Cost**: Completely free, no usage limits
2. **Privacy**: All data stays on your infrastructure
3. **Control**: Full control over models and settings
4. **Customization**: Can fine-tune for specific use cases
5. **Reliability**: No dependency on external API services

## Next Steps

1. Set up Open WebUI following this guide
2. Configure your API key in IBDPal
3. Test the integration with the provided test script
4. Customize model settings for your needs
5. Deploy to production when ready

## Support

- **Open WebUI Documentation**: https://docs.openwebui.com/
- **GitHub Repository**: https://github.com/open-webui/open-webui
- **Community Discord**: https://discord.gg/openwebui

For IBDPal-specific issues, check the main project documentation or create an issue in the IBDPal repository. 