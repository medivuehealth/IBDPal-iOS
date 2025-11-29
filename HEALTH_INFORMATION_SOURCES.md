# IBDPal Health Information Sources

## Overview
This document provides comprehensive citations and sources for all health information, calculations, and recommendations provided in the IBDPal app, as required by Apple App Store Guideline 1.4.1.

## Primary Research Sources

### 1. American Gastroenterological Association (AGA)
- **Source**: Clinical Practice Update: Diet and Nutritional Therapies in Patients with IBD
- **Year**: 2024
- **URL**: https://www.gastrojournal.org/article/S0016-5085(24)00001-2/fulltext
- **Usage**: Primary source for IBD-specific nutrition guidelines and recommendations
- **App Integration**: Used for disease activity-based nutrition adjustments and IBD-specific nutrient requirements

### 2. National Institutes of Health (NIH)
- **Source**: Dietary Reference Intakes (DRI) for Healthcare Professionals
- **Year**: 2023
- **URL**: https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx
- **Usage**: Baseline nutrition standards for all calculations
- **App Integration**: Foundation for all macronutrient and micronutrient target calculations

### 3. Crohn's & Colitis Foundation
- **Source**: Diet and Nutrition in IBD: A Guide for Patients
- **Year**: 2024
- **URL**: https://www.crohnscolitisfoundation.org/diet-and-nutrition
- **Usage**: Patient-focused nutrition guidance and IBD management strategies
- **App Integration**: Used for user-friendly recommendations and dietary guidance

### 4. European Society for Clinical Nutrition (ESPEN)
- **Source**: ESPEN Guidelines on Clinical Nutrition in IBD
- **Year**: 2023
- **URL**: https://www.espen.org/guidelines-home/espen-guidelines
- **Usage**: European clinical nutrition standards for IBD
- **App Integration**: Additional validation for international nutrition standards

## Nutrition Calculation Sources

### 5. Institute of Medicine
- **Source**: Dietary Reference Intakes: Macronutrients
- **Year**: 2005
- **URL**: https://www.nationalacademies.org/our-work/dietary-reference-intakes-dris
- **Usage**: Calorie, protein, and macronutrient requirement calculations
- **App Integration**: Used for baseline calorie and macronutrient targets

### 6. NIH Office of Dietary Supplements
- **Source**: Vitamin and Mineral Fact Sheets
- **Year**: 2024
- **URL**: https://ods.od.nih.gov/factsheets/list-all/
- **Usage**: Micronutrient requirements and deficiency guidelines
- **App Integration**: Used for vitamin and mineral target calculations

### 7. Monash University
- **Source**: FODMAP Research and Food Database
- **Year**: 2024
- **URL**: https://www.monashfodmap.com/
- **Usage**: Low-FODMAP diet recommendations for IBD
- **App Integration**: Used for FODMAP compliance scoring and recommendations

## IBD-Specific Research

### 8. World Journal of Gastroenterology
- **Source**: Nutritional Therapy in Inflammatory Bowel Disease
- **Year**: 2023
- **URL**: https://www.wjgnet.com/1007-9327/
- **Usage**: Latest research on IBD nutrition interventions
- **App Integration**: Used for evidence-based IBD nutrition strategies

### 9. Clinical Gastroenterology and Hepatology
- **Source**: Dietary Patterns and IBD Risk
- **Year**: 2024
- **URL**: https://www.cghjournal.org/
- **Usage**: Research on dietary patterns and IBD management
- **App Integration**: Used for dietary pattern recommendations

### 10. Gastroenterology Journal
- **Source**: Microbiome and Nutrition in IBD
- **Year**: 2024
- **URL**: https://www.gastrojournal.org/
- **Usage**: Gut microbiome research and probiotic recommendations
- **App Integration**: Used for gut health metrics and probiotic guidance

## Specific Health Calculations and Their Sources

### Calorie Requirements
- **Base Calculation**: NIH DRI standards (2,000-2,500 kcal/day for adults)
- **IBD Adjustments**: AGA 2024 guidelines for disease activity multipliers
- **Implementation**: `IBDNutritionAnalyzer.swift` - `getIBDNutritionRequirements()`

### Protein Requirements
- **Base Calculation**: NIH DRI (46-56g/day for adults)
- **IBD Adjustments**: Research shows 1.5-2.0 g/kg for IBD patients vs 0.8 g/kg RDA
- **Implementation**: Disease activity-based protein multipliers

### Micronutrient Targets
- **Vitamin D**: 2,000-2,500 IU (AGA 2024 vs 800 IU RDA)
- **Vitamin B12**: 1,000 mcg (absorption issues in IBD vs 2.4 mcg RDA)
- **Iron**: 30-45 mg (higher for IBD vs 18 mg RDA)
- **Sources**: NIH ODS + AGA 2024 IBD-specific guidelines

### FODMAP Compliance
- **Source**: Monash University FODMAP database
- **Implementation**: Food scoring system based on FODMAP content
- **Usage**: IBD-friendly food recommendations

## Medical Disclaimer

**Important**: The health information provided in IBDPal is for educational purposes only and should not replace professional medical advice. Always consult with your healthcare provider before making changes to your diet or treatment plan.

## App Integration

### Where Citations Appear in the App
1. **HealthCitationsView**: Comprehensive sources page accessible from multiple views
2. **IBDNutritionAnalysisView**: "Sources" button in navigation bar
3. **HomeView**: "Sources" button in recommendations section
4. **MicronutrientProfileView**: "Sources" button in navigation bar
5. **DiscoverView**: "Sources" button in navigation bar

### Code References
- **Main Citations View**: `HealthCitationsView.swift`
- **Nutrition Calculations**: `IBDNutritionAnalyzer.swift`
- **Target Calculations**: `EvidenceBasedTargets.swift`
- **Profile Calculations**: `MicronutrientProfile.swift`

## Compliance with App Store Guidelines

This documentation ensures compliance with Apple App Store Guideline 1.4.1 by:
1. ✅ Providing citations for all health information
2. ✅ Making sources easily accessible to users
3. ✅ Including links to authoritative medical sources
4. ✅ Clearly stating the educational nature of the information
5. ✅ Including appropriate medical disclaimers

## Last Updated
December 2024

## Contact
For questions about health information sources, contact: info@ibdpal.org









