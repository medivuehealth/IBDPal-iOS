import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Dimensions,
} from 'react-native';

const { width } = Dimensions.get('window');

const InsightScreen = () => {
  const [selectedPeriod, setSelectedPeriod] = useState('week');
  const [selectedCategory, setSelectedCategory] = useState('nutrition');

  const periods = [
    { key: 'week', label: 'Week' },
    { key: 'month', label: 'Month' },
    { key: '3months', label: '3 Months' },
  ];

  const categories = [
    { key: 'nutrition', label: 'Nutrition', icon: '🍎' },
    { key: 'flareRisk', label: 'Flare Risk', icon: '⚠️' },
    { key: 'symptoms', label: 'Symptoms', icon: '📊' },
  ];

  const renderNutritionChart = () => (
    <View style={styles.chartContainer}>
      <Text style={styles.chartTitle}>Nutrition Trends</Text>
      <View style={styles.chartPlaceholder}>
        <Text style={styles.chartPlaceholderText}>📈</Text>
        <Text style={styles.chartPlaceholderText}>Calories: 1,850 avg</Text>
        <Text style={styles.chartPlaceholderText}>Protein: 65g avg</Text>
        <Text style={styles.chartPlaceholderText}>Fiber: 18g avg</Text>
        <Text style={styles.chartPlaceholderText}>Hydration: 6.5 cups avg</Text>
      </View>
      <View style={styles.metricRow}>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>85%</Text>
          <Text style={styles.metricLabel}>Goal Achievement</Text>
        </View>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>+12%</Text>
          <Text style={styles.metricLabel}>vs Last Period</Text>
        </View>
      </View>
    </View>
  );

  const renderFlareRiskChart = () => (
    <View style={styles.chartContainer}>
      <Text style={styles.chartTitle}>Flare Risk Assessment</Text>
      <View style={styles.chartPlaceholder}>
        <Text style={styles.chartPlaceholderText}>🔮</Text>
        <Text style={styles.chartPlaceholderText}>Current Risk: Low</Text>
        <Text style={styles.chartPlaceholderText}>Trend: Decreasing</Text>
        <Text style={styles.chartPlaceholderText}>Next Assessment: 3 days</Text>
      </View>
      <View style={styles.riskIndicator}>
        <View style={[styles.riskBar, { width: '25%', backgroundColor: '#27ae60' }]} />
        <Text style={styles.riskText}>Low Risk</Text>
      </View>
      <View style={styles.metricRow}>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>25%</Text>
          <Text style={styles.metricLabel}>Risk Level</Text>
        </View>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>-15%</Text>
          <Text style={styles.metricLabel}>vs Last Week</Text>
        </View>
      </View>
    </View>
  );

  const renderSymptomsChart = () => (
    <View style={styles.chartContainer}>
      <Text style={styles.chartTitle}>Symptom Patterns</Text>
      <View style={styles.chartPlaceholder}>
        <Text style={styles.chartPlaceholderText}>📋</Text>
        <Text style={styles.chartPlaceholderText}>Pain Level: 2.3 avg</Text>
        <Text style={styles.chartPlaceholderText}>Bowel Frequency: 2.1/day</Text>
        <Text style={styles.chartPlaceholderText}>Energy Level: 7.5/10</Text>
        <Text style={styles.chartPlaceholderText}>Sleep Quality: 8.2/10</Text>
      </View>
      <View style={styles.symptomBars}>
        <View style={styles.symptomBar}>
          <Text style={styles.symptomLabel}>Pain</Text>
          <View style={styles.barContainer}>
            <View style={[styles.bar, { width: '23%', backgroundColor: '#e74c3c' }]} />
          </View>
          <Text style={styles.barValue}>2.3</Text>
        </View>
        <View style={styles.symptomBar}>
          <Text style={styles.symptomLabel}>Fatigue</Text>
          <View style={styles.barContainer}>
            <View style={[styles.bar, { width: '35%', backgroundColor: '#f39c12' }]} />
          </View>
          <Text style={styles.barValue}>3.5</Text>
        </View>
        <View style={styles.symptomBar}>
          <Text style={styles.symptomLabel}>Bloating</Text>
          <View style={styles.barContainer}>
            <View style={[styles.bar, { width: '18%', backgroundColor: '#9b59b6' }]} />
          </View>
          <Text style={styles.barValue}>1.8</Text>
        </View>
      </View>
    </View>
  );

  const renderChart = () => {
    switch (selectedCategory) {
      case 'nutrition':
        return renderNutritionChart();
      case 'flareRisk':
        return renderFlareRiskChart();
      case 'symptoms':
        return renderSymptomsChart();
      default:
        return renderNutritionChart();
    }
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Insights & Analytics</Text>
      
      {/* Time Period Selector */}
      <View style={styles.periodSelector}>
        <Text style={styles.selectorTitle}>Time Period</Text>
        <View style={styles.periodButtons}>
          {periods.map((period) => (
            <TouchableOpacity
              key={period.key}
              style={[
                styles.periodButton,
                selectedPeriod === period.key && styles.periodButtonActive,
              ]}
              onPress={() => setSelectedPeriod(period.key)}
            >
              <Text
                style={[
                  styles.periodButtonText,
                  selectedPeriod === period.key && styles.periodButtonTextActive,
                ]}
              >
                {period.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Category Selector */}
      <View style={styles.categorySelector}>
        <Text style={styles.selectorTitle}>Category</Text>
        <View style={styles.categoryButtons}>
          {categories.map((category) => (
            <TouchableOpacity
              key={category.key}
              style={[
                styles.categoryButton,
                selectedCategory === category.key && styles.categoryButtonActive,
              ]}
              onPress={() => setSelectedCategory(category.key)}
            >
              <Text style={styles.categoryIcon}>{category.icon}</Text>
              <Text
                style={[
                  styles.categoryButtonText,
                  selectedCategory === category.key && styles.categoryButtonTextActive,
                ]}
              >
                {category.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {/* Chart Display */}
      {renderChart()}

      {/* Summary Cards */}
      <View style={styles.summarySection}>
        <Text style={styles.summaryTitle}>Quick Summary</Text>
        <View style={styles.summaryCards}>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryCardTitle}>Overall Health</Text>
            <Text style={styles.summaryCardValue}>Good</Text>
            <Text style={styles.summaryCardTrend}>↗️ Improving</Text>
          </View>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryCardTitle}>Adherence</Text>
            <Text style={styles.summaryCardValue}>92%</Text>
            <Text style={styles.summaryCardTrend}>📈 On Track</Text>
          </View>
          <View style={styles.summaryCard}>
            <Text style={styles.summaryCardTitle}>Next Goal</Text>
            <Text style={styles.summaryCardValue}>Increase Fiber</Text>
            <Text style={styles.summaryCardTrend}>🎯 3g more/day</Text>
          </View>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 20,
    textAlign: 'center',
  },
  periodSelector: {
    backgroundColor: 'white',
    padding: 15,
    borderRadius: 10,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  selectorTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#34495e',
    marginBottom: 10,
  },
  periodButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  periodButton: {
    flex: 1,
    padding: 10,
    marginHorizontal: 5,
    borderRadius: 8,
    backgroundColor: '#f8f9fa',
    borderWidth: 1,
    borderColor: '#dee2e6',
  },
  periodButtonActive: {
    backgroundColor: '#3498db',
    borderColor: '#3498db',
  },
  periodButtonText: {
    textAlign: 'center',
    fontSize: 14,
    color: '#6c757d',
  },
  periodButtonTextActive: {
    color: 'white',
    fontWeight: '600',
  },
  categorySelector: {
    backgroundColor: 'white',
    padding: 15,
    borderRadius: 10,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  categoryButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  categoryButton: {
    flex: 1,
    padding: 15,
    marginHorizontal: 5,
    borderRadius: 8,
    backgroundColor: '#f8f9fa',
    borderWidth: 1,
    borderColor: '#dee2e6',
    alignItems: 'center',
  },
  categoryButtonActive: {
    backgroundColor: '#3498db',
    borderColor: '#3498db',
  },
  categoryIcon: {
    fontSize: 20,
    marginBottom: 5,
  },
  categoryButtonText: {
    fontSize: 12,
    color: '#6c757d',
    textAlign: 'center',
  },
  categoryButtonTextActive: {
    color: 'white',
    fontWeight: '600',
  },
  chartContainer: {
    backgroundColor: 'white',
    padding: 20,
    borderRadius: 10,
    marginBottom: 15,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  chartTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 15,
    textAlign: 'center',
  },
  chartPlaceholder: {
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#f8f9fa',
    borderRadius: 8,
    marginBottom: 15,
  },
  chartPlaceholderText: {
    fontSize: 16,
    color: '#6c757d',
    marginBottom: 5,
  },
  metricRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  metric: {
    alignItems: 'center',
  },
  metricValue: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#2c3e50',
  },
  metricLabel: {
    fontSize: 12,
    color: '#6c757d',
    marginTop: 5,
  },
  riskIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 15,
  },
  riskBar: {
    height: 20,
    borderRadius: 10,
    marginRight: 10,
  },
  riskText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#27ae60',
  },
  symptomBars: {
    marginTop: 15,
  },
  symptomBar: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  symptomLabel: {
    width: 60,
    fontSize: 14,
    color: '#2c3e50',
  },
  barContainer: {
    flex: 1,
    height: 20,
    backgroundColor: '#f1f2f6',
    borderRadius: 10,
    marginHorizontal: 10,
    overflow: 'hidden',
  },
  bar: {
    height: '100%',
    borderRadius: 10,
  },
  barValue: {
    width: 30,
    fontSize: 14,
    color: '#2c3e50',
    textAlign: 'right',
  },
  summarySection: {
    backgroundColor: 'white',
    padding: 15,
    borderRadius: 10,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  summaryTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 15,
  },
  summaryCards: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  summaryCard: {
    flex: 1,
    padding: 15,
    marginHorizontal: 5,
    backgroundColor: '#f8f9fa',
    borderRadius: 8,
    alignItems: 'center',
  },
  summaryCardTitle: {
    fontSize: 12,
    color: '#6c757d',
    marginBottom: 5,
  },
  summaryCardValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#2c3e50',
    marginBottom: 5,
  },
  summaryCardTrend: {
    fontSize: 10,
    color: '#27ae60',
  },
});

export default InsightScreen; 