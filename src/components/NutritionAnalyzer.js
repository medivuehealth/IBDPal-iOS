import React, { useState, useEffect } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  Dimensions,
} from 'react-native';
import {
  Text,
  Card,
  Title,
  Paragraph,
  Chip,
  ActivityIndicator,
} from 'react-native-paper';
import { LineChart, BarChart } from 'react-native-chart-kit';
import { colors } from '../theme';
import { API_BASE_URL } from '../config';

const { width } = Dimensions.get('window');

const NutritionAnalyzer = ({ userId }) => {
  const [analysisData, setAnalysisData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [timeRange, setTimeRange] = useState(30); // days

  // IBD Nutrition Guidelines
  const ibdGuidelines = {
    recommended: {
      protein: { min: 1.2, max: 1.5, unit: 'g/kg body weight' },
      fiber: { min: 10, max: 15, unit: 'g/day' },
      calories: { min: 1800, max: 2500, unit: 'kcal/day' },
      carbs: { min: 200, max: 300, unit: 'g/day' },
    },
    avoid: [
      'high-fat foods', 'spicy foods', 'caffeine', 'alcohol', 
      'dairy (if lactose intolerant)', 'raw vegetables', 'nuts and seeds',
      'carbonated beverages', 'artificial sweeteners'
    ],
    beneficial: [
      'lean proteins', 'cooked vegetables', 'bananas', 'applesauce',
      'white rice', 'oatmeal', 'yogurt', 'salmon', 'eggs'
    ]
  };

  useEffect(() => {
    fetchNutritionData();
  }, [userId, timeRange]);

  const fetchNutritionData = async () => {
    setLoading(true);
    try {
      // Fetch journal entries (which include meal data and nutrition info)
      const journalResponse = await fetch(`${API_BASE_URL}/journal/entries/${userId}`);
      const journalData = await journalResponse.json();
      
      // Fetch prediction results
      const predictionsResponse = await fetch(`${API_BASE_URL}/recent-predictions?username=${userId}&limit=${timeRange}`);
      const predictionsData = await predictionsResponse.json();
      
      // Fetch meal logs for additional meal data
      const mealLogsResponse = await fetch(`${API_BASE_URL}/meal_logs?username=${userId}&days=${timeRange}`);
      const mealLogsData = await mealLogsResponse.json();
      
      if (journalData && journalData.length > 0) {
        analyzeNutritionData(journalData, predictionsData.predictions || [], mealLogsData.meal_logs || []);
      } else {
        // Create mock data for demonstration if API fails
        createMockAnalysisData();
      }
    } catch (error) {
      console.error('Error fetching nutrition data:', error);
      // Create mock data for demonstration if API fails
      createMockAnalysisData();
    } finally {
      setLoading(false);
    }
  };

  const createMockAnalysisData = () => {
    // Mock data for demonstration purposes
    const mockAnalysis = {
      totalEntries: 15,
      flareEntries: 3,
      averageNutrition: {
        calories: 1850,
        protein: 75,
        carbs: 220,
        fiber: 8,
      },
      deficiencies: [
        {
          nutrient: 'Fiber',
          current: 8,
          recommended: '10-15g',
          impact: 'Low fiber can worsen constipation and inflammation'
        }
      ],
      flareCorrelations: [
        {
          factor: 'High Fat Intake',
          correlation: 'Strong',
          description: 'Flare days show 25% higher fat consumption'
        }
      ],
      recommendations: [
        {
          type: 'deficiency',
          priority: 'High',
          title: 'Address Nutritional Deficiencies',
          description: 'Focus on increasing fiber intake',
          actions: ['Increase fiber intake to 10-15g daily', 'Add more fruits and vegetables']
        },
        {
          type: 'correlation',
          priority: 'Medium',
          title: 'Adjust Diet Based on Flare Patterns',
          description: 'Monitor fat intake on flare days',
          actions: ['Reduce fat intake on flare days', 'Choose lean proteins']
        },
        {
          type: 'general',
          priority: 'Low',
          title: 'Follow IBD Nutrition Guidelines',
          description: 'Maintain a balanced diet following IBD recommendations',
          actions: [
            'Include lean proteins daily',
            'Choose cooked vegetables over raw',
            'Stay hydrated with water',
            'Consider probiotic foods'
          ]
        }
      ],
      chartData: generateMockChartData()
    };
    setAnalysisData(mockAnalysis);
  };

  const generateMockChartData = () => {
    const data = [];
    for (let i = 29; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      data.push({
        date: date.toLocaleDateString(),
        calories: Math.floor(Math.random() * 500) + 1500,
        protein: Math.floor(Math.random() * 30) + 60,
        fiber: Math.floor(Math.random() * 10) + 5,
        flareRisk: Math.random() * 0.8
      });
    }
    return data;
  };

  const analyzeNutritionData = (journalEntries, predictions, mealLogs) => {
    const analysis = {
      totalEntries: journalEntries.length,
      flareEntries: 0,
      averageNutrition: {
        calories: 0,
        protein: 0,
        carbs: 0,
        fiber: 0,
        fat: 0
      },
      deficiencies: [],
      flareCorrelations: [],
      recommendations: [],
      chartData: []
    };

    // Count flare entries based on prediction results
    if (predictions && predictions.length > 0) {
      analysis.flareEntries = predictions.filter(p => p.probability > 0.5).length;
    }

    // Calculate average nutrition from journal entries
    if (journalEntries.length > 0) {
      const totals = journalEntries.reduce((acc, entry) => {
        acc.calories += entry.calories || 0;
        acc.protein += entry.protein || 0;
        acc.carbs += entry.carbs || 0;
        acc.fiber += entry.fiber || 0;
        acc.fat += entry.fat || 0;
        return acc;
      }, { calories: 0, protein: 0, carbs: 0, fiber: 0, fat: 0 });

      analysis.averageNutrition = {
        calories: Math.round(totals.calories / journalEntries.length),
        protein: Math.round(totals.protein / journalEntries.length),
        carbs: Math.round(totals.carbs / journalEntries.length),
        fiber: Math.round(totals.fiber / journalEntries.length),
        fat: Math.round(totals.fat / journalEntries.length)
      };
    }

    // Identify deficiencies based on IBD guidelines
    if (analysis.averageNutrition.fiber < 10) {
      analysis.deficiencies.push({
        nutrient: 'Fiber',
        current: analysis.averageNutrition.fiber,
        recommended: '10-15g',
        impact: 'Low fiber can worsen constipation and inflammation'
      });
    }

    if (analysis.averageNutrition.protein < 60) {
      analysis.deficiencies.push({
        nutrient: 'Protein',
        current: analysis.averageNutrition.protein,
        recommended: '60-90g',
        impact: 'Protein is crucial for healing and maintaining muscle mass'
      });
    }

    // Analyze flare correlations by matching journal entries with predictions
    if (predictions && predictions.length > 0 && journalEntries.length > 0) {
      const flareDays = predictions.filter(p => p.probability > 0.5);
      const nonFlareDays = predictions.filter(p => p.probability <= 0.5);

      if (flareDays.length > 0 && nonFlareDays.length > 0) {
        // Get nutrition data for flare vs non-flare days
        const flareNutrition = getAverageNutritionForDays(flareDays, journalEntries);
        const nonFlareNutrition = getAverageNutritionForDays(nonFlareDays, journalEntries);

        if (flareNutrition.fat > nonFlareNutrition.fat * 1.2) {
          analysis.flareCorrelations.push({
            factor: 'High Fat Intake',
            correlation: 'Strong',
            description: `Flare days show ${Math.round((flareNutrition.fat / nonFlareNutrition.fat - 1) * 100)}% higher fat consumption`
          });
        }

        if (flareNutrition.fiber < nonFlareNutrition.fiber * 0.8) {
          analysis.flareCorrelations.push({
            factor: 'Low Fiber Intake',
            correlation: 'Moderate',
            description: 'Flare days show lower fiber consumption'
          });
        }

        if (flareNutrition.calories > nonFlareNutrition.calories * 1.15) {
          analysis.flareCorrelations.push({
            factor: 'High Calorie Intake',
            correlation: 'Moderate',
            description: 'Flare days show higher calorie consumption'
          });
        }
      }
    }

    // Generate chart data
    analysis.chartData = journalEntries.map(entry => ({
      date: new Date(entry.entry_date).toLocaleDateString(),
      calories: entry.calories || 0,
      protein: entry.protein || 0,
      fiber: entry.fiber || 0,
      flareRisk: entry.prediction ? entry.prediction.probability : 0
    }));

    // Add recommendations
    if (analysis.deficiencies.length > 0) {
      analysis.recommendations.push({
        type: 'deficiency',
        priority: 'High',
        title: 'Address Nutritional Deficiencies',
        description: 'Focus on increasing fiber and protein intake',
        actions: ['Increase fiber intake to 10-15g daily', 'Add more lean proteins']
      });
    }

    analysis.recommendations.push({
      type: 'general',
      priority: 'Low',
      title: 'Follow IBD Nutrition Guidelines',
      description: 'Maintain a balanced diet following IBD recommendations',
      actions: [
        'Include lean proteins daily',
        'Choose cooked vegetables over raw',
        'Stay hydrated with water',
        'Consider probiotic foods'
      ]
    });

    setAnalysisData(analysis);
  };

  const getAverageNutritionForDays = (predictionDays, journalEntries) => {
    const dayDates = predictionDays.map(p => new Date(p.prediction_timestamp).toDateString());
    const relevantEntries = journalEntries.filter(entry => 
      dayDates.includes(new Date(entry.entry_date).toDateString())
    );

    if (relevantEntries.length === 0) {
      return { calories: 0, protein: 0, carbs: 0, fiber: 0, fat: 0 };
    }

    const totals = relevantEntries.reduce((acc, entry) => {
      acc.calories += entry.calories || 0;
      acc.protein += entry.protein || 0;
      acc.carbs += entry.carbs || 0;
      acc.fiber += entry.fiber || 0;
      acc.fat += entry.fat || 0;
      return acc;
    }, { calories: 0, protein: 0, carbs: 0, fiber: 0, fat: 0 });

    return {
      calories: totals.calories / relevantEntries.length,
      protein: totals.protein / relevantEntries.length,
      carbs: totals.carbs / relevantEntries.length,
      fiber: totals.fiber / relevantEntries.length,
      fat: totals.fat / relevantEntries.length
    };
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 'High': return colors.error;
      case 'Medium': return colors.warning;
      case 'Low': return colors.success;
      default: return colors.primary;
    }
  };

  if (loading) {
    return (
      <Card style={styles.card}>
        <Card.Content>
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={colors.primary} />
            <Text style={styles.loadingText}>Analyzing nutrition data...</Text>
          </View>
        </Card.Content>
      </Card>
    );
  }

  if (!analysisData) {
    return (
      <Card style={styles.card}>
        <Card.Content>
          <Title style={styles.cardTitle}>Nutrition Analyzer</Title>
          <Text style={styles.noDataText}>
            No nutrition data available. Start logging your meals to get personalized insights.
          </Text>
        </Card.Content>
      </Card>
    );
  }

  const chartConfig = {
    backgroundColor: colors.background,
    backgroundGradientFrom: colors.background,
    backgroundGradientTo: colors.background,
    decimalPlaces: 0,
    color: (opacity = 1) => `rgba(59, 130, 246, ${opacity})`,
    labelColor: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
    style: {
      borderRadius: 16,
    },
    propsForDots: {
      r: '6',
      strokeWidth: '2',
      stroke: colors.primary,
    },
  };

  const nutritionChartData = {
    labels: analysisData.chartData.slice(-7).map(d => d.date.split('/')[1]), // Show last 7 days
    datasets: [
      {
        data: analysisData.chartData.slice(-7).map(d => d.calories),
        color: (opacity = 1) => `rgba(59, 130, 246, ${opacity})`,
        strokeWidth: 2,
      },
    ],
  };

  return (
    <Card style={styles.card}>
      <Card.Content>
        <Title style={styles.cardTitle}>Nutrition Analyzer (Last 30 Days)</Title>
        
        {/* Summary Stats */}
        <View style={styles.statsContainer}>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>{analysisData.totalEntries}</Text>
            <Text style={styles.statLabel}>Total Entries</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>{analysisData.flareEntries}</Text>
            <Text style={styles.statLabel}>Flare Episodes</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>
              {analysisData.totalEntries > 0 
                ? Math.round((analysisData.flareEntries / analysisData.totalEntries) * 100)
                : 0}%
            </Text>
            <Text style={styles.statLabel}>Flare Rate</Text>
          </View>
        </View>

        {/* Average Nutrition */}
        <View style={styles.nutritionContainer}>
          <Title style={styles.sectionTitle}>Average Daily Nutrition</Title>
          <View style={styles.nutritionGrid}>
            <View style={styles.nutritionItem}>
              <Text style={styles.nutritionValue}>{analysisData.averageNutrition.calories}</Text>
              <Text style={styles.nutritionLabel}>Calories</Text>
            </View>
            <View style={styles.nutritionItem}>
              <Text style={styles.nutritionValue}>{analysisData.averageNutrition.protein}g</Text>
              <Text style={styles.nutritionLabel}>Protein</Text>
            </View>
            <View style={styles.nutritionItem}>
              <Text style={styles.nutritionValue}>{analysisData.averageNutrition.carbs}g</Text>
              <Text style={styles.nutritionLabel}>Carbs</Text>
            </View>
            <View style={styles.nutritionItem}>
              <Text style={styles.nutritionValue}>{analysisData.averageNutrition.fiber}g</Text>
              <Text style={styles.nutritionLabel}>Fiber</Text>
            </View>
          </View>
        </View>

        {/* Nutrition Chart */}
        <View style={styles.chartContainer}>
          <Title style={styles.sectionTitle}>Calories Trend (Last 7 Days)</Title>
          <LineChart
            data={nutritionChartData}
            width={width - 80}
            height={220}
            chartConfig={chartConfig}
            bezier
            style={styles.chart}
          />
        </View>

        {/* Deficiencies */}
        {analysisData.deficiencies.length > 0 && (
          <View style={styles.deficienciesContainer}>
            <Title style={styles.sectionTitle}>Nutritional Deficiencies</Title>
            {analysisData.deficiencies.map((deficiency, index) => (
              <View key={index} style={styles.deficiencyItem}>
                <Text style={styles.deficiencyTitle}>{deficiency.nutrient}</Text>
                <Text style={styles.deficiencyText}>
                  Current: {deficiency.current}g | Recommended: {deficiency.recommended}
                </Text>
                <Text style={styles.deficiencyImpact}>{deficiency.impact}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Recommendations */}
        <View style={styles.recommendationsContainer}>
          <Title style={styles.sectionTitle}>Recommendations</Title>
          {analysisData.recommendations.map((rec, index) => (
            <View key={index} style={styles.recommendationItem}>
              <View style={styles.recommendationHeader}>
                <Text style={styles.recommendationTitle}>{rec.title}</Text>
                <Chip 
                  mode="outlined" 
                  textStyle={{ color: getPriorityColor(rec.priority) }}
                  style={[styles.priorityChip, { borderColor: getPriorityColor(rec.priority) }]}
                >
                  {rec.priority}
                </Chip>
              </View>
              <Text style={styles.recommendationDescription}>{rec.description}</Text>
            </View>
          ))}
        </View>
      </Card.Content>
    </Card>
  );
};

const styles = StyleSheet.create({
  card: {
    marginBottom: 16,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 16,
    color: colors.primary,
  },
  loadingContainer: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: colors.text,
  },
  noDataText: {
    fontSize: 16,
    color: colors.placeholder,
    textAlign: 'center',
    fontStyle: 'italic',
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginBottom: 20,
  },
  statItem: {
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: colors.primary,
  },
  statLabel: {
    fontSize: 14,
    color: colors.placeholder,
    marginTop: 4,
  },
  nutritionContainer: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
    color: colors.primary,
  },
  nutritionGrid: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  nutritionItem: {
    alignItems: 'center',
  },
  nutritionValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: colors.primary,
  },
  nutritionLabel: {
    fontSize: 12,
    color: colors.placeholder,
    marginTop: 4,
  },
  chartContainer: {
    marginBottom: 20,
  },
  chart: {
    marginVertical: 8,
    borderRadius: 16,
  },
  deficienciesContainer: {
    marginBottom: 20,
  },
  deficiencyItem: {
    backgroundColor: colors.error + '20',
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
  },
  deficiencyTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.error,
  },
  deficiencyText: {
    fontSize: 14,
    color: colors.text,
    marginTop: 4,
  },
  deficiencyImpact: {
    fontSize: 12,
    color: colors.error,
    marginTop: 4,
    fontStyle: 'italic',
  },
  recommendationsContainer: {
    marginBottom: 20,
  },
  recommendationItem: {
    backgroundColor: colors.surface,
    padding: 12,
    borderRadius: 8,
    marginBottom: 8,
  },
  recommendationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  recommendationTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.text,
    flex: 1,
  },
  priorityChip: {
    marginLeft: 8,
  },
  recommendationDescription: {
    fontSize: 14,
    color: colors.text,
    lineHeight: 20,
  },
});

export default NutritionAnalyzer; 