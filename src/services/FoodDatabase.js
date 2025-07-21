// Comprehensive International Food Database for IBDPal
// Based on the Medivue web app food database with enhanced nutrition data

const FOOD_DATABASE = {
  // Breakfast Foods
  'breakfast': {
    'oatmeal': {
      name: 'Oatmeal',
      category: 'grain',
      calories: 150,
      protein: 6,
      carbs: 27,
      fiber: 4,
      fat: 3,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['boiled', 'microwaved'],
      benefits: 'High fiber, good for digestion, steady energy',
      tags: ['fiber', 'digestion', 'energy', 'breakfast']
    },
    'greek_yogurt': {
      name: 'Greek Yogurt',
      category: 'dairy',
      calories: 130,
      protein: 20,
      carbs: 9,
      fiber: 0,
      fat: 0.5,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'mediterranean',
      preparation: ['plain', 'with_fruit'],
      benefits: 'High protein, probiotics, good for gut health',
      tags: ['protein', 'probiotics', 'gut_health', 'dairy']
    },
    'eggs': {
      name: 'Eggs',
      category: 'protein',
      calories: 70,
      protein: 6,
      carbs: 0,
      fiber: 0,
      fat: 5,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['scrambled', 'boiled', 'poached', 'fried'],
      benefits: 'High protein, easy to digest, nutrient-dense',
      tags: ['protein', 'easy_digest', 'nutrient_dense', 'breakfast']
    },
    'banana': {
      name: 'Banana',
      category: 'fruit',
      calories: 105,
      carbs: 27,
      protein: 1.3,
      fiber: 3.1,
      fat: 0.4,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['raw'],
      benefits: 'Easy to digest, potassium, natural sugars',
      tags: ['fruit', 'potassium', 'easy_digest', 'breakfast']
    }
  },

  // Lunch Foods
  'lunch': {
    'chicken_salad': {
      name: 'Chicken Salad',
      category: 'protein',
      calories: 300,
      protein: 25,
      carbs: 15,
      fiber: 3,
      fat: 12,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['grilled', 'mixed'],
      benefits: 'High protein, good for muscle maintenance',
      tags: ['protein', 'muscle', 'lunch', 'salad']
    },
    'quinoa_bowl': {
      name: 'Quinoa Bowl',
      category: 'grain',
      calories: 250,
      protein: 8,
      carbs: 45,
      fiber: 5,
      fat: 4,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['boiled', 'mixed'],
      benefits: 'Complete protein, high fiber, gluten-free',
      tags: ['complete_protein', 'fiber', 'gluten_free', 'lunch']
    },
    'salmon': {
      name: 'Salmon',
      category: 'protein',
      calories: 208,
      protein: 22,
      carbs: 0,
      fiber: 0,
      fat: 12,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['baked', 'grilled', 'poached'],
      benefits: 'Omega-3 fatty acids, anti-inflammatory, high protein',
      tags: ['omega3', 'anti_inflammatory', 'protein', 'lunch']
    }
  },

  // Dinner Foods
  'dinner': {
    'chicken_breast': {
      name: 'Chicken Breast',
      category: 'protein',
      calories: 165,
      protein: 31,
      carbs: 0,
      fiber: 0,
      fat: 3.6,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['grilled', 'baked', 'poached'],
      benefits: 'Lean protein, easy to digest, versatile',
      tags: ['lean_protein', 'easy_digest', 'versatile', 'dinner']
    },
    'sweet_potato': {
      name: 'Sweet Potato',
      category: 'vegetable',
      calories: 103,
      protein: 2,
      carbs: 24,
      fiber: 4,
      fat: 0.2,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['baked', 'roasted', 'mashed'],
      benefits: 'High in vitamin A, fiber, anti-inflammatory',
      tags: ['vitamin_a', 'fiber', 'anti_inflammatory', 'dinner']
    },
    'brown_rice': {
      name: 'Brown Rice',
      category: 'grain',
      calories: 216,
      protein: 5,
      carbs: 45,
      fiber: 4,
      fat: 2,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['boiled', 'steamed'],
      benefits: 'Whole grain, high fiber, sustained energy',
      tags: ['whole_grain', 'fiber', 'sustained_energy', 'dinner']
    }
  },

  // Snacks
  'snacks': {
    'apple': {
      name: 'Apple',
      category: 'fruit',
      calories: 95,
      carbs: 25,
      protein: 0.5,
      fiber: 4.4,
      fat: 0.3,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['raw', 'cooked'],
      benefits: 'High fiber, antioxidants, natural sugars',
      tags: ['fiber', 'antioxidants', 'natural_sugars', 'snacks']
    },
    'almonds': {
      name: 'Almonds',
      category: 'nuts',
      calories: 164,
      protein: 6,
      carbs: 6,
      fiber: 3.5,
      fat: 14,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['raw', 'roasted'],
      benefits: 'Healthy fats, protein, vitamin E',
      tags: ['healthy_fats', 'protein', 'vitamin_e', 'snacks']
    },
    'carrot_sticks': {
      name: 'Carrot Sticks',
      category: 'vegetable',
      calories: 25,
      protein: 0.6,
      carbs: 6,
      fiber: 2,
      fat: 0.1,
      ibd_friendly: true,
      fodmap_level: 'low',
      cuisine: 'international',
      preparation: ['raw', 'cooked'],
      benefits: 'Vitamin A, fiber, low calorie',
      tags: ['vitamin_a', 'fiber', 'low_calorie', 'snacks']
    }
  }
};

