import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  FlatList,
} from 'react-native';
import {
  TextInput,
  Button,
  Text,
  Card,
  Chip,
  Divider,
  IconButton,
  ActivityIndicator,
  List,
} from 'react-native-paper';
import { colors } from '../theme';
import FoodDatabase from '../services/FoodDatabase';

const FoodSearch = ({ onFoodSelect, selectedFoods = [], onFoodsChange }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [showIBDFriendlyOnly, setShowIBDFriendlyOnly] = useState(true);
  const [isSearching, setIsSearching] = useState(false);
  const [searchSuggestions, setSearchSuggestions] = useState([]);
  const [debouncedQuery, setDebouncedQuery] = useState('');

  const categories = [
    { key: 'all', label: 'All Foods' },
    { key: 'breakfast', label: 'Breakfast' },
    { key: 'lunch', label: 'Lunch' },
    { key: 'dinner', label: 'Dinner' },
    { key: 'snacks', label: 'Snacks' },
  ];

  // Debounce search query to avoid excessive searches
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedQuery(searchQuery);
    }, 300); // 300ms delay

    return () => clearTimeout(timer);
  }, [searchQuery]);

  // Generate search suggestions based on current query
  const generateSuggestions = useCallback((query) => {
    if (!query.trim()) return [];
    
    const suggestions = [];
    const searchTerm = query.toLowerCase();
    
    // Get all foods from database
    const allFoods = FoodDatabase.getIBDFriendlyFoods();
    
    // Find foods that match the query
    allFoods.forEach(food => {
      if (food.name.toLowerCase().includes(searchTerm)) {
        suggestions.push({
          type: 'food',
          name: food.name,
          data: food
        });
      }
    });
    
    // Add category suggestions
    categories.forEach(category => {
      if (category.label.toLowerCase().includes(searchTerm)) {
        suggestions.push({
          type: 'category',
          name: `Category: ${category.label}`,
          data: category
        });
      }
    });
    
    return suggestions.slice(0, 5); // Limit to 5 suggestions
  }, [categories]);

  // Update suggestions when query changes
  useEffect(() => {
    if (searchQuery.trim()) {
      const suggestions = generateSuggestions(searchQuery);
      setSearchSuggestions(suggestions);
    } else {
      setSearchSuggestions([]);
    }
  }, [searchQuery, generateSuggestions]);

  // Perform search with debouncing
  useEffect(() => {
    if (debouncedQuery !== searchQuery) return; // Only search when debounced query matches current query
    
    const performSearch = async () => {
      setIsSearching(true);
      
      // Simulate a small delay for better UX
      await new Promise(resolve => setTimeout(resolve, 100));
      
      let results = [];
      
      if (debouncedQuery.trim()) {
        results = FoodDatabase.searchFoods(debouncedQuery);
      } else {
        if (selectedCategory === 'all') {
          results = FoodDatabase.getIBDFriendlyFoods();
        } else {
          results = FoodDatabase.getFoodsByCategory(selectedCategory);
        }
      }

      // Filter by IBD-friendly if option is enabled
      if (showIBDFriendlyOnly) {
        results = results.filter(food => food.ibd_friendly);
      }

      setSearchResults(results);
      setIsSearching(false);
    };

    performSearch();
  }, [debouncedQuery, selectedCategory, showIBDFriendlyOnly]);

  // Memoize search results for better performance
  const memoizedSearchResults = useMemo(() => searchResults, [searchResults]);

  const handleFoodSelect = (food) => {
    if (onFoodSelect) {
      onFoodSelect(food);
    }
    
    if (onFoodsChange) {
      const newSelectedFoods = [...selectedFoods, food];
      onFoodsChange(newSelectedFoods);
    }
  };

  const handleFoodRemove = (foodToRemove) => {
    if (onFoodsChange) {
      const newSelectedFoods = selectedFoods.filter(food => food.key !== foodToRemove.key);
      onFoodsChange(newSelectedFoods);
    }
  };

  const handleSuggestionPress = (suggestion) => {
    if (suggestion.type === 'food') {
      handleFoodSelect(suggestion.data);
    } else if (suggestion.type === 'category') {
      setSelectedCategory(suggestion.data.key);
      setSearchQuery(''); // Clear search when selecting category
    }
  };

  const renderSuggestion = ({ item }) => (
    <List.Item
      title={item.name}
      left={(props) => (
        <List.Icon 
          {...props} 
          icon={item.type === 'food' ? 'food-apple' : 'folder'} 
        />
      )}
      onPress={() => handleSuggestionPress(item)}
      style={styles.suggestionItem}
    />
  );

  const renderFoodItem = ({ item }) => (
    <Card style={styles.foodCard} onPress={() => handleFoodSelect(item)}>
      <Card.Content>
        <View style={styles.foodHeader}>
          <Text style={styles.foodName}>{item.name}</Text>
          <View style={styles.foodTags}>
            {item.ibd_friendly && (
              <Chip 
                mode="outlined" 
                compact 
                style={[styles.tag, styles.ibdFriendly]}
                textStyle={styles.tagText}
              >
                IBD Safe
              </Chip>
            )}
            <Chip 
              mode="outlined" 
              compact 
              style={styles.tag}
              textStyle={styles.tagText}
            >
              {item.fodmap_level}
            </Chip>
          </View>
        </View>
        
        <View style={styles.nutritionInfo}>
          <Text style={styles.nutritionText}>
            {item.calories} cal | P: {item.protein}g | C: {item.carbs}g | F: {item.fiber}g
          </Text>
        </View>
        
        <Text style={styles.benefitsText}>{item.benefits}</Text>
        
        <View style={styles.preparationInfo}>
          <Text style={styles.preparationLabel}>Preparation:</Text>
          <Text style={styles.preparationText}>{item.preparation.join(', ')}</Text>
        </View>
      </Card.Content>
    </Card>
  );

  const renderSelectedFood = ({ item }) => (
    <Card style={styles.selectedFoodCard}>
      <Card.Content>
        <View style={styles.selectedFoodHeader}>
          <Text style={styles.selectedFoodName}>{item.name}</Text>
          <IconButton
            icon="close"
            size={20}
            onPress={() => handleFoodRemove(item)}
            style={styles.removeButton}
          />
        </View>
        <Text style={styles.selectedFoodNutrition}>
          {item.calories} cal | P: {item.protein}g | C: {item.carbs}g | F: {item.fiber}g
        </Text>
      </Card.Content>
    </Card>
  );

  return (
    <View style={styles.container}>
      {/* Search and Filters */}
      <View style={styles.searchSection}>
        <TextInput
          label="Search foods..."
          value={searchQuery}
          onChangeText={setSearchQuery}
          mode="outlined"
          style={styles.searchInput}
          left={<TextInput.Icon icon="magnify" />}
          right={
            isSearching ? (
              <TextInput.Icon icon={() => <ActivityIndicator size={20} color={colors.primary} />} />
            ) : searchQuery ? (
              <TextInput.Icon icon="close" onPress={() => setSearchQuery('')} />
            ) : null
          }
        />
        
        {/* Search Suggestions */}
        {searchSuggestions.length > 0 && searchQuery.trim() && (
          <Card style={styles.suggestionsCard}>
            <Card.Content>
              <Text style={styles.suggestionsTitle}>Quick Suggestions</Text>
              <FlatList
                data={searchSuggestions}
                renderItem={renderSuggestion}
                keyExtractor={(item, index) => `${item.type}-${index}`}
                scrollEnabled={false}
              />
            </Card.Content>
          </Card>
        )}
        
        <View style={styles.filterSection}>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {categories.map(category => (
              <Chip
                key={category.key}
                selected={selectedCategory === category.key}
                onPress={() => setSelectedCategory(category.key)}
                style={styles.categoryChip}
                mode="outlined"
              >
                {category.label}
              </Chip>
            ))}
          </ScrollView>
        </View>
        
        <Button
          mode={showIBDFriendlyOnly ? "contained" : "outlined"}
          onPress={() => setShowIBDFriendlyOnly(!showIBDFriendlyOnly)}
          icon="shield-check"
          style={styles.filterButton}
        >
          IBD Friendly Only
        </Button>
      </View>

      {/* Selected Foods */}
      {selectedFoods.length > 0 && (
        <View style={styles.selectedSection}>
          <Text style={styles.sectionTitle}>Selected Foods</Text>
          <FlatList
            data={selectedFoods}
            renderItem={renderSelectedFood}
            keyExtractor={(item) => item.key}
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.selectedFoodsList}
          />
        </View>
      )}

      {/* Search Results */}
      <View style={styles.resultsSection}>
        <View style={styles.resultsHeader}>
          <Text style={styles.sectionTitle}>
            {isSearching ? 'Searching...' : `${memoizedSearchResults.length} foods found`}
          </Text>
          {isSearching && <ActivityIndicator size={20} color={colors.primary} />}
        </View>
        
        {isSearching ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={colors.primary} />
            <Text style={styles.loadingText}>Searching for foods...</Text>
          </View>
        ) : (
          <FlatList
            data={memoizedSearchResults}
            renderItem={renderFoodItem}
            keyExtractor={(item) => item.key}
            showsVerticalScrollIndicator={false}
            style={styles.resultsList}
            ListEmptyComponent={
              <View style={styles.emptyContainer}>
                <Text style={styles.emptyText}>
                  {searchQuery.trim() 
                    ? `No foods found for "${searchQuery}"` 
                    : 'Start typing to search for foods'
                  }
                </Text>
              </View>
            }
          />
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  searchSection: {
    padding: 16,
    backgroundColor: colors.background,
  },
  searchInput: {
    marginBottom: 16,
  },
  suggestionsCard: {
    marginBottom: 16,
    elevation: 2,
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
  filterSection: {
    marginBottom: 16,
  },
  categoryChip: {
    marginRight: 8,
  },
  filterButton: {
    marginBottom: 8,
  },
  selectedSection: {
    padding: 16,
    backgroundColor: colors.surface,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
    marginBottom: 12,
  },
  selectedFoodsList: {
    marginBottom: 8,
  },
  selectedFoodCard: {
    marginRight: 12,
    minWidth: 200,
  },
  selectedFoodHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  selectedFoodName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
    flex: 1,
  },
  removeButton: {
    margin: 0,
  },
  selectedFoodNutrition: {
    fontSize: 14,
    color: colors.text,
    marginTop: 4,
  },
  resultsSection: {
    flex: 1,
    padding: 16,
  },
  resultsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  resultsList: {
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: colors.text,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 40,
  },
  emptyText: {
    fontSize: 16,
    color: colors.placeholder,
    textAlign: 'center',
  },
  foodCard: {
    marginBottom: 12,
  },
  foodHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  foodName: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
    flex: 1,
  },
  foodTags: {
    flexDirection: 'row',
    gap: 4,
  },
  tag: {
    marginLeft: 4,
  },
  ibdFriendly: {
    backgroundColor: colors.success,
  },
  tagText: {
    fontSize: 10,
  },
  nutritionInfo: {
    marginBottom: 8,
  },
  nutritionText: {
    fontSize: 14,
    color: colors.text,
    fontWeight: '500',
  },
  benefitsText: {
    fontSize: 14,
    color: colors.text,
    fontStyle: 'italic',
    marginBottom: 8,
  },
  preparationInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  preparationLabel: {
    fontSize: 12,
    color: colors.placeholder,
    marginRight: 4,
  },
  preparationText: {
    fontSize: 12,
    color: colors.text,
  },
});

export default FoodSearch; 