import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  Linking,
  FlatList,
} from 'react-native';
import {
  TextInput,
  Button,
  Text,
  Surface,
  Title,
  Paragraph,
  Card,
  List,
  ActivityIndicator,
  Chip,
} from 'react-native-paper';
import { colors } from '../theme';
import CustomModal from '../components/CustomModal';
import { AI_SEARCH_CONFIG, getFreeApiTokens } from '../config/ai-search-config';

const SearchScreen = ({ navigation, route }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [recentSearches, setRecentSearches] = useState([]);
  const [debouncedQuery, setDebouncedQuery] = useState('');
  const [searchSuggestions, setSearchSuggestions] = useState([]);
  const [instantResults, setInstantResults] = useState([]);
  const [aiResults, setAiResults] = useState([]);
  const [isAiSearching, setIsAiSearching] = useState(false);

  const { userData } = route.params;

  // AI-powered search using free LLM APIs
  const performAiSearch = useCallback(async (query) => {
    if (!query.trim()) return;

    setIsAiSearching(true);
    console.log('Performing AI search for:', query);

    try {
      // Get API tokens from configuration
      const tokens = getFreeApiTokens();
      
      // Use Hugging Face Inference API as primary (for local development)
      console.log('Using Hugging Face API for local development...');
      const aiResponse = await fetch(`${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.baseUrl}/models/${AI_SEARCH_CONFIG.FREE_LLM_APIS.HUGGING_FACE.models.textGeneration}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${tokens.HUGGING_FACE_TOKEN}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          inputs: `Search query: ${query} related to inflammatory bowel disease (IBD). Provide relevant information about symptoms, treatments, diet, and lifestyle.`,
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
        console.log('Hugging Face AI response:', aiData);
        
        // Process AI response and create search results
        const aiGeneratedResults = Array.isArray(aiData) ? aiData.map((result, index) => ({
          id: `ai-${index}`,
          title: `AI Generated Response ${index + 1}`,
          description: result.generated_text || result.summary_text || 'AI-generated information about your query.',
          url: '#',
          source: 'AI Assistant',
          type: 'ai',
          relevance: 95 - (index * 5),
          isAiGenerated: true,
        })) : [{
          id: 'ai-0',
          title: 'AI Generated Response',
          description: aiData.generated_text || aiData.summary_text || 'AI-generated information about your query.',
          url: '#',
          source: 'AI Assistant',
          type: 'ai',
          relevance: 95,
          isAiGenerated: true,
        }];

        setAiResults(aiGeneratedResults);
      } else {
        console.log('Hugging Face API failed, using local AI');
        // Fallback to local AI processing
        const localAiResults = await performLocalAiSearch(query);
        setAiResults(localAiResults);
      }
    } catch (error) {
      console.error('AI search error:', error);
      // Fallback to local AI processing
      const localAiResults = await performLocalAiSearch(query);
      setAiResults(localAiResults);
    } finally {
      setIsAiSearching(false);
    }
  }, []);

  // Local AI processing using simple NLP techniques
  const performLocalAiSearch = useCallback(async (query) => {
    console.log('Performing local AI search for:', query);
    
    const searchTerm = query.toLowerCase();
    const aiKeywords = {
      'symptom': ['pain', 'diarrhea', 'blood', 'fatigue', 'weight loss', 'fever'],
      'treatment': ['medication', 'biologics', 'surgery', 'therapy', 'remission'],
      'diet': ['food', 'nutrition', 'fiber', 'protein', 'vitamins', 'supplements'],
      'lifestyle': ['exercise', 'stress', 'sleep', 'work', 'social', 'mental health'],
      'flare': ['flare-up', 'attack', 'worsening', 'acute', 'severe'],
      'remission': ['better', 'improved', 'stable', 'controlled', 'manageable']
    };

    // Analyze query intent
    let intent = 'general';
    let confidence = 0;
    
    Object.entries(aiKeywords).forEach(([category, keywords]) => {
      const matches = keywords.filter(keyword => searchTerm.includes(keyword)).length;
      if (matches > confidence) {
        intent = category;
        confidence = matches;
      }
    });

    // Generate AI-like responses based on intent
    const aiResponses = {
      symptom: [
        {
          title: 'IBD Symptoms Analysis',
          description: `Based on your query about "${query}", common IBD symptoms include abdominal pain, diarrhea, rectal bleeding, fatigue, and unintended weight loss. It's important to track your symptoms and discuss them with your healthcare provider.`,
          category: 'symptoms'
        },
        {
          title: 'Symptom Management Tips',
          description: `For managing "${query}"-related symptoms: keep a symptom diary, identify triggers, maintain regular check-ups, and follow your treatment plan. Consider stress management techniques as stress can worsen symptoms.`,
          category: 'management'
        }
      ],
      treatment: [
        {
          title: 'Treatment Options for IBD',
          description: `Regarding "${query}" treatments: IBD treatment typically includes medications (aminosalicylates, corticosteroids, immunomodulators, biologics), lifestyle changes, and sometimes surgery. Your treatment plan should be personalized.`,
          category: 'treatment'
        },
        {
          title: 'Treatment Effectiveness',
          description: `Treatment effectiveness for "${query}" varies by individual. Regular monitoring, medication adherence, and open communication with your healthcare team are crucial for optimal outcomes.`,
          category: 'monitoring'
        }
      ],
      diet: [
        {
          title: 'IBD Diet Recommendations',
          description: `For "${query}" and IBD: focus on easily digestible foods, avoid trigger foods, maintain adequate nutrition, and consider working with a registered dietitian. Keep a food diary to identify personal triggers.`,
          category: 'nutrition'
        },
        {
          title: 'Nutritional Support',
          description: `Nutritional support for "${query}" includes ensuring adequate protein, vitamins, and minerals. Consider supplements if needed, and stay hydrated. Small, frequent meals may be better tolerated.`,
          category: 'nutrition'
        }
      ],
      lifestyle: [
        {
          title: 'Lifestyle Management for IBD',
          description: `Lifestyle factors for "${query}" include stress management, regular exercise (as tolerated), adequate sleep, and maintaining social connections. These can significantly impact your IBD management.`,
          category: 'lifestyle'
        },
        {
          title: 'Mental Health and IBD',
          description: `Mental health is crucial for "${query}" management. Consider counseling, support groups, mindfulness practices, and open communication with loved ones about your condition.`,
          category: 'mental-health'
        }
      ],
      flare: [
        {
          title: 'Flare Management Strategies',
          description: `For managing "${query}" flares: rest more, follow a bland diet, stay hydrated, avoid stress, and contact your healthcare provider if symptoms worsen. Have an action plan ready.`,
          category: 'flare-management'
        },
        {
          title: 'Flare Prevention',
          description: `To prevent "${query}" flares: identify and avoid triggers, maintain medication adherence, manage stress, get adequate sleep, and follow your treatment plan consistently.`,
          category: 'prevention'
        }
      ],
      remission: [
        {
          title: 'Maintaining Remission',
          description: `To maintain remission with "${query}": continue medications as prescribed, attend regular check-ups, maintain a healthy lifestyle, and be aware of early warning signs of flares.`,
          category: 'remission'
        },
        {
          title: 'Remission Monitoring',
          description: `Regular monitoring during remission for "${query}" includes tracking symptoms, maintaining medication adherence, and reporting any changes to your healthcare team promptly.`,
          category: 'monitoring'
        }
      ],
      general: [
        {
          title: 'IBD Information and Support',
          description: `Regarding "${query}" and IBD: this is a chronic condition that requires ongoing management. Work closely with your healthcare team, educate yourself, and connect with support communities.`,
          category: 'general'
        },
        {
          title: 'Living Well with IBD',
          description: `Living well with IBD involves understanding your condition, following your treatment plan, maintaining a healthy lifestyle, and seeking support when needed. You're not alone in this journey.`,
          category: 'support'
        }
      ]
    };

    const responses = aiResponses[intent] || aiResponses.general;
    
    return responses.map((response, index) => ({
      id: `local-ai-${index}`,
      title: response.title,
      description: response.description,
      url: '#',
      source: 'AI Assistant',
      type: 'ai',
      relevance: 95 - (index * 5),
      isAiGenerated: true,
      category: response.category
    }));
  }, []);

  // Real-time search database
  const searchDatabase = useMemo(() => [
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
  ], []);

  // Test search database on mount
  useEffect(() => {
    console.log('Search database loaded with', searchDatabase.length, 'items');
    console.log('Sample items:', searchDatabase.slice(0, 2).map(item => item.title));
    
    // Test instant search
    performInstantSearch('diet');
  }, [searchDatabase, performInstantSearch]);

  // Real-time search function
  const performInstantSearch = useCallback((query) => {
    console.log('Performing instant search for:', query);
    
    if (!query.trim()) {
      console.log('Empty query, clearing instant results');
      setInstantResults([]);
      return;
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
    
    console.log('Setting instant results:', topResults.length);
    setInstantResults(topResults);
  }, [searchDatabase]);

  // Debounce search query for web search (faster response)
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(searchQuery);
    }, 200); // Reduced from 500ms to 200ms for faster response

    return () => clearTimeout(timer);
  }, [searchQuery]);

  // Perform instant search on every keystroke
  useEffect(() => {
    console.log('Search query changed:', searchQuery);
    performInstantSearch(searchQuery);
  }, [searchQuery, performInstantSearch]);

  // Perform AI search when query changes
  useEffect(() => {
    if (searchQuery.trim() && searchQuery.length > 3) {
      const timer = setTimeout(() => {
        performAiSearch(searchQuery);
      }, 500); // AI search with slight delay

      return () => clearTimeout(timer);
    } else {
      setAiResults([]);
    }
  }, [searchQuery, performAiSearch]);

  // Generate search suggestions
  const generateSuggestions = useCallback((query) => {
    if (!query.trim()) return [];
    
    const suggestions = [
      { type: 'search', name: `${query} IBD symptoms`, icon: 'magnify' },
      { type: 'search', name: `${query} IBD treatment`, icon: 'medical-bag' },
      { type: 'search', name: `${query} IBD diet`, icon: 'food-apple' },
      { type: 'search', name: `${query} IBD flare management`, icon: 'heart' },
      { type: 'search', name: `${query} Crohn's disease`, icon: 'medical-bag' },
      { type: 'search', name: `${query} ulcerative colitis`, icon: 'medical-bag' },
    ];
    
    return suggestions;
  }, []);

  // Update suggestions when query changes
  useEffect(() => {
    if (searchQuery.trim()) {
      const suggestions = generateSuggestions(searchQuery);
      setSearchSuggestions(suggestions);
    } else {
      setSearchSuggestions([]);
    }
  }, [searchQuery, generateSuggestions]);

  // Perform web search with debouncing
  useEffect(() => {
    if (!debouncedQuery.trim() || debouncedQuery !== searchQuery) return;

    const performWebSearch = async () => {
      setIsSearching(true);
      
      try {
        // Store recent search
        const newSearch = {
          query: debouncedQuery.trim(),
          timestamp: new Date().toISOString(),
        };
        setRecentSearches(prev => [newSearch, ...prev.slice(0, 4)]); // Keep last 5 searches
        
        // Simulate web search with enhanced results
        setTimeout(() => {
          // Filter and enhance results based on query
          const enhancedResults = searchDatabase.filter(result => 
            result.title.toLowerCase().includes(debouncedQuery.toLowerCase()) ||
            result.description.toLowerCase().includes(debouncedQuery.toLowerCase()) ||
            result.tags.some(tag => tag.toLowerCase().includes(debouncedQuery.toLowerCase()))
          );
          
          // Add some web-specific results
          const webResults = [
            ...enhancedResults,
            {
              id: 100,
              title: `${debouncedQuery} - Latest IBD Research`,
              description: `Latest research and studies about ${debouncedQuery} in inflammatory bowel disease.`,
              url: `https://www.research.ibd.org/${debouncedQuery.replace(/\s+/g, '-')}`,
              source: 'IBD Research Network',
              type: 'research',
              relevance: 85,
            },
            {
              id: 101,
              title: `${debouncedQuery} - Patient Community Discussion`,
              description: `Join the discussion about ${debouncedQuery} in our patient community.`,
              url: `https://www.ibdcommunity.org/discussions/${debouncedQuery.replace(/\s+/g, '-')}`,
              source: 'IBD Community',
              type: 'community',
              relevance: 80,
            }
          ];
          
          console.log('Setting web search results:', webResults);
          setSearchResults(webResults);
          setIsSearching(false);
        }, 300); // Reduced delay for faster response
        
      } catch (error) {
        console.error('Search error:', error);
        setErrorMessage('Failed to perform search. Please check your internet connection and try again.');
        setShowErrorModal(true);
        setIsSearching(false);
      }
    };

    performWebSearch();
  }, [debouncedQuery, searchDatabase]);

  const popularSearches = [
    'IBD diet',
    'flare management',
    'medications',
    'symptoms',
    'treatment options',
    'lifestyle tips',
    'Crohn\'s disease',
    'ulcerative colitis',
    'biologics',
    'surgery options',
  ];

  const handleResultPress = (result) => {
    // Open the URL in the device's default browser
    if (result.url && result.url !== '#') {
      Linking.openURL(result.url).catch(err => {
        console.error('Error opening URL:', err);
        setErrorMessage('Unable to open the link. Please try again.');
        setShowErrorModal(true);
      });
    } else {
      // Handle AI-generated results
      console.log('AI result selected:', result.title);
    }
  };

  const handleRecentSearchPress = (search) => {
    setSearchQuery(search.query);
  };

  const handleSuggestionPress = (suggestion) => {
    setSearchQuery(suggestion.name);
  };

  const handlePopularSearchPress = (search) => {
    setSearchQuery(search);
  };

  const renderSearchSuggestion = ({ item }) => (
    <List.Item
      title={item.name}
      left={(props) => <List.Icon {...props} icon={item.icon} />}
      onPress={() => handleSuggestionPress(item)}
      style={styles.suggestionItem}
    />
  );

  const renderSearchResult = ({ item }) => (
    <Card style={styles.resultCard} onPress={() => handleResultPress(item)}>
      <Card.Content>
        <View style={styles.resultHeader}>
          <Text style={styles.resultTitle}>{item.title}</Text>
          <Chip 
            mode="outlined" 
            compact 
            style={[styles.sourceChip, item.isAiGenerated && styles.aiChip]}
            textStyle={styles.sourceChipText}
          >
            {item.source}
          </Chip>
        </View>
        <Text style={styles.resultDescription}>{item.description}</Text>
        {item.url !== '#' && <Text style={styles.resultUrl}>{item.url}</Text>}
      </Card.Content>
    </Card>
  );

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContainer}>
        <Surface style={styles.surface}>
          <View style={styles.header}>
            <Title style={styles.title}>AI-Powered Search</Title>
            <Paragraph style={styles.subtitle}>
              Find intelligent information about IBD, treatments, and lifestyle tips
            </Paragraph>
          </View>

          <View style={styles.content}>
            {/* Search Bar */}
            <Card style={styles.card}>
              <Card.Content>
                <TextInput
                  label="Ask AI about IBD information..."
                  value={searchQuery}
                  onChangeText={setSearchQuery}
                  mode="outlined"
                  style={styles.searchInput}
                  right={
                    isSearching || isAiSearching ? (
                      <TextInput.Icon icon={() => <ActivityIndicator size={20} color={colors.primary} />} />
                    ) : searchQuery ? (
                      <TextInput.Icon icon="close" onPress={() => setSearchQuery('')} />
                    ) : (
                      <TextInput.Icon icon="robot" />
                    )
                  }
                  onSubmitEditing={() => {
                    if (searchQuery.trim()) {
                      setDebouncedQuery(searchQuery);
                    }
                  }}
                />
                
                {/* AI Results */}
                {aiResults.length > 0 && searchQuery.trim() && (
                  <Card style={styles.aiResultsCard}>
                    <Card.Content>
                      <View style={styles.aiResultsHeader}>
                        <Text style={styles.aiResultsTitle}>
                          AI Insights ({aiResults.length})
                        </Text>
                        <ActivityIndicator size={16} color={colors.primary} />
                      </View>
                      {aiResults.map((result, index) => (
                        <List.Item
                          key={result.id}
                          title={result.title}
                          description={result.description.substring(0, 120) + '...'}
                          left={(props) => <List.Icon {...props} icon="robot" />}
                          onPress={() => handleResultPress(result)}
                          style={styles.aiResultItem}
                        />
                      ))}
                    </Card.Content>
                  </Card>
                )}
                
                {/* Instant Results */}
                {searchQuery.trim() && (
                  <Card style={styles.instantResultsCard}>
                    <Card.Content>
                      <View style={styles.instantResultsHeader}>
                        <Text style={styles.instantResultsTitle}>
                          Instant Results ({instantResults.length})
                        </Text>
                        <ActivityIndicator size={16} color={colors.primary} />
                      </View>
                      {instantResults.length > 0 ? (
                        instantResults.map((result, index) => (
                          <List.Item
                            key={result.id}
                            title={result.title}
                            description={result.description.substring(0, 80) + '...'}
                            left={(props) => <List.Icon {...props} icon="lightning-bolt" />}
                            onPress={() => handleResultPress(result)}
                            style={styles.instantResultItem}
                          />
                        ))
                      ) : (
                        <Text style={styles.noInstantResults}>
                          No instant results found for "{searchQuery}"
                        </Text>
                      )}
                    </Card.Content>
                  </Card>
                )}
                
                {/* Debug Info - Remove this in production */}
                {searchQuery.trim() && (
                  <Card style={styles.debugCard}>
                    <Card.Content>
                      <Text style={styles.debugText}>
                        Debug: Query="{searchQuery}" | Instant: {instantResults.length} | AI: {aiResults.length} | Web: {searchResults.length}
                      </Text>
                    </Card.Content>
                  </Card>
                )}
                
                {/* Search Suggestions */}
                {searchSuggestions.length > 0 && searchQuery.trim() && instantResults.length === 0 && (
                  <Card style={styles.suggestionsCard}>
                    <Card.Content>
                      <Text style={styles.suggestionsTitle}>Quick Suggestions</Text>
                      {searchSuggestions.map((suggestion, index) => (
                        <List.Item
                          key={index}
                          title={suggestion.name}
                          left={(props) => <List.Icon {...props} icon={suggestion.icon} />}
                          onPress={() => handleSuggestionPress(suggestion)}
                          style={styles.suggestionItem}
                        />
                      ))}
                    </Card.Content>
                  </Card>
                )}
              </Card.Content>
            </Card>

            {/* Recent Searches */}
            {recentSearches.length > 0 && !searchQuery.trim() && (
              <Card style={styles.card}>
                <Card.Content>
                  <Title style={styles.cardTitle}>Recent Searches</Title>
                  {recentSearches.map((search, index) => (
                    <List.Item
                      key={index}
                      title={search.query}
                      left={(props) => <List.Icon {...props} icon="history" />}
                      onPress={() => handleRecentSearchPress(search)}
                      style={styles.recentSearchItem}
                    />
                  ))}
                </Card.Content>
              </Card>
            )}

            {/* Web Search Results */}
            {searchResults.length > 0 && (
              <Card style={styles.card}>
                <Card.Content>
                  <View style={styles.resultsHeader}>
                    <Title style={styles.cardTitle}>
                      {isSearching ? 'Searching...' : `${searchResults.length} web results found`}
                    </Title>
                    {isSearching && <ActivityIndicator size={20} color={colors.primary} />}
                  </View>
                  
                  {isSearching ? (
                    <View style={styles.loadingContainer}>
                      <ActivityIndicator size="large" color={colors.primary} />
                      <Text style={styles.loadingText}>Searching the web for information...</Text>
                    </View>
                  ) : (
                    <FlatList
                      data={searchResults}
                      renderItem={renderSearchResult}
                      keyExtractor={(item) => item.id.toString()}
                      scrollEnabled={false}
                      ListEmptyComponent={
                        <View style={styles.emptyContainer}>
                          <Text style={styles.emptyText}>
                            {searchQuery.trim() 
                              ? `No web results found for "${searchQuery}"` 
                              : 'Start typing to search for information'
                            }
                          </Text>
                        </View>
                      }
                    />
                  )}
                </Card.Content>
              </Card>
            )}

            {/* Popular Searches */}
            {!searchQuery.trim() && (
              <Card style={styles.card}>
                <Card.Content>
                  <Title style={styles.cardTitle}>Popular Searches</Title>
                  <View style={styles.popularSearchesContainer}>
                    {popularSearches.map((search, index) => (
                      <Chip
                        key={index}
                        mode="outlined"
                        onPress={() => handlePopularSearchPress(search)}
                        style={styles.popularSearchChip}
                        textStyle={styles.popularSearchChipText}
                      >
                        {search}
                      </Chip>
                    ))}
                  </View>
                </Card.Content>
              </Card>
            )}

            {/* Quick Access */}
            {!searchQuery.trim() && (
              <Card style={styles.card}>
                <Card.Content>
                  <Title style={styles.cardTitle}>Quick Access</Title>
                  <List.Item
                    title="IBD Education"
                    description="Learn about different types of IBD"
                    left={(props) => <List.Icon {...props} icon="school" />}
                    right={(props) => <List.Icon {...props} icon="chevron-right" />}
                    style={styles.quickAccessItem}
                  />
                  <List.Item
                    title="Treatment Options"
                    description="Explore various treatment approaches"
                    left={(props) => <List.Icon {...props} icon="medical-bag" />}
                    right={(props) => <List.Icon {...props} icon="chevron-right" />}
                    style={styles.quickAccessItem}
                  />
                  <List.Item
                    title="Lifestyle Tips"
                    description="Daily living with IBD"
                    left={(props) => <List.Icon {...props} icon="heart" />}
                    right={(props) => <List.Icon {...props} icon="chevron-right" />}
                    style={styles.quickAccessItem}
                  />
                </Card.Content>
              </Card>
            )}
          </View>
        </Surface>
      </ScrollView>

      {/* Error Modal */}
      <CustomModal
        visible={showErrorModal}
        onClose={() => setShowErrorModal(false)}
        title="Search Error"
        message={errorMessage}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContainer: {
    flexGrow: 1,
  },
  surface: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    padding: 16,
    backgroundColor: colors.primary,
  },
  title: {
    color: 'white',
    fontSize: 24,
    fontWeight: 'bold',
  },
  subtitle: {
    color: 'white',
    fontSize: 16,
    opacity: 0.9,
  },
  content: {
    padding: 16,
  },
  card: {
    marginBottom: 16,
    elevation: 2,
  },
  searchInput: {
    marginBottom: 8,
  },
  aiResultsCard: {
    marginTop: 8,
    elevation: 1,
    backgroundColor: colors.surface,
    borderLeftWidth: 4,
    borderLeftColor: colors.primary,
  },
  aiResultsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  aiResultsTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: colors.primary,
  },
  aiResultItem: {
    paddingVertical: 4,
  },
  instantResultsCard: {
    marginTop: 8,
    elevation: 1,
    backgroundColor: colors.surface,
  },
  instantResultsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  instantResultsTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: colors.primary,
  },
  instantResultItem: {
    paddingVertical: 4,
  },
  suggestionsCard: {
    marginTop: 8,
    elevation: 1,
  },
  suggestionsTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 8,
  },
  suggestionItem: {
    paddingVertical: 4,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 12,
  },
  recentSearchItem: {
    paddingVertical: 4,
  },
  resultsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  loadingContainer: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: colors.text,
  },
  emptyContainer: {
    paddingVertical: 40,
    alignItems: 'center',
  },
  emptyText: {
    fontSize: 16,
    color: colors.placeholder,
    textAlign: 'center',
  },
  resultCard: {
    marginBottom: 12,
  },
  resultHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  resultTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
    flex: 1,
  },
  sourceChip: {
    marginLeft: 8,
  },
  aiChip: {
    backgroundColor: colors.primary,
  },
  sourceChipText: {
    fontSize: 10,
  },
  resultDescription: {
    fontSize: 14,
    color: colors.text,
    marginBottom: 8,
    lineHeight: 20,
  },
  resultUrl: {
    fontSize: 12,
    color: colors.primary,
    fontStyle: 'italic',
  },
  popularSearchesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  popularSearchChip: {
    marginBottom: 8,
  },
  popularSearchChipText: {
    fontSize: 12,
  },
  quickAccessItem: {
    paddingVertical: 4,
  },
  debugCard: {
    marginTop: 8,
    elevation: 1,
    backgroundColor: colors.surface,
  },
  debugText: {
    fontSize: 12,
    color: colors.text,
    textAlign: 'center',
  },
  noInstantResults: {
    fontSize: 14,
    color: colors.placeholder,
    textAlign: 'center',
    paddingVertical: 10,
  },
});

export default SearchScreen; 