// Enhanced search and filtering functions
class FoodDatabaseService {
  constructor() {
    this.database = FOOD_DATABASE;
    this.searchIndex = this.buildSearchIndex();
  }

  // Build a search index for faster lookups
  buildSearchIndex() {
    const index = {};
    
    Object.keys(this.database).forEach(category => {
      Object.keys(this.database[category]).forEach(foodKey => {
        const food = this.database[category][foodKey];
        const searchableText = [
          food.name.toLowerCase(),
          foodKey.toLowerCase(),
          ...(food.tags || []).map(tag => tag.toLowerCase()),
          food.benefits.toLowerCase(),
          food.preparation.join(' ').toLowerCase()
        ].join(' ');
        
        index[foodKey] = {
          searchableText,
          category,
          food
        };
      });
    });
    
    return index;
  }

  // Enhanced search with fuzzy matching and multiple criteria
  searchFoods(query) {
    if (!query.trim()) return [];
    
    const results = [];
    const searchTerms = query.toLowerCase().split(/\s+/);
    
    Object.keys(this.searchIndex).forEach(foodKey => {
      const { searchableText, category, food } = this.searchIndex[foodKey];
      let score = 0;
      let matchesAllTerms = true;
      
      // Check if all search terms are found
      for (const term of searchTerms) {
        if (term.length < 2) continue; // Skip very short terms
        
        if (searchableText.includes(term)) {
          // Boost score for exact matches
          if (food.name.toLowerCase().includes(term)) {
            score += 10;
          } else if (foodKey.toLowerCase().includes(term)) {
            score += 8;
          } else if (food.tags && food.tags.some(tag => tag.toLowerCase().includes(term))) {
            score += 6;
          } else {
            score += 2;
          }
        } else {
          matchesAllTerms = false;
          break;
        }
      }
      
      if (matchesAllTerms && score > 0) {
        results.push({
          ...food,
          key: foodKey,
          category: category,
          searchScore: score
        });
      }
    });
    
    // Sort by relevance score
    return results.sort((a, b) => b.searchScore - a.searchScore);
  }

  // Search foods by specific criteria
  searchFoodsByCriteria(criteria) {
    const results = [];
    
    Object.keys(this.database).forEach(category => {
      Object.keys(this.database[category]).forEach(foodKey => {
        const food = this.database[category][foodKey];
        let matches = true;
        
        // Check each criterion
        if (criteria.category && food.category !== criteria.category) {
          matches = false;
        }
        
        if (criteria.ibd_friendly !== undefined && food.ibd_friendly !== criteria.ibd_friendly) {
          matches = false;
        }
        
        if (criteria.fodmap_level && food.fodmap_level !== criteria.fodmap_level) {
          matches = false;
        }
        
        if (criteria.maxCalories && food.calories > criteria.maxCalories) {
          matches = false;
        }
        
        if (criteria.minProtein && food.protein < criteria.minProtein) {
          matches = false;
        }
        
        if (matches) {
          results.push({
            ...food,
            key: foodKey,
            category: category
          });
        }
      });
    });
    
    return results;
  }

