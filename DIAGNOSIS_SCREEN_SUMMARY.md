# IBDPal MyDiagnosisScreen Enhancement

## Overview
The MyDiagnosisScreen has been completely redesigned as a comprehensive one-time assessment that collects detailed IBD diagnosis information from users. This data is saved to the Medivue database and used for personalized care recommendations.

## Key Features

### 1. Multi-Step Assessment Process
- **Step 1**: Basic Diagnosis Information
- **Step 2**: Medication Information  
- **Step 3**: Health Status
- **Step 4**: Additional Information

### 2. Comprehensive Question Set

#### Step 1: Basic Diagnosis Information
- **IBD Diagnosis**: Crohn's Disease, Ulcerative Colitis, Indeterminate Colitis, Microscopic Colitis, IBS, Other IBD
- **Diagnosis Date**: Year and month of first diagnosis
- **Disease Location**: Small Intestine, Large Intestine, Colon, Rectum, Ileum, Multiple Locations, Unknown
- **Disease Behavior**: Inflammatory, Stricturing, Penetrating, Mixed, Unknown
- **Disease Severity**: Mild, Moderate, Severe, Varies

#### Step 2: Medication Information
- **Taking Medications**: Yes/No
- **Medication Types**: Biologics, Immunosuppressants, Steroids, 5-ASA, JAK Inhibitors, Antibiotics, Pain Medications, Other
- **Medication Complications**: Infections, Liver problems, Bone loss, Skin reactions, Fatigue, Nausea, Headaches, Joint pain, None

#### Step 3: Health Status
- **Anemia Status**: Yes/No with severity (Mild, Moderate, Severe)
- **GI Specialist Frequency**: Every 3 months, Every 6 months, Once a year, As needed, Don't see one
- **Last GI Visit**: Within last month, 1-3 months ago, 3-6 months ago, 6-12 months ago, More than a year ago, Never

#### Step 4: Additional Information
- **Family History**: Yes/No/Unknown
- **Surgery History**: Yes/No
- **Hospitalizations**: Number of IBD-related hospitalizations
- **Flare Frequency**: Never, Rarely, Occasionally, Frequently, Very frequently
- **Current Symptoms**: Abdominal Pain, Diarrhea, Constipation, Blood in Stool, Fatigue, Weight Loss, Fever, Joint Pain, Skin Problems, Eye Problems, Nausea, Loss of Appetite, Bloating, Urgency
- **Dietary Restrictions**: Gluten-free, Dairy-free, Low FODMAP, Low fiber, Low fat, No raw vegetables, No spicy foods, No caffeine, No alcohol, Other
- **Comorbidities**: Arthritis, Diabetes, Hypertension, Asthma, Depression/Anxiety, Osteoporosis, Liver disease, Kidney disease, Heart disease, Cancer, None

## Technical Implementation

### Frontend (React Native)
- **File**: `IBDPal/src/screens/MyDiagnosisScreen.js`
- **State Management**: Comprehensive state for all form fields
- **Validation**: Step-by-step validation with error messages
- **UI Components**: 
  - Progress indicator
  - Radio buttons for Yes/No questions
  - Pickers for dropdown selections
  - Chips for multi-select items
  - Text inputs for numeric data

### Backend (Node.js/Express)
- **File**: `IBDPal/server/routes/users.js`
- **Endpoints**:
  - `POST /api/users/diagnosis` - Save diagnosis data
  - `GET /api/users/diagnosis` - Retrieve diagnosis data
- **Database**: Updates existing users table with diagnosis fields

### Database Schema
The diagnosis data is stored in the existing `users` table with the following fields:
- `diagnosis_date` - Date of diagnosis
- `ibd_type` - Type of IBD
- `disease_location` - Location of disease
- `disease_behavior` - Behavior pattern
- `disease_activity` - Current activity level
- `current_medications` - Comma-separated medication list
- `allergies` - Used to store medication complications
- `comorbidities` - Other medical conditions
- `family_history` - Family history of IBD
- `hospitalizations_count` - Number of hospitalizations
- `flare_frequency` - Frequency of flares

## User Experience

### Progress Tracking
- Visual progress bar showing completion percentage
- Step counter (Step X of 4)
- Clear navigation between steps

### Validation
- Required field validation at each step
- Error modals with specific messages
- Cannot proceed without completing required fields

### Data Persistence
- All data is saved to the database upon completion
- Success modal confirms data was saved
- Users can update information later from the More tab

## Additional IBD Questions Included

Beyond the requested questions, the enhanced screen includes:

1. **Disease Behavior**: Important for treatment planning
2. **Current Symptoms**: For ongoing monitoring
3. **Dietary Restrictions**: For nutrition recommendations
4. **Comorbidities**: For comprehensive care planning
5. **Surgery History**: For treatment history
6. **Flare Frequency**: For disease activity assessment
7. **Family History**: For genetic risk assessment

## Benefits

### For Users
- Comprehensive health assessment
- Personalized care recommendations
- Better tracking of disease progression
- Improved communication with healthcare providers

### For Healthcare Providers
- Complete patient history
- Better treatment planning
- Risk assessment data
- Longitudinal disease tracking

### For Research
- Anonymized data for IBD research
- Population health insights
- Treatment effectiveness studies
- Disease progression patterns

## Testing

A test script (`test_diagnosis_endpoint.js`) is included to verify:
- POST endpoint functionality
- GET endpoint functionality
- Data validation
- Error handling

## Future Enhancements

1. **Integration with EHR systems**
2. **Automated recommendations based on diagnosis**
3. **Risk assessment algorithms**
4. **Treatment effectiveness tracking**
5. **Research data contribution (with consent)**

## Security & Privacy

- All data is encrypted in transit
- User authentication required
- HIPAA-compliant data handling
- User consent for data sharing
- Anonymized research data

This enhanced diagnosis screen provides a comprehensive foundation for personalized IBD care and management. 