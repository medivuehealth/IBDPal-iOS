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
import { LineChart } from 'react-native-chart-kit';
import { colors } from '../theme';
import { API_BASE_URL } from '../config';

const { width } = Dimensions.get('window');

const FlarePredictions = ({ userId }) => {
  const [predictionsData, setPredictionsData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [timeRange, setTimeRange] = useState(30); // days

  useEffect(() => {
    fetchPredictionsData();
  }, [userId, timeRange]);

  const fetchPredictionsData = async () => {
    setLoading(true);
    try {
      // Fetch flare statistics for the last 30 days
      const statsResponse = await fetch(`${API_BASE_URL}/flare-statistics?username=${userId}&days=${timeRange}`);
      const statsData = await statsResponse.json();
      
      // Fetch recent predictions for chart data
      const predictionsResponse = await fetch(`${API_BASE_URL}/recent-predictions?username=${userId}&limit=${timeRange}`);
      const predictionsData = await predictionsResponse.json();
      
      if (statsData && predictionsData) {
        analyzePredictionsData(statsData, predictionsData.predictions || []);
      } else {
        // Create mock data for demonstration
        createMockPredictionsData();
      }
    } catch (error) {
      console.error('Error fetching predictions data:', error);
      // Create mock data for demonstration if API fails
      createMockPredictionsData();
    } finally {
      setLoading(false);
    }
  };

  const createMockPredictionsData = () => {
    // Mock data for demonstration purposes
    const mockData = {
      totalPredictions: 25,
      totalFlares: 3,
      avgFlareProbability: 0.15,
      highestRisk: 0.85,
      riskTrend: 'decreasing',
      chartData: generateMockChartData(),
      recommendations: [
        {
          type: 'trend',
          priority: 'Low',
          title: 'Risk Trend Improving',
          description: 'Your flare risk has been decreasing over the past 30 days',
          actions: ['Continue current treatment plan', 'Maintain healthy lifestyle habits']
        },
        {
          type: 'general',
          priority: 'Medium',
          title: 'Monitor High Risk Days',
          description: 'Some days showed elevated risk levels',
          actions: ['Track symptoms on high-risk days', 'Consider stress management techniques']
        },
        {
          type: 'prevention',
          priority: 'Low',
          title: 'Preventive Measures',
          description: 'Continue with preventive strategies',
          actions: [
            'Maintain medication adherence',
            'Follow recommended diet',
            'Get adequate sleep',
            'Manage stress levels'
          ]
        }
      ]
    };
    setPredictionsData(mockData);
  };

  const generateMockChartData = () => {
    const data = [];
    for (let i = 29; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      data.push({
        date: date.toLocaleDateString(),
        probability: Math.random() * 0.8,
        flare: Math.random() > 0.8 ? 'Yes' : 'No'
      });
    }
    return data;
  };

  const analyzePredictionsData = (statistics, predictions) => {
    if (!statistics) {
      createMockPredictionsData();
      return;
    }

    const analysis = {
      totalPredictions: statistics.total_predictions || 0,
      totalFlares: statistics.total_flares || 0,
      avgFlareProbability: statistics.avg_flare_probability || 0,
      highestRisk: statistics.highest_risk || 0,
      riskTrend: 'stable',
      chartData: [],
      recommendations: []
    };

    // Generate chart data from predictions
    if (predictions && predictions.length > 0) {
      analysis.chartData = predictions.map(p => ({
        date: new Date(p.prediction_timestamp).toLocaleDateString(),
        probability: p.probability || 0,
        flare: p.prediction === 1 ? 'Yes' : 'No'
      }));
    } else {
      analysis.chartData = generateMockChartData();
    }

    // Determine risk trend
    if (analysis.chartData.length >= 2) {
      const recentAvg = analysis.chartData.slice(-7).reduce((sum, d) => sum + d.probability, 0) / 7;
      const olderAvg = analysis.chartData.slice(-14, -7).reduce((sum, d) => sum + d.probability, 0) / 7;
      
      if (recentAvg < olderAvg * 0.9) {
        analysis.riskTrend = 'decreasing';
      } else if (recentAvg > olderAvg * 1.1) {
        analysis.riskTrend = 'increasing';
      }
    }

    // Generate recommendations based on analysis
    if (analysis.riskTrend === 'increasing') {
      analysis.recommendations.push({
        type: 'trend',
        priority: 'High',
        title: 'Risk Trend Increasing',
        description: 'Your flare risk has been increasing over the past 30 days',
        actions: ['Consult your healthcare provider', 'Review medication adherence', 'Monitor symptoms closely']
      });
    } else if (analysis.riskTrend === 'decreasing') {
      analysis.recommendations.push({
        type: 'trend',
        priority: 'Low',
        title: 'Risk Trend Improving',
        description: 'Your flare risk has been decreasing over the past 30 days',
        actions: ['Continue current treatment plan', 'Maintain healthy lifestyle habits']
      });
    }

    if (analysis.avgFlareProbability > 0.7) {
      analysis.recommendations.push({
        type: 'high_risk',
        priority: 'High',
        title: 'High Average Risk',
        description: 'Your average flare risk is elevated',
        actions: ['Schedule appointment with healthcare provider', 'Review treatment plan', 'Consider medication adjustments']
      });
    }

    analysis.recommendations.push({
      type: 'general',
      priority: 'Low',
      title: 'Preventive Measures',
      description: 'Continue with preventive strategies',
      actions: [
        'Maintain medication adherence',
        'Follow recommended diet',
        'Get adequate sleep',
        'Manage stress levels'
      ]
    });

    setPredictionsData(analysis);
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case 'High': return colors.error;
      case 'Medium': return colors.warning;
      case 'Low': return colors.success;
      default: return colors.primary;
    }
  };

  const getTrendIcon = (trend) => {
    switch (trend) {
      case 'increasing': return '📈';
      case 'decreasing': return '📉';
      default: return '➡️';
    }
  };

  if (loading) {
    return (
      <Card style={styles.card}>
        <Card.Content>
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={colors.primary} />
            <Text style={styles.loadingText}>Analyzing flare predictions...</Text>
          </View>
        </Card.Content>
      </Card>
    );
  }

  if (!predictionsData) {
    return (
      <Card style={styles.card}>
        <Card.Content>
          <Title style={styles.cardTitle}>Flare Predictions</Title>
          <Text style={styles.noDataText}>
            No prediction data available. Start logging your health data to get personalized predictions.
          </Text>
        </Card.Content>
      </Card>
    );
  }

  const chartConfig = {
    backgroundColor: colors.background,
    backgroundGradientFrom: colors.background,
    backgroundGradientTo: colors.background,
    decimalPlaces: 2,
    color: (opacity = 1) => `rgba(124, 58, 237, ${opacity})`, // Purple color for flare predictions
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

  const flareChartData = {
    labels: predictionsData.chartData.slice(-7).map(d => d.date.split('/')[1]), // Show last 7 days
    datasets: [
      {
        data: predictionsData.chartData.slice(-7).map(d => d.probability),
        color: (opacity = 1) => `rgba(124, 58, 237, ${opacity})`,
        strokeWidth: 2,
      },
    ],
  };

  return (
    <Card style={styles.card}>
      <Card.Content>
        <Title style={styles.cardTitle}>Flare Predictions (Last 30 Days)</Title>
        
        {/* Summary Stats */}
        <View style={styles.statsContainer}>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>{predictionsData.totalPredictions}</Text>
            <Text style={styles.statLabel}>Total Predictions</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>{predictionsData.totalFlares}</Text>
            <Text style={styles.statLabel}>Predicted Flares</Text>
          </View>
          <View style={styles.statItem}>
            <Text style={styles.statNumber}>
              {(predictionsData.avgFlareProbability * 100).toFixed(1)}%
            </Text>
            <Text style={styles.statLabel}>Avg Risk</Text>
          </View>
        </View>

        {/* Risk Trend */}
        <View style={styles.trendContainer}>
          <Title style={styles.sectionTitle}>Risk Trend</Title>
          <View style={styles.trendItem}>
            <Text style={styles.trendIcon}>{getTrendIcon(predictionsData.riskTrend)}</Text>
            <Text style={styles.trendText}>
              {predictionsData.riskTrend === 'increasing' ? 'Risk Increasing' :
               predictionsData.riskTrend === 'decreasing' ? 'Risk Decreasing' :
               'Risk Stable'}
            </Text>
          </View>
        </View>

        {/* Flare Risk Chart */}
        <View style={styles.chartContainer}>
          <Title style={styles.sectionTitle}>Flare Risk Trend (Last 7 Days)</Title>
          <LineChart
            data={flareChartData}
            width={width - 80}
            height={220}
            chartConfig={chartConfig}
            bezier
            style={styles.chart}
          />
          <Text style={styles.chartNote}>
            Values show probability of flare (0-1 scale)
          </Text>
        </View>

        {/* Risk Levels */}
        <View style={styles.riskLevelsContainer}>
          <Title style={styles.sectionTitle}>Risk Analysis</Title>
          <View style={styles.riskLevelItem}>
            <Text style={styles.riskLevelLabel}>Highest Risk:</Text>
            <Text style={styles.riskLevelValue}>
              {(predictionsData.highestRisk * 100).toFixed(1)}%
            </Text>
          </View>
          <View style={styles.riskLevelItem}>
            <Text style={styles.riskLevelLabel}>Average Risk:</Text>
            <Text style={styles.riskLevelValue}>
              {(predictionsData.avgFlareProbability * 100).toFixed(1)}%
            </Text>
          </View>
          <View style={styles.riskLevelItem}>
            <Text style={styles.riskLevelLabel}>Flare Rate:</Text>
            <Text style={styles.riskLevelValue}>
              {predictionsData.totalPredictions > 0 
                ? ((predictionsData.totalFlares / predictionsData.totalPredictions) * 100).toFixed(1)
                : 0}%
            </Text>
          </View>
        </View>

        {/* Recommendations */}
        <View style={styles.recommendationsContainer}>
          <Title style={styles.sectionTitle}>Recommendations</Title>
          {predictionsData.recommendations.map((rec, index) => (
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
  trendContainer: {
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 12,
    color: colors.primary,
  },
  trendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    padding: 12,
    borderRadius: 8,
  },
  trendIcon: {
    fontSize: 24,
    marginRight: 12,
  },
  trendText: {
    fontSize: 16,
    color: colors.text,
    fontWeight: '500',
  },
  chartContainer: {
    marginBottom: 20,
  },
  chart: {
    marginVertical: 8,
    borderRadius: 16,
  },
  chartNote: {
    fontSize: 12,
    color: colors.placeholder,
    textAlign: 'center',
    marginTop: 8,
    fontStyle: 'italic',
  },
  riskLevelsContainer: {
    marginBottom: 20,
  },
  riskLevelItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: colors.surface,
  },
  riskLevelLabel: {
    fontSize: 16,
    color: colors.text,
  },
  riskLevelValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: colors.primary,
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

export default FlarePredictions; 