  // Get foods by category
  getFoodsByCategory(category) {
    if (this.database[category]) {
      return Object.keys(this.database[category]).map(key => ({
        ...this.database[category][key],
        key: key,
        category: category
      }));
    }
    return [];
  }

  // Get IBD-friendly foods only
  getIBDFriendlyFoods() {
    const results = [];
    Object.keys(this.database).forEach(category => {
      Object.keys(this.database[category]).forEach(foodKey => {
        const food = this.database[category][foodKey];
        if (food.ibd_friendly) {
          results.push({
            ...food,
            key: foodKey,
            category: category
          });
        }
      });
    });
    return results;
  }

  // Get popular foods (most commonly used)
  getPopularFoods(limit = 10) {
    const allFoods = this.getIBDFriendlyFoods();
    // For now, return first N foods, but this could be enhanced with usage tracking
    return allFoods.slice(0, limit);
  }

  // Get foods by preparation method
  getFoodsByPreparation(preparation) {
    const results = [];
    Object.keys(this.database).forEach(category => {
      Object.keys(this.database[category]).forEach(foodKey => {
        const food = this.database[category][foodKey];
        if (food.preparation.includes(preparation)) {
          results.push({
            ...food,
            key: foodKey,
            category: category
          });
        }
      });
    });
    return results;
  }

  // Calculate nutrition totals for a list of foods
  calculateNutritionTotals(foods) {
    return foods.reduce((totals, food) => {
      return {
        calories: totals.calories + (food.calories || 0),
        protein: totals.protein + (food.protein || 0),
        carbs: totals.carbs + (food.carbs || 0),
        fiber: totals.fiber + (food.fiber || 0),
        fat: totals.fat + (food.fat || 0)
      };
    }, { calories: 0, protein: 0, carbs: 0, fiber: 0, fat: 0 });
  }

  // Get nutrition recommendations based on IBD status
  getNutritionRecommendations(ibdStatus = 'remission') {
    const recommendations = {
      remission: {
        focus: 'Maintain balanced nutrition',
        foods: this.getIBDFriendlyFoods(),
        tips: [
          'Include a variety of fruits and vegetables',
          'Choose lean proteins',
          'Include healthy fats',
          'Stay hydrated'
        ]
      },
      flare: {
        focus: 'Easy-to-digest foods',
        foods: this.getIBDFriendlyFoods(),
        tips: [
          'Choose bland, cooked foods',
          'Avoid raw vegetables',
          'Include easily digestible proteins',
          'Stay well hydrated'
        ]
      }
    };

    return recommendations[ibdStatus] || recommendations.remission;
  }

  // Get search suggestions based on partial query
  getSearchSuggestions(query, limit = 5) {
    if (!query.trim()) return [];
    
    const suggestions = [];
    const searchTerm = query.toLowerCase();
    
    // Get all foods
    const allFoods = this.getIBDFriendlyFoods();
    
    // Find matching foods
    allFoods.forEach(food => {
      if (food.name.toLowerCase().includes(searchTerm)) {
        suggestions.push({
          type: 'food',
          name: food.name,
          data: food
        });
      }
    });
    
    // Add tag suggestions
    const allTags = new Set();
    allFoods.forEach(food => {
      if (food.tags) {
        food.tags.forEach(tag => {
          if (tag.toLowerCase().includes(searchTerm)) {
            allTags.add(tag);
          }
        });
      }
    });
    
    allTags.forEach(tag => {
      suggestions.push({
        type: 'tag',
        name: `Tag: ${tag}`,
        data: { tag }
      });
    });
    
    return suggestions.slice(0, limit);
  }
}

// Export the service
export default new FoodDatabaseService(); 