# IBDPal Nutrition Targets: Dietician's Guide

## Overview

IBDPal uses an evidence-based, AI-powered system to calculate personalized nutrition targets for IBD patients. This guide explains the scientific foundation, calculation methodology, and clinical rationale behind our nutrition recommendations.

## Scientific Foundation

### Primary References
- **NIH Dietary Reference Intakes (DRI)** - Baseline nutrition standards
- **AGA Clinical Practice Update (2024)** - IBD-specific nutrition guidelines
- **Crohn's & Colitis Congress (2024)** - Latest research on IBD nutrition
- **Evidence-based Medicine** - Peer-reviewed research and clinical studies

### Key Principles
1. **Personalization**: Targets adapt to individual patient profiles
2. **Disease Activity**: Nutrition needs increase during flares
3. **Malabsorption Compensation**: Higher targets for IBD patients
4. **Age-Appropriate**: Pediatric, adult, and geriatric considerations
5. **Gender-Specific**: Male vs. female baseline requirements

## Calculation Methodology

### 1. Base Target Selection (NIH DRI)

#### Macronutrients (Daily)
| Nutrient | Male (19-50 years) | Female (19-50 years) | Unit |
|----------|-------------------|---------------------|------|
| Calories | 2500 | 2000 | kcal/day |
| Protein | 56 | 46 | g/day |
| Fiber | 38 | 25 | g/day |
| Hydration | 3700 | 2700 | ml/day |
| Fat | 30% of calories | 30% of calories | % |
| Carbs | Remaining calories | Remaining calories | g/day |

#### Micronutrients (Daily RDA/AI)
| Nutrient | Male (19-50 years) | Female (19-50 years) | Unit |
|----------|-------------------|---------------------|------|
| Vitamin D | 600 | 600 | IU |
| Vitamin B12 | 2.4 | 2.4 | mcg |
| Iron | 8 | 18 | mg |
| Folate | 400 | 400 | mcg DFE |
| Calcium | 1000 | 1000 | mg |
| Zinc | 11 | 8 | mg |
| Omega-3 | 1100 | 1100 | mg |

### 2. Multiplier System

#### Disease Activity Multipliers
- **Remission**: 1.0x (no adjustment)
- **Mild**: 1.1x (10% increase)
- **Moderate**: 1.3x (30% increase)
- **Severe**: 1.5x (50% increase)

#### Age Multipliers
- **< 18 years**: 1.2x (20% increase for growth)
- **18-65 years**: 1.0x (no adjustment)
- **> 65 years**: 0.8x (20% decrease for aging)

#### Disease Type Multipliers
- **IBD patients**: 1.2x (20% increase for malabsorption)
- **Normal people**: 1.0x (no adjustment)

### 3. Final Calculation Formula

```
Total Multiplier = Disease Activity × Age × Disease Type
Final Target = Base DRI × Total Multiplier
```

## IBD-Specific Adjustments

### Macronutrient Considerations

#### Calories
- **Base**: NIH DRI (2000-2500 kcal)
- **IBD Adjustment**: +20% for malabsorption
- **Flare Adjustment**: +10-50% during active disease
- **Rationale**: IBD patients need extra calories due to malabsorption and inflammation

#### Protein
- **Base**: NIH DRI (46-56g)
- **IBD Adjustment**: 1.5-2.0 g/kg body weight
- **Rationale**: Higher protein needs for healing and muscle preservation

#### Fiber
- **Base**: NIH DRI (25-38g)
- **IBD Adjustment**: Symptom-dependent
- **Rationale**: Adjust based on strictures, diarrhea, and tolerance

#### Hydration
- **Base**: NIH DRI (2700-3700ml)
- **IBD Adjustment**: +20-50% during flares
- **Rationale**: Increased fluid losses during diarrhea and inflammation

### Micronutrient Considerations

#### Vitamin D
- **Base**: NIH DRI (600 IU)
- **IBD Adjustment**: 2000-4000 IU
- **Rationale**: IBD patients have higher deficiency rates and absorption issues

#### Vitamin B12
- **Base**: NIH DRI (2.4 mcg)
- **IBD Adjustment**: 1000-2000 mcg
- **Rationale**: Terminal ileum involvement affects absorption

#### Iron
- **Base**: NIH DRI (8-18 mg)
- **IBD Adjustment**: 30-65 mg
- **Rationale**: Blood loss and malabsorption increase needs

#### Folate
- **Base**: NIH DRI (400 mcg)
- **IBD Adjustment**: 600-800 mcg
- **Rationale**: Medication interactions (methotrexate, sulfasalazine)

