// AI Search Configuration for IBDPal
// Free LLM APIs and settings for real-time AI-powered search
// 
// DEPLOYMENT STRATEGY:
// - Local Development: Hugging Face API (already configured with user's token)
// - Cloud Production: Open WebUI (free, open-source, self-hosted)

export const AI_SEARCH_CONFIG = {
  // Free LLM API endpoints
  FREE_LLM_APIS: {
    // Open WebUI 0.6.5 API (free and open-source)
    OPEN_WEBUI: {
      baseUrl: 'http://localhost:8080/api/v1', // Default Open WebUI endpoint
      models: {
        chat: 'llama3.2-3b-instruct', // Default model, can be changed
        textGeneration: 'llama3.2-3b-instruct',
        summarization: 'llama3.2-3b-instruct'
      },
      headers: {
        'Content-Type': 'application/json',
        // Open WebUI uses API key authentication
        'Authorization': 'Bearer [OPEN_WEBUI_API_KEY]'
      },
      // Open WebUI specific settings
      settings: {
        temperature: 0.7,
        max_tokens: 500,
        top_p: 0.9,
        frequency_penalty: 0.0,
        presence_penalty: 0.0
      }
    },

    // Hugging Face Inference API (free tier)
    HUGGING_FACE: {
      baseUrl: 'https://api-inference.huggingface.co',
      models: {
        textGeneration: 'facebook/bart-large-cnn',
        summarization: 'facebook/bart-large-cnn',
        questionAnswering: 'deepset/roberta-base-squad2'
      },
      headers: {
        'Content-Type': 'application/json',
        // Add your Hugging Face token here
        'Authorization': `Bearer ${process.env.HUGGING_FACE_TOKEN || '[HUGGING_FACE_TOKEN]'}`
      }
    },
    
    // OpenAI API (free tier with credits)
    OPENAI: {
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-3.5-turbo',
      headers: {
        'Content-Type': 'application/json',
        // Add your OpenAI API key here
        'Authorization': 'Bearer [OPENAI_API_KEY]'
      }
    },
    
    // Cohere API (free tier)
    COHERE: {
      baseUrl: 'https://api.cohere.ai/v1',
      model: 'command',
      headers: {
        'Content-Type': 'application/json',
        // Add your Cohere API key here
        'Authorization': 'Bearer [COHERE_API_KEY]'
      }
    }
  },

  // Local AI processing settings
  LOCAL_AI: {
    // Intent classification keywords
    INTENT_KEYWORDS: {
      symptom: ['pain', 'diarrhea', 'blood', 'fatigue', 'weight loss', 'fever', 'cramping', 'nausea'],
      treatment: ['medication', 'biologics', 'surgery', 'therapy', 'remission', 'drugs', 'injection'],
      diet: ['food', 'nutrition', 'fiber', 'protein', 'vitamins', 'supplements', 'eating', 'meal'],
      lifestyle: ['exercise', 'stress', 'sleep', 'work', 'social', 'mental health', 'activity'],
      flare: ['flare-up', 'attack', 'worsening', 'acute', 'severe', 'episode', 'exacerbation'],
      remission: ['better', 'improved', 'stable', 'controlled', 'manageable', 'well', 'good']
    },

    // Response templates for different intents
    RESPONSE_TEMPLATES: {
      symptom: [
        {
          title: 'IBD Symptoms Analysis',
          template: 'Based on your query about "{query}", common IBD symptoms include abdominal pain, diarrhea, rectal bleeding, fatigue, and unintended weight loss. It\'s important to track your symptoms and discuss them with your healthcare provider.',
          category: 'symptoms'
        },
        {
          title: 'Symptom Management Tips',
          template: 'For managing "{query}"-related symptoms: keep a symptom diary, identify triggers, maintain regular check-ups, and follow your treatment plan. Consider stress management techniques as stress can worsen symptoms.',
          category: 'management'
        }
      ],
      treatment: [
        {
          title: 'Treatment Options for IBD',
          template: 'Regarding "{query}" treatments: IBD treatment typically includes medications (aminosalicylates, corticosteroids, immunomodulators, biologics), lifestyle changes, and sometimes surgery. Your treatment plan should be personalized.',
          category: 'treatment'
        },
        {
          title: 'Treatment Effectiveness',
          template: 'Treatment effectiveness for "{query}" varies by individual. Regular monitoring, medication adherence, and open communication with your healthcare team are crucial for optimal outcomes.',
          category: 'monitoring'
        }
      ],
      diet: [
        {
          title: 'IBD Diet Recommendations',
          template: 'For "{query}" and IBD: focus on easily digestible foods, avoid trigger foods, maintain adequate nutrition, and consider working with a registered dietitian. Keep a food diary to identify personal triggers.',
          category: 'nutrition'
        },
        {
          title: 'Nutritional Support',
          template: 'Nutritional support for "{query}" includes ensuring adequate protein, vitamins, and minerals. Consider supplements if needed, and stay hydrated. Small, frequent meals may be better tolerated.',
          category: 'nutrition'
        }
      ],
      lifestyle: [
        {
          title: 'Lifestyle Management for IBD',
          template: 'Lifestyle factors for "{query}" include stress management, regular exercise (as tolerated), adequate sleep, and maintaining social connections. These can significantly impact your IBD management.',
          category: 'lifestyle'
        },
        {
          title: 'Mental Health and IBD',
          template: 'Mental health is crucial for "{query}" management. Consider counseling, support groups, mindfulness practices, and open communication with loved ones about your condition.',
          category: 'mental-health'
        }
      ],
      flare: [
        {
          title: 'Flare Management Strategies',
          template: 'For managing "{query}" flares: rest more, follow a bland diet, stay hydrated, avoid stress, and contact your healthcare provider if symptoms worsen. Have an action plan ready.',
          category: 'flare-management'
        },
        {
          title: 'Flare Prevention',
          template: 'To prevent "{query}" flares: identify and avoid triggers, maintain medication adherence, manage stress, get adequate sleep, and follow your treatment plan consistently.',
          category: 'prevention'
        }
      ],
      remission: [
        {
          title: 'Maintaining Remission',
          template: 'To maintain remission with "{query}": continue medications as prescribed, attend regular check-ups, maintain a healthy lifestyle, and be aware of early warning signs of flares.',
          category: 'remission'
        },
        {
          title: 'Remission Monitoring',
          template: 'Regular monitoring during remission for "{query}" includes tracking symptoms, maintaining medication adherence, and reporting any changes to your healthcare team promptly.',
          category: 'monitoring'
        }
      ],
      general: [
        {
          title: 'IBD Information and Support',
          template: 'Regarding "{query}" and IBD: this is a chronic condition that requires ongoing management. Work closely with your healthcare team, educate yourself, and connect with support communities.',
          category: 'general'
        },
        {
          title: 'Living Well with IBD',
          template: 'Living well with IBD involves understanding your condition, following your treatment plan, maintaining a healthy lifestyle, and seeking support when needed. You\'re not alone in this journey.',
          category: 'support'
        }
      ]
    }
  },

  // Search settings
  SEARCH_SETTINGS: {
    // Minimum query length for AI search
    MIN_QUERY_LENGTH: 3,
    
    // Debounce delay for AI search (ms)
    AI_SEARCH_DELAY: 500,
    
    // Maximum AI results to show
    MAX_AI_RESULTS: 3,
    
    // Enable/disable different search types
    ENABLE_AI_SEARCH: true,
    ENABLE_INSTANT_SEARCH: true,
    ENABLE_WEB_SEARCH: true,
    
    // Fallback to local AI if external API fails
    FALLBACK_TO_LOCAL_AI: true
  },

  // Error messages
  ERROR_MESSAGES: {
    AI_SEARCH_FAILED: 'AI search temporarily unavailable. Showing local results.',
    NETWORK_ERROR: 'Network error. Please check your connection.',
    API_LIMIT: 'API limit reached. Using local AI processing.',
    INVALID_QUERY: 'Please enter a valid search query.'
  }
};

// Helper function to get free API tokens
export const getFreeApiTokens = () => {
  return {
    // Open WebUI API key (set this to your Open WebUI API key)
    OPEN_WEBUI_API_KEY: process.env.OPEN_WEBUI_API_KEY || '[OPEN_WEBUI_API_KEY]',
    // Add your Hugging Face token here
    HUGGING_FACE_TOKEN: process.env.HUGGING_FACE_TOKEN || '[HUGGING_FACE_TOKEN]',
    OPENAI_API_KEY: process.env.OPENAI_API_KEY || '[OPENAI_API_KEY]',
    COHERE_API_KEY: process.env.COHERE_API_KEY || '[COHERE_API_KEY]'
  };
};

// Helper function to check if AI search is available
export const isAiSearchAvailable = () => {
  const tokens = getFreeApiTokens();
  return tokens.OPEN_WEBUI_API_KEY !== '[OPEN_WEBUI_API_KEY]' ||
         tokens.HUGGING_FACE_TOKEN !== '[HUGGING_FACE_TOKEN]' ||
         tokens.OPENAI_API_KEY !== '[OPENAI_API_KEY]' ||
         tokens.COHERE_API_KEY !== '[COHERE_API_KEY]';
};

export default AI_SEARCH_CONFIG; 