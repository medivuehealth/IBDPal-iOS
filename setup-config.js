#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log('🔧 IBDPal Configuration Setup');
console.log('=============================\n');

// Check if config.env already exists
const configPath = path.join(__dirname, 'config.env');
const envExamplePath = path.join(__dirname, 'env.example');

if (fs.existsSync(configPath)) {
  console.log('✅ config.env already exists');
  console.log('📝 Current configuration:');
  console.log('------------------------');
  
  const config = fs.readFileSync(configPath, 'utf8');
  console.log(config);
  
  rl.question('\nDo you want to update your configuration? (y/n): ', (answer) => {
    if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
      setupConfiguration();
    } else {
      console.log('Configuration setup cancelled.');
      rl.close();
    }
  });
} else {
  console.log('❌ config.env not found');
  console.log('📝 Creating new configuration...\n');
  setupConfiguration();
}

function setupConfiguration() {
  console.log('Please provide the following configuration values:\n');
  
  const questions = [
    {
      key: 'HUGGING_FACE_TOKEN',
      question: 'Enter your Hugging Face API token (or press Enter to skip): ',
      default: ''
    },
    {
      key: 'OPEN_WEBUI_API_KEY',
      question: 'Enter your Open WebUI API key (or press Enter to skip): ',
      default: ''
    },
    {
      key: 'OPENAI_API_KEY',
      question: 'Enter your OpenAI API key (or press Enter to skip): ',
      default: ''
    },
    {
      key: 'COHERE_API_KEY',
      question: 'Enter your Cohere API key (or press Enter to skip): ',
      default: ''
    },
    {
      key: 'JWT_SECRET',
      question: 'Enter a secure JWT secret (or press Enter for default): ',
      default: 'your-super-secret-jwt-key-change-in-production'
    },
    {
      key: 'DB_PASSWORD',
      question: 'Enter your database password (or press Enter for default): ',
      default: 'postgres'
    }
  ];
  
  const config = {};
  let questionIndex = 0;
  
  function askQuestion() {
    if (questionIndex >= questions.length) {
      createConfigFile(config);
      return;
    }
    
    const question = questions[questionIndex];
    rl.question(question.question, (answer) => {
      config[question.key] = answer || question.default;
      questionIndex++;
      askQuestion();
    });
  }
  
  askQuestion();
}

function createConfigFile(config) {
  console.log('\n📝 Creating config.env file...');
  
  const configContent = `# IBDPal iOS App Configuration
# This app shares the MediVue database with the MediVue website
APP_NAME=IBDPal
APP_VERSION=1.0.0
NODE_ENV=development
APP_TYPE=ios

# Server Configuration
SERVER_PORT=3004
JWT_SECRET=${config.JWT_SECRET}
JWT_EXPIRES_IN=24h

# Database Configuration - Shared MediVue Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=medivue
DB_USER=postgres
DB_PASSWORD=${config.DB_PASSWORD}
DB_SSL=false

# API Configuration
API_BASE_URL=http://localhost:3004/api
API_TIMEOUT=30000

# CORS Configuration - Allow both MediVue website and IBDPal app
CORS_ORIGINS=http://localhost:3000,http://localhost:19006,exp://localhost:19000,http://localhost:3004,http://localhost:8081
CORS_CREDENTIALS=true

# Logging Configuration
LOG_LEVEL=debug
LOG_FILE=logs/ibdpal.log

# Security Configuration
ENCRYPTION_KEY=ibdpal_encryption_key_here
BCRYPT_ROUNDS=12

# AI Search Configuration
HUGGING_FACE_TOKEN=${config.HUGGING_FACE_TOKEN}
OPEN_WEBUI_API_KEY=${config.OPEN_WEBUI_API_KEY}
OPENAI_API_KEY=${config.OPENAI_API_KEY}
COHERE_API_KEY=${config.COHERE_API_KEY}

# Health Check
HEALTH_CHECK_ENDPOINT=/api/health

# Security
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Production Configuration (for Azure, AWS, GCP)
# Uncomment and configure for production deployment
# SERVER_PORT=8080
# DB_HOST=your-db-host.azure.com
# DB_PORT=5432
# DB_NAME=medivue_prod
# DB_USER=medivue_user
# DB_PASSWORD=your_secure_production_password
# JWT_SECRET=your_very_secure_jwt_secret_for_production
# API_BASE_URL=https://your-ibdpal-api-domain.com/api
# CORS_ORIGINS=https://your-medivue-website.com,https://your-ibdpal-app.com
`;

  try {
    fs.writeFileSync(configPath, configContent);
    console.log('✅ config.env file created successfully!');
    console.log('\n🔒 Security Notes:');
    console.log('- config.env is in .gitignore and will not be committed to git');
    console.log('- Keep your API tokens secure and never share them');
    console.log('- For production, use environment variables or secure key management');
    console.log('\n🚀 You can now start the IBDPal app!');
  } catch (error) {
    console.error('❌ Error creating config.env:', error.message);
  }
  
  rl.close();
} 