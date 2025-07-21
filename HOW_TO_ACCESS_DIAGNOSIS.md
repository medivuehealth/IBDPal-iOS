# How to Access MyDiagnosisScreen in IBDPal

## ✅ **The MyDiagnosisScreen is Now Available!**

The comprehensive diagnosis assessment screen has been successfully integrated into the IBDPal app. Here's how to access it:

## 🎯 **Access Points**

### **1. From Home Screen**
- Open the IBDPal app
- Go to the **Home** tab
- You'll see a prominent **"Complete Your Diagnosis Assessment"** card at the top
- Tap **"Start Assessment"** to begin

### **2. From More Screen**
- Open the IBDPal app
- Go to the **More** tab
- Scroll down to find **"My Diagnosis"** in the menu
- Tap on it to access the diagnosis assessment

## 📱 **What You'll See**

### **Step 1: Basic Diagnosis Information**
- Select your IBD diagnosis (Crohn's, UC, IBS, etc.)
- Choose when you were first diagnosed (year and month)
- Specify disease location and behavior
- Rate your disease severity

### **Step 2: Medication Information**
- Indicate if you're taking medications
- Select medication types (Biologics, Steroids, etc.)
- Report any medication complications

### **Step 3: Health Status**
- Answer if you're anemic and severity level
- Specify how often you see your GI specialist
- Indicate when you last visited your GI specialist

### **Step 4: Additional Information**
- Family history of IBD
- Surgery history
- Hospitalization count
- Flare frequency
- Current symptoms
- Dietary restrictions
- Other medical conditions

## 🔧 **Technical Implementation**

### **Navigation Structure**
```javascript
// App.js - Main navigation
<Stack.Screen 
  name="MyDiagnosis" 
  component={MyDiagnosisScreen}
  initialParams={{ authContext, userData }}
/>

// HomeScreen.js - Diagnosis card
<Button
  onPress={() => navigation.navigate('MyDiagnosis', { userData, authContext })}
>
  Start Assessment
</Button>

// MoreScreen.js - Menu item
<List.Item
  title="My Diagnosis"
  onPress={() => navigation.navigate('MyDiagnosis', { userData, authContext })}
/>
```

### **Data Flow**
1. User taps diagnosis assessment
2. Navigation passes `userData` and `authContext`
3. MyDiagnosisScreen loads with 4-step assessment
4. Data is saved to Medivue database via API
5. Success confirmation shown

## 🎨 **UI Features**

### **Progress Tracking**
- Visual progress bar
- Step counter (Step X of 4)
- Clear navigation buttons

### **Form Validation**
- Required field validation
- Error messages for missing data
- Cannot proceed without completing required fields

### **User Experience**
- Clean, intuitive interface
- Step-by-step guidance
- Success confirmation
- Error handling

## 📊 **Data Storage**

All diagnosis information is saved to the Medivue database in the `users` table:

```sql
-- Key fields updated
diagnosis_date
ibd_type
disease_location
disease_behavior
disease_activity
current_medications
comorbidities
family_history
hospitalizations_count
flare_frequency
```

## 🚀 **Getting Started**

1. **Launch the app** - Make sure you're logged in
2. **Navigate to Home** - Look for the diagnosis assessment card
3. **Start assessment** - Tap "Start Assessment"
4. **Complete all steps** - Fill out all required information
5. **Save data** - Tap "Save Diagnosis" at the end
6. **Confirm success** - You'll see a success message

## 🔍 **Troubleshooting**

### **If you don't see the diagnosis card:**
- Make sure you're logged in
- Check that you're on the Home tab
- Try refreshing the app

### **If navigation doesn't work:**
- Check that the app is properly installed
- Ensure you have the latest version
- Try restarting the app

### **If data doesn't save:**
- Check your internet connection
- Ensure the backend server is running
- Try again in a few minutes

## 📈 **Benefits**

- **Personalized Care**: Better treatment recommendations
- **Comprehensive Tracking**: Complete health history
- **Research Contribution**: Anonymized data for IBD research
- **Better Communication**: Improved provider-patient communication

The MyDiagnosisScreen is now fully integrated and ready to use! 🎉 