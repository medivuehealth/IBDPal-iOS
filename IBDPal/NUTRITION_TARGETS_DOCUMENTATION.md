# IBDPal Nutrition Targets Documentation

## Overview
This document explains how the IBDPal app calculates personalized nutrition targets based on user profile data (weight, gender, age, disease activity) using NIH Dietary Reference Intakes (DRI) as the baseline.

## NIH DRI Reference Links
- **Primary Source**: [NIH Office of Dietary Supplements - Nutrient Recommendations and Databases](https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx)
- **DRI Calculator**: [NIH DRI Calculator for Healthcare Professionals](https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx)
- **DRI Reports**: [Food and Nutrition Board DRI Reports](https://www.nationalacademies.org/our-work/dietary-reference-intakes-dris)

## DRI Baseline Storage and Calculation

### Where DRI Values Are Stored
- **Location**: Hardcoded in Swift code (`DiscoverView.swift`)
- **Storage Type**: Static constants in `IBDTargets` struct and `PersonalizedIBDTargets.calculate()` function
- **Calculation**: **Runtime calculation** - values are computed on-demand when user profile is accessed
- **No Database Storage**: DRI baseline values are not stored in the database; they are embedded in the application code

### Implementation Details
```swift
// DRI baseline values are hardcoded in the application
let baseCalories = gender == "male" ? 2500 : 2000 // DRI baseline
let baseProtein = gender == "male" ? 56 : 46 // DRI baseline (g/day)
let baseFiber = gender == "male" ? 38 : 25 // DRI baseline (g/day)
```

## Base DRI Values (NIH Recommendations)

### Macronutrients (Daily)
| Nutrient | Male (19-50 years) | Female (19-50 years) | Unit |
|----------|-------------------|---------------------|------|
| Calories | 2500 | 2000 | kcal/day |
| Protein | 56 | 46 | g/day |
| Fiber | 38 | 25 | g/day |
| Hydration | 3700 | 2700 | ml/day |
| Fat | 30% of calories | 30% of calories | % |
| Carbs | Remaining calories | Remaining calories | g/day |

### Micronutrients (Daily RDA/AI)
| Nutrient | Male (19-50 years) | Female (19-50 years) | Unit |
|----------|-------------------|---------------------|------|
| Vitamin D | 600 | 600 | IU |
| Vitamin B12 | 2.4 | 2.4 | mcg |
| Iron | 8 | 18 | mg |
| Folate | 400 | 400 | mcg DFE |
| Calcium | 1000 | 1000 | mg |
| Zinc | 11 | 8 | mg |
| Omega-3 | 1100 | 1100 | mg |

## Calculation Logic

### 1. Base Target Selection
The system first selects gender-specific DRI baseline values:

```swift
let baseCalories = gender == "male" ? 2500 : 2000
let baseProtein = gender == "male" ? 56 : 46
let baseFiber = gender == "male" ? 38 : 25
let baseHydration = gender == "male" ? 3700 : 2700
```

### 2. Multiplier Calculations
Three multipliers are applied based on user profile:

#### Disease Activity Multiplier
- **Remission**: 1.0 (no adjustment)
- **Mild**: 1.1 (10% increase)
- **Moderate**: 1.2 (20% increase)
- **Severe**: 1.3 (30% increase)

#### Age Multiplier
- **< 18 years**: 1.2 (20% increase for growth)
- **18-50 years**: 1.0 (no adjustment)
- **51-70 years**: 1.1 (10% increase for aging)
- **> 70 years**: 1.2 (20% increase for aging)

#### Disease Type Multiplier
- **IBD patients**: 1.2 (20% increase for malabsorption)
- **Normal people**: 1.0 (no adjustment)

### 3. Final Calculation
```swift
let totalMultiplier = diseaseActivityMultiplier × ageMultiplier × diseaseTypeMultiplier
let finalTarget = baseTarget × totalMultiplier
```

## Use Case Examples

### Example 1: Healthy 25-year-old Male (Normal Person)
- **Weight**: 70kg
- **Gender**: Male
- **Age**: 25
- **Disease**: None

**Calculation**:
- Base: 2500 kcal, 56g protein, 38g fiber, 3700ml hydration
- Disease Activity: 1.0 (no disease)
- Age: 1.0 (18-50 years)
- Disease Type: 1.0 (normal person)
- **Total Multiplier**: 1.0 × 1.0 × 1.0 = 1.0

**Daily Targets**:
- Calories: 2500 kcal
- Protein: 56g
- Fiber: 38g
- Hydration: 3700ml
- Vitamin D: 600 IU
- Iron: 8mg
- Zinc: 11mg

### Example 2: Healthy 30-year-old Female (Normal Person)
- **Weight**: 60kg
- **Gender**: Female
- **Age**: 30
- **Disease**: None

**Calculation**:
- Base: 2000 kcal, 46g protein, 25g fiber, 2700ml hydration
- Disease Activity: 1.0 (no disease)
- Age: 1.0 (18-50 years)
- Disease Type: 1.0 (normal person)
- **Total Multiplier**: 1.0 × 1.0 × 1.0 = 1.0

**Daily Targets**:
- Calories: 2000 kcal
- Protein: 46g
- Fiber: 25g
- Hydration: 2700ml
- Vitamin D: 600 IU
- Iron: 18mg
- Zinc: 8mg

### Example 3: IBD Patient - 28-year-old Male in Remission
- **Weight**: 75kg
- **Gender**: Male
- **Age**: 28
- **Disease**: Crohn's Disease (Remission)

**Calculation**:
- Base: 2500 kcal, 56g protein, 38g fiber, 3700ml hydration
- Disease Activity: 1.0 (remission)
- Age: 1.0 (18-50 years)
- Disease Type: 1.2 (IBD patient)
- **Total Multiplier**: 1.0 × 1.0 × 1.2 = 1.2

**Daily Targets**:
- Calories: 3000 kcal (2500 × 1.2)
- Protein: 67g (56 × 1.2)
- Fiber: 46g (38 × 1.2)
- Hydration: 4440ml (3700 × 1.2)
- Vitamin D: 720 IU (600 × 1.2)
- Iron: 10mg (8 × 1.2)
- Zinc: 13mg (11 × 1.2)

### Example 4: IBD Patient - 35-year-old Female with Moderate Activity
- **Weight**: 65kg
- **Gender**: Female
- **Age**: 35
- **Disease**: Ulcerative Colitis (Moderate)

**Calculation**:
- Base: 2000 kcal, 46g protein, 25g fiber, 2700ml hydration
- Disease Activity: 1.2 (moderate)
- Age: 1.0 (18-50 years)
- Disease Type: 1.2 (IBD patient)
- **Total Multiplier**: 1.2 × 1.0 × 1.2 = 1.44

**Daily Targets**:
- Calories: 2880 kcal (2000 × 1.44)
- Protein: 66g (46 × 1.44)
- Fiber: 36g (25 × 1.44)
- Hydration: 3888ml (2700 × 1.44)
- Vitamin D: 864 IU (600 × 1.44)
- Iron: 26mg (18 × 1.44)
- Zinc: 12mg (8 × 1.44)

### Example 5: Elderly IBD Patient - 65-year-old Male with Severe Activity
- **Weight**: 80kg
- **Gender**: Male
- **Age**: 65
- **Disease**: Crohn's Disease (Severe)

**Calculation**:
- Base: 2500 kcal, 56g protein, 38g fiber, 3700ml hydration
- Disease Activity: 1.3 (severe)
- Age: 1.1 (51-70 years)
- Disease Type: 1.2 (IBD patient)
- **Total Multiplier**: 1.3 × 1.1 × 1.2 = 1.716

**Daily Targets**:
- Calories: 4290 kcal (2500 × 1.716)
- Protein: 96g (56 × 1.716)
- Fiber: 65g (38 × 1.716)
- Hydration: 6349ml (3700 × 1.716)
- Vitamin D: 1030 IU (600 × 1.716)
- Iron: 14mg (8 × 1.716)
- Zinc: 19mg (11 × 1.716)

## Expected Daily Baseline Values Summary

### Normal People (No Disease)
| Age Group | Male | Female |
|-----------|------|--------|
| **18-50 years** | 2500 kcal, 56g protein, 38g fiber | 2000 kcal, 46g protein, 25g fiber |
| **51-70 years** | 2750 kcal, 62g protein, 42g fiber | 2200 kcal, 51g protein, 28g fiber |
| **>70 years** | 3000 kcal, 67g protein, 46g fiber | 2400 kcal, 55g protein, 30g fiber |

### IBD Patients (Remission)
| Age Group | Male | Female |
|-----------|------|--------|
| **18-50 years** | 3000 kcal, 67g protein, 46g fiber | 2400 kcal, 55g protein, 30g fiber |
| **51-70 years** | 3300 kcal, 74g protein, 50g fiber | 2640 kcal, 61g protein, 34g fiber |
| **>70 years** | 3600 kcal, 80g protein, 55g fiber | 2880 kcal, 66g protein, 36g fiber |

### IBD Patients (Moderate Activity)
| Age Group | Male | Female |
|-----------|------|--------|
| **18-50 years** | 3600 kcal, 81g protein, 55g fiber | 2880 kcal, 66g protein, 36g fiber |
| **51-70 years** | 3960 kcal, 89g protein, 60g fiber | 3168 kcal, 73g protein, 40g fiber |
| **>70 years** | 4320 kcal, 97g protein, 66g fiber | 3456 kcal, 79g protein, 43g fiber |

## Key Benefits of This System

1. **Evidence-Based**: Uses official NIH DRI recommendations as baseline
2. **Personalized**: Adjusts for individual characteristics (gender, age, disease status)
3. **IBD-Specific**: Accounts for malabsorption and increased nutrient needs
4. **Scalable**: Easy to modify multipliers based on new research
5. **Comprehensive**: Covers both macronutrients and micronutrients

## Implementation Notes

- All calculations are performed in the `PersonalizedIBDTargets.calculate()` function
- Gender-specific DRI values are used as the foundation
- IBD patients receive a 20% baseline increase due to malabsorption
- Disease activity and age adjustments are additive to the IBD multiplier
- Final values are rounded to whole numbers for practical use
- The system maintains backward compatibility with existing nutrition analysis

## References

- NIH Office of Dietary Supplements: https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx
- Dietary Reference Intakes (DRI) Reports and Tables
- AGA Guidelines 2024 for IBD Nutrition
- Crohn's & Colitis Congress 2024 Nutrition Recommendations
