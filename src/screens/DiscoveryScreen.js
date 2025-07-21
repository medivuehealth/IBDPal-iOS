import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Dimensions,
  TouchableOpacity,
  Alert,
} from 'react-native';
import { LineChart, BarChart } from 'react-native-chart-kit';

const { width } = Dimensions.get('window');

const DiscoveryScreen = () => {
  const [selectedTimeframe, setSelectedTimeframe] = useState('week');
  const [selectedChart, setSelectedChart] = useState('nutrition');

  // IBD FODMAP and approved diet baselines
  const ibdBaselines = {
    calories: { low: 1800, moderate: 2200, high: 2600 },
    protein: { low: 60, moderate: 80, high: 100 },
    carbs: { low: 150, moderate: 200, high: 250 },
    fiber: { low: 15, moderate: 25, high: 35 }
  };

  // Sample data - replace with actual API data
  const nutritionData = {
    week: {
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      calories: [1850, 2100, 1950, 2200, 2000, 2300, 1900],
      protein: [75, 85, 70, 90, 80, 95, 75],
      carbs: [180, 200, 170, 220, 190, 240, 180],
      fiber: [18, 22, 16, 25, 20, 28, 19]
    },
    month: {
      labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
      calories: [2000, 2100, 1950, 2200],
      protein: [80, 85, 75, 90],
      carbs: [190, 200, 180, 220],
      fiber: [20, 22, 18, 25]
    }
  };

  const flareData = {
    week: {
      labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      data: [0.2, 0.3, 0.1, 0.4, 0.2, 0.1, 0.3]
    },
    month: {
      labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
      data: [0.25, 0.3, 0.2, 0.15]
    }
  };

  const aiInsights = [
    "Your fiber intake is below IBD FODMAP recommendations. Consider adding soluble fiber sources.",
    "Protein intake is optimal for IBD management. Maintain current levels.",
    "Calorie intake shows good consistency with IBD dietary guidelines.",
    "Consider reducing complex carbs during potential flare periods."
  ];

  const renderNutritionComparisonChart = () => {
    const data = nutritionData[selectedTimeframe];
    const baseline = ibdBaselines;

    const chartData = {
      labels: data.labels,
      datasets: [
        {
          data: data.calories,
          color: (opacity = 1) => `rgba(255, 99, 132, ${opacity})`,
          strokeWidth: 2,
          legend: 'Actual Calories'
        },
        {
          data: Array(data.labels.length).fill(baseline.calories.moderate),
          color: (opacity = 1) => `rgba(255, 99, 132, ${opacity * 0.3})`,
          strokeWidth: 1,
          strokeDasharray: [5, 5],
          legend: 'IBD Baseline'
        },
        {
          data: data.protein,
          color: (opacity = 1) => `rgba(54, 162, 235, ${opacity})`,
          strokeWidth: 2,
          legend: 'Actual Protein (g)'
        },
        {
          data: Array(data.labels.length).fill(baseline.protein.moderate),
          color: (opacity = 1) => `rgba(54, 162, 235, ${opacity * 0.3})`,
          strokeWidth: 1,
          strokeDasharray: [5, 5],
          legend: 'Protein Baseline'
        },
        {
          data: data.carbs,
          color: (opacity = 1) => `rgba(255, 206, 86, ${opacity})`,
          strokeWidth: 2,
          legend: 'Actual Carbs (g)'
        },
        {
          data: Array(data.labels.length).fill(baseline.carbs.moderate),
          color: (opacity = 1) => `rgba(255, 206, 86, ${opacity * 0.3})`,
          strokeWidth: 1,
          strokeDasharray: [5, 5],
          legend: 'Carbs Baseline'
        },
        {
          data: data.fiber,
          color: (opacity = 1) => `rgba(75, 192, 192, ${opacity})`,
          strokeWidth: 2,
          legend: 'Actual Fiber (g)'
        },
        {
          data: Array(data.labels.length).fill(baseline.fiber.moderate),
          color: (opacity = 1) => `rgba(75, 192, 192, ${opacity * 0.3})`,
          strokeWidth: 1,
          strokeDasharray: [5, 5],
          legend: 'Fiber Baseline'
        }
      ]
    };

    return (
      <View style={styles.chartContainer}>
        <Text style={styles.chartTitle}>Nutrition vs IBD Diet Baselines</Text>
        <Text style={styles.chartSubtitle}>
          Comparing your intake to FODMAP and IBD-approved recommendations
        </Text>
        
        <LineChart
          data={chartData}
          width={width - 40}
          height={300}
          chartConfig={{
            backgroundColor: '#ffffff',
            backgroundGradientFrom: '#ffffff',
            backgroundGradientTo: '#ffffff',
            decimalPlaces: 0,
            color: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
            labelColor: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
            style: {
              borderRadius: 16,
            },
            propsForDots: {
              r: '4',
              strokeWidth: '2',
            },
          }}
          bezier
          style={styles.chart}
          legend={['Actual', 'Baseline']}
        />

        {/* Comprehensive Legend */}
        <View style={styles.legendContainer}>
          <Text style={styles.legendTitle}>Chart Legend</Text>
          
          {/* Calories Legend */}
          <View style={styles.legendSection}>
            <Text style={styles.legendSectionTitle}>Calories (kcal/day)</Text>
            <View style={styles.legendItem}>
              <View style={[styles.legendColor, { backgroundColor: 'rgba(255, 99, 132, 1)' }]} />
              <Text style={styles.legendText}>Actual Intake</Text>
            </View>
            <View style={styles.legendItem}>
              <View style={[styles.legendColor, { backgroundColor: 'rgba(255, 99, 132, 0.3)' }]} />
              <Text style={styles.legendText}>IBD Baseline: {baseline.calories.moderate} kcal</Text>
            </View>
          </View>

          {/* Protein Legend */}
          <View style={styles.legendSection}>
            <Text style={styles.legendSectionTitle}>Protein (g/day)</Text>
            <View style={styles.legendItem}>
              <View style={[styles.legendColor, { backgroundColor: 'rgba(54, 162, 235, 1)' }]} />
              <Text style={styles.legendText}>Actual Intake</Text>
            </View>
            <View style={styles.legendItem}>
              <View style={[styles.legendColor, { backgroundColor: 'rgba(54, 162, 235, 0.3)' }]} />
              <Text style={styles.legendText}>IBD Baseline: {baseline.protein.moderate}g</Text>
            </View>
          </View>

          {/* Carbs Legend */}
          <View style={styles.legendSection}>
            <Text style={styles.legendSectionTitle}>Carbohydrates (g/day)</Text>
            <View style={styles.legendItem}>
              <View style={[styles.legendColor, { backgroundColor: 'rgba(255, 206, 86, 1)' }]} />
              <Text style={styles.legendText}>Actual Intake</Text>
            </View>
            <View style={styles.legendItem}>
              <View style={[styles.legendColor, { backgroundColor: 'rgba(255, 206, 86, 0.3)' }]} />
              <Text style={styles.legendText}>IBD Baseline: {baseline.carbs.moderate}g</Text>
            </View>
          </View>

          {/* Fiber Legend */}
          <View style={styles.legendSection}>
            <Text style={styles.legendSectionTitle}>Fiber (g/day)</Text>
            <View style={styles.legendItem}>
              <View style={[styles.legendColor, { backgroundColor: 'rgba(75, 192, 192, 1)' }]} />
              <Text style={styles.legendText}>Actual Intake</Text>
            </View>
            <View style={styles.legendItem}>
              <View style={[styles.legendColor, { backgroundColor: 'rgba(75, 192, 192, 0.3)' }]} />
              <Text style={styles.legendText}>IBD Baseline: {baseline.fiber.moderate}g</Text>
            </View>
          </View>

          {/* Baseline Info */}
          <View style={styles.baselineInfo}>
            <Text style={styles.baselineTitle}>IBD Diet Guidelines:</Text>
            <Text style={styles.baselineText}>• Based on FODMAP and IBD-approved dietary programs</Text>
            <Text style={styles.baselineText}>• Moderate activity level recommendations</Text>
            <Text style={styles.baselineText}>• Designed for IBD symptom management</Text>
            <Text style={styles.baselineText}>• Consult healthcare provider for personalized targets</Text>
          </View>
        </View>
      </View>
    );
  };

  const renderFlarePredictionChart = () => (
    <View style={styles.chartContainer}>
      <Text style={styles.chartTitle}>Flare Risk Prediction</Text>
      <Text style={styles.chartSubtitle}>AI-powered flare probability analysis</Text>
      
      <BarChart
        data={{
          labels: flareData[selectedTimeframe].labels,
          datasets: [{
            data: flareData[selectedTimeframe].data
          }]
        }}
        width={width - 40}
        height={250}
        chartConfig={{
          backgroundColor: '#ffffff',
          backgroundGradientFrom: '#ffffff',
          backgroundGradientTo: '#ffffff',
          decimalPlaces: 2,
          color: (opacity = 1) => `rgba(255, 99, 132, ${opacity})`,
          labelColor: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
          style: {
            borderRadius: 16,
          },
        }}
        style={styles.chart}
      />
    </View>
  );

  const renderAIInsights = () => (
    <View style={styles.insightsContainer}>
      <Text style={styles.insightsTitle}>AI-Powered Insights</Text>
      {aiInsights.map((insight, index) => (
        <View key={index} style={styles.insightItem}>
          <Text style={styles.insightText}>• {insight}</Text>
        </View>
      ))}
    </View>
  );

  const renderDietaryApproaches = () => (
    <View style={styles.approachesContainer}>
      <Text style={styles.approachesTitle}>IBD Dietary Approaches</Text>
      
      <TouchableOpacity style={styles.approachCard}>
        <Text style={styles.approachTitle}>FODMAP Diet</Text>
        <Text style={styles.approachDescription}>
          Low-FODMAP foods to reduce digestive symptoms
        </Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.approachCard}>
        <Text style={styles.approachTitle}>Anti-Inflammatory Diet</Text>
        <Text style={styles.approachDescription}>
          Foods rich in omega-3s and antioxidants
        </Text>
      </TouchableOpacity>

      <TouchableOpacity style={styles.approachCard}>
        <Text style={styles.approachTitle}>Elimination Diet</Text>
        <Text style={styles.approachDescription}>
          Identify trigger foods systematically
        </Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Discovery</Text>
        <Text style={styles.subtitle}>AI-Powered IBD Insights & Trends</Text>
      </View>

      {/* Timeframe Selector */}
      <View style={styles.timeframeContainer}>
        <TouchableOpacity
          style={[styles.timeframeButton, selectedTimeframe === 'week' && styles.activeButton]}
          onPress={() => setSelectedTimeframe('week')}
        >
          <Text style={[styles.timeframeText, selectedTimeframe === 'week' && styles.activeText]}>
            Week
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.timeframeButton, selectedTimeframe === 'month' && styles.activeButton]}
          onPress={() => setSelectedTimeframe('month')}
        >
          <Text style={[styles.timeframeText, selectedTimeframe === 'month' && styles.activeText]}>
            Month
          </Text>
        </TouchableOpacity>
      </View>

      {/* Chart Selector */}
      <View style={styles.chartSelector}>
        <TouchableOpacity
          style={[styles.chartButton, selectedChart === 'nutrition' && styles.activeChartButton]}
          onPress={() => setSelectedChart('nutrition')}
        >
          <Text style={[styles.chartButtonText, selectedChart === 'nutrition' && styles.activeChartText]}>
            Nutrition
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.chartButton, selectedChart === 'flare' && styles.activeChartButton]}
          onPress={() => setSelectedChart('flare')}
        >
          <Text style={[styles.chartButtonText, selectedChart === 'flare' && styles.activeChartText]}>
            Flare Risk
          </Text>
        </TouchableOpacity>
      </View>

      {/* Charts */}
      {selectedChart === 'nutrition' && renderNutritionComparisonChart()}
      {selectedChart === 'flare' && renderFlarePredictionChart()}

      {/* AI Insights */}
      {renderAIInsights()}

      {/* Dietary Approaches */}
      {renderDietaryApproaches()}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  header: {
    padding: 20,
    backgroundColor: '#ffffff',
    borderBottomWidth: 1,
    borderBottomColor: '#e9ecef',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 5,
  },
  subtitle: {
    fontSize: 16,
    color: '#6c757d',
  },
  timeframeContainer: {
    flexDirection: 'row',
    padding: 20,
    backgroundColor: '#ffffff',
    marginBottom: 10,
  },
  timeframeButton: {
    flex: 1,
    paddingVertical: 10,
    paddingHorizontal: 20,
    marginHorizontal: 5,
    borderRadius: 20,
    backgroundColor: '#f8f9fa',
    alignItems: 'center',
  },
  activeButton: {
    backgroundColor: '#007bff',
  },
  timeframeText: {
    fontSize: 16,
    color: '#6c757d',
    fontWeight: '500',
  },
  activeText: {
    color: '#ffffff',
  },
  chartSelector: {
    flexDirection: 'row',
    paddingHorizontal: 20,
    marginBottom: 10,
  },
  chartButton: {
    flex: 1,
    paddingVertical: 8,
    paddingHorizontal: 16,
    marginHorizontal: 5,
    borderRadius: 15,
    backgroundColor: '#ffffff',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#e9ecef',
  },
  activeChartButton: {
    backgroundColor: '#28a745',
    borderColor: '#28a745',
  },
  chartButtonText: {
    fontSize: 14,
    color: '#6c757d',
    fontWeight: '500',
  },
  activeChartText: {
    color: '#ffffff',
  },
  chartContainer: {
    backgroundColor: '#ffffff',
    margin: 10,
    padding: 15,
    borderRadius: 15,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  chartTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 5,
  },
  chartSubtitle: {
    fontSize: 14,
    color: '#6c757d',
    marginBottom: 15,
  },
  chart: {
    marginVertical: 8,
    borderRadius: 16,
  },
  baselineInfo: {
    marginTop: 15,
    padding: 10,
    backgroundColor: '#f8f9fa',
    borderRadius: 10,
  },
  baselineTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 5,
  },
  baselineText: {
    fontSize: 12,
    color: '#6c757d',
    marginBottom: 2,
  },
  insightsContainer: {
    backgroundColor: '#ffffff',
    margin: 10,
    padding: 15,
    borderRadius: 15,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
  },
  insightsTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 15,
  },
  insightItem: {
    marginBottom: 10,
  },
  insightText: {
    fontSize: 14,
    color: '#495057',
    lineHeight: 20,
  },
  approachesContainer: {
    backgroundColor: '#ffffff',
    margin: 10,
    padding: 15,
    borderRadius: 15,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 3.84,
    elevation: 5,
    marginBottom: 20,
  },
  approachesTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 15,
  },
  approachCard: {
    backgroundColor: '#f8f9fa',
    padding: 15,
    borderRadius: 10,
    marginBottom: 10,
    borderLeftWidth: 4,
    borderLeftColor: '#007bff',
  },
  approachTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 5,
  },
  approachDescription: {
    fontSize: 14,
    color: '#6c757d',
  },
  legendContainer: {
    marginTop: 15,
    padding: 15,
    backgroundColor: '#f8f9fa',
    borderRadius: 10,
  },
  legendTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 10,
  },
  legendSection: {
    marginBottom: 15,
  },
  legendSectionTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 5,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 3,
  },
  legendColor: {
    width: 10,
    height: 10,
    borderRadius: 5,
    marginRight: 8,
  },
  legendText: {
    fontSize: 13,
    color: '#495057',
  },
});

export default DiscoveryScreen; 