#### Calcium
- **Base**: NIH DRI (1000 mg)
- **IBD Adjustment**: 1200-1500 mg
- **Rationale**: Bone health, steroid use, malabsorption

## AI-Powered Disease Activity Assessment

### How It Works
1. **Data Collection**: Analyzes 30 days of symptom data
2. **Weighted Scoring**: Assigns weights based on symptom severity
3. **Trend Analysis**: Identifies patterns and changes over time
4. **Confidence Scoring**: Provides assessment reliability metrics

### Symptom Weighting System
- **Critical Symptoms** (2.0x weight): Blood present, severe pain
- **Severe Symptoms** (1.5x weight): High pain, urgency
- **Moderate Symptoms** (1.0x weight): Moderate symptoms
- **Mild Symptoms** (0.5x weight): Mild symptoms
- **Secondary Indicators** (0.3x weight): Stress, fatigue, sleep quality

### Assessment Categories
- **Remission**: Minimal symptoms, stable condition
- **Mild**: Occasional symptoms, manageable
- **Moderate**: Regular symptoms, some impact on daily life
- **Severe**: Frequent symptoms, significant impact

## Example Calculations

### Case Study: 30-year-old Female, Crohn's Disease, Severe Activity

#### Base DRI Values
- Calories: 2000 kcal
- Protein: 46g
- Vitamin D: 600 IU
- Iron: 18 mg

#### Multipliers Applied
- Disease Activity: 1.5x (severe)
- Age: 1.0x (adult)
- Disease Type: 1.2x (IBD)
- **Total Multiplier**: 1.5 × 1.0 × 1.2 = 1.8x

#### Final Targets
- Calories: 2000 × 1.8 = **3600 kcal**
- Protein: 46 × 1.8 = **83g**
- Vitamin D: 600 × 1.8 = **1080 IU**
- Iron: 18 × 1.8 = **32 mg**

### Case Study: 65-year-old Male, Ulcerative Colitis, Mild Activity

#### Base DRI Values
- Calories: 2500 kcal
- Protein: 56g
- Vitamin D: 600 IU
- Iron: 8 mg

#### Multipliers Applied
- Disease Activity: 1.1x (mild)
- Age: 0.8x (geriatric)
- Disease Type: 1.1x (UC)
- **Total Multiplier**: 1.1 × 0.8 × 1.1 = 0.97x

#### Final Targets
- Calories: 2500 × 0.97 = **2425 kcal**
- Protein: 56 × 0.97 = **54g**
- Vitamin D: 600 × 0.97 = **582 IU**
- Iron: 8 × 0.97 = **8 mg**

## Clinical Considerations

### Monitoring and Adjustments
1. **Regular Assessment**: Disease activity changes over time
2. **Symptom Tracking**: Continuous monitoring of patient symptoms
3. **Lab Values**: Regular blood work to monitor nutrient levels
4. **Patient Feedback**: Adjust targets based on tolerance and preferences

### Special Populations
- **Pediatric Patients**: Higher calorie and protein needs for growth
- **Geriatric Patients**: Lower calorie needs, higher micronutrient density
- **Pregnant Women**: Additional folate and iron requirements
- **Athletes**: Higher calorie and protein needs

### Contraindications and Considerations
- **Strictures**: May require lower fiber targets
- **Short Bowel Syndrome**: Higher calorie and fluid needs
- **Steroid Use**: Higher calcium and vitamin D requirements
- **Surgery**: Increased protein needs for healing

## Quality Assurance

### Validation Methods
1. **Clinical Guidelines**: Aligned with AGA and NIH recommendations
2. **Research Evidence**: Based on peer-reviewed studies
3. **Expert Review**: Validated by IBD specialists and dieticians
4. **Patient Outcomes**: Monitored for effectiveness and safety

### Continuous Improvement
- **Data Analysis**: Regular review of patient outcomes
- **Research Updates**: Incorporation of new evidence
- **Algorithm Refinement**: Ongoing optimization of calculations
- **Feedback Integration**: Patient and provider input

## Conclusion

IBDPal's nutrition target system provides evidence-based, personalized recommendations that adapt to each patient's unique needs. The AI-powered disease activity assessment ensures targets remain relevant as patients' conditions change, while the multiplier system accounts for the complex nutritional needs of IBD patients.

This system empowers patients with accurate, personalized nutrition guidance while providing healthcare providers with a reliable tool for monitoring and adjusting nutrition plans.

---

*For technical questions or algorithm details, please contact the development team.*
*For clinical questions, please consult with IBD specialists and registered dieticians.*
