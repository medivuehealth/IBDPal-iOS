const express = require('express');
const router = express.Router();
const db = require('../database/db');

// POST /api/journal/entries - Create a new journal entry
router.post('/entries', async (req, res) => {
    try {
        // Get the journal entry data
        const journalData = req.body;
        
        console.log('Server received journal entry data:', {
            medication_taken: journalData.medication_taken,
            medication_type: journalData.medication_type,
            dosage_level: journalData.dosage_level,
            typeOfDosage: typeof journalData.dosage_level,
            rawData: JSON.stringify(journalData)
        });

        // Check if an entry already exists for this user and date
        const existingEntryQuery = `
            SELECT entry_id FROM journal_entries 
            WHERE user_id = $1 AND entry_date = $2
        `;
        const existingResult = await db.query(existingEntryQuery, [journalData.user_id, journalData.entry_date]);
        
        if (existingResult.rows.length > 0) {
            // Update existing entry
            const entryId = existingResult.rows[0].entry_id;
            return await updateJournalEntry(entryId, journalData, res);
        } else {
            // Create new entry with proper defaults
            return await createJournalEntry(journalData, res);
        }

    } catch (error) {
        console.error('Error saving journal entry:', error);
        res.status(500).json({
            error: 'Failed to save journal entry',
            details: error.message
        });
    }
});

// Helper function to create a new journal entry
async function createJournalEntry(journalData, res) {
    // Insert journal entry with proper defaults for constraints
    const journalQuery = `
        INSERT INTO journal_entries (
            user_id, entry_date, calories, protein, carbs, fiber,
            has_allergens, meals_per_day, hydration_level, bowel_frequency,
            bristol_scale, urgency_level, blood_present, pain_location,
            pain_severity, pain_time, medication_taken, medication_type,
            dosage_level, sleep_hours, stress_level, menstruation,
            fatigue_level, notes, breakfast, lunch, dinner, snacks,
            breakfast_calories, breakfast_protein, breakfast_carbs, breakfast_fiber, breakfast_fat,
            lunch_calories, lunch_protein, lunch_carbs, lunch_fiber, lunch_fat,
            dinner_calories, dinner_protein, dinner_carbs, dinner_fiber, dinner_fat,
            snack_calories, snack_protein, snack_carbs, snack_fiber, snack_fat
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14,
                $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29,
                $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45)
        RETURNING entry_id;
    `;

    const journalValues = [
        journalData.user_id,
        journalData.entry_date,
        journalData.calories || 0,
        journalData.protein || 0,
        journalData.carbs || 0,
        journalData.fiber || 0,
        journalData.has_allergens || false,
        journalData.meals_per_day || 0,
        journalData.hydration_level || 0,
        journalData.bowel_frequency || 0,
        // Bristol scale must be 1-7, default to 4 if 0 or invalid
        (journalData.bristol_scale && journalData.bristol_scale >= 1 && journalData.bristol_scale <= 7) ? journalData.bristol_scale : 4,
        journalData.urgency_level || 0,
        journalData.blood_present || false,
        // Pain location must be one of the valid values, default to 'None' if empty/invalid
        (journalData.pain_location && ['None', 'full_abdomen', 'lower_abdomen', 'upper_abdomen'].includes(journalData.pain_location)) ? journalData.pain_location : 'None',
        journalData.pain_severity || 0,
        // Pain time must be one of the valid values, default to 'None' if empty/invalid
        (journalData.pain_time && ['None', 'morning', 'afternoon', 'evening', 'night', 'variable'].includes(journalData.pain_time)) ? journalData.pain_time : 'None',
        journalData.medication_taken || false,
        // Medication type must be one of the valid values, default to 'None' if empty/invalid
        (journalData.medication_type && ['None', 'biologic', 'immunosuppressant', 'steroid'].includes(journalData.medication_type)) ? journalData.medication_type : 'None',
        // Dosage level must be text and match medication type constraints
        (() => {
            let validDosage = '0'; // default for 'None' medication type
            const medicationType = journalData.medication_type || 'None';
            
            if (medicationType === 'biologic') {
                validDosage = (journalData.dosage_level && ['every_2_weeks', 'every_4_weeks', 'every_8_weeks'].includes(journalData.dosage_level)) ? journalData.dosage_level : 'every_4_weeks';
            } else if (medicationType === 'immunosuppressant') {
                validDosage = (journalData.dosage_level && ['daily', 'twice_daily', 'weekly'].includes(journalData.dosage_level)) ? journalData.dosage_level : 'daily';
            } else if (medicationType === 'steroid') {
                validDosage = (journalData.dosage_level && ['5', '10', '20'].includes(journalData.dosage_level)) ? journalData.dosage_level : '5';
            } else {
                // For 'None' or any other medication type, use '0'
                validDosage = '0';
            }
            return validDosage;
        })(),
        journalData.sleep_hours || 0,
        journalData.stress_level || 0,
        journalData.menstruation || 'not_applicable',
        journalData.fatigue_level || 0,
        journalData.notes || '',
        journalData.breakfast || '',
        journalData.lunch || '',
        journalData.dinner || '',
        journalData.snacks || '',
        // Individual meal nutrition
        journalData.breakfast_calories || 0,
        journalData.breakfast_protein || 0,
        journalData.breakfast_carbs || 0,
        journalData.breakfast_fiber || 0,
        journalData.breakfast_fat || 0,
        journalData.lunch_calories || 0,
        journalData.lunch_protein || 0,
        journalData.lunch_carbs || 0,
        journalData.lunch_fiber || 0,
        journalData.lunch_fat || 0,
        journalData.dinner_calories || 0,
        journalData.dinner_protein || 0,
        journalData.dinner_carbs || 0,
        journalData.dinner_fiber || 0,
        journalData.dinner_fat || 0,
        journalData.snack_calories || 0,
        journalData.snack_protein || 0,
        journalData.snack_carbs || 0,
        journalData.snack_fiber || 0,
        journalData.snack_fat || 0
    ];

    console.log('Executing journal entry query with values:', journalValues);
    const journalResult = await db.query(journalQuery, journalValues);
    const entryId = journalResult.rows[0].entry_id;

    res.json({
        message: 'Journal entry saved successfully',
        entry_id: entryId
    });
}

// Helper function to update an existing journal entry
async function updateJournalEntry(entryId, journalData, res) {
    // Build dynamic update query based on what fields are provided
    let updateFields = [];
    let updateValues = [];
    let paramCount = 1;

            // Only update fields that are provided (not undefined/null)
        const fieldsToUpdate = {
            'calories': journalData.calories,
            'protein': journalData.protein,
            'carbs': journalData.carbs,
            'fiber': journalData.fiber,
            'has_allergens': journalData.has_allergens,
            'meals_per_day': journalData.meals_per_day,
            'hydration_level': journalData.hydration_level,
            'bowel_frequency': journalData.bowel_frequency,
            'bristol_scale': journalData.bristol_scale,
            'urgency_level': journalData.urgency_level,
            'blood_present': journalData.blood_present,
            'pain_location': journalData.pain_location,
            'pain_severity': journalData.pain_severity,
            'pain_time': journalData.pain_time,
            'medication_taken': journalData.medication_taken,
            'medication_type': journalData.medication_type,
            'dosage_level': journalData.dosage_level,
            'sleep_hours': journalData.sleep_hours,
            'stress_level': journalData.stress_level,
            'menstruation': journalData.menstruation,
            'fatigue_level': journalData.fatigue_level,
            'notes': journalData.notes,
            'breakfast': journalData.breakfast,
            'lunch': journalData.lunch,
            'dinner': journalData.dinner,
            'snacks': journalData.snacks,
            // Individual meal nutrition
            'breakfast_calories': journalData.breakfast_calories,
            'breakfast_protein': journalData.breakfast_protein,
            'breakfast_carbs': journalData.breakfast_carbs,
            'breakfast_fiber': journalData.breakfast_fiber,
            'breakfast_fat': journalData.breakfast_fat,
            'lunch_calories': journalData.lunch_calories,
            'lunch_protein': journalData.lunch_protein,
            'lunch_carbs': journalData.lunch_carbs,
            'lunch_fiber': journalData.lunch_fiber,
            'lunch_fat': journalData.lunch_fat,
            'dinner_calories': journalData.dinner_calories,
            'dinner_protein': journalData.dinner_protein,
            'dinner_carbs': journalData.dinner_carbs,
            'dinner_fiber': journalData.dinner_fiber,
            'dinner_fat': journalData.dinner_fat,
            'snack_calories': journalData.snack_calories,
            'snack_protein': journalData.snack_protein,
            'snack_carbs': journalData.snack_carbs,
            'snack_fiber': journalData.snack_fiber,
            'snack_fat': journalData.snack_fat
        };

    Object.entries(fieldsToUpdate).forEach(([field, value]) => {
        if (value !== undefined && value !== null) {
            updateFields.push(`${field} = $${paramCount}`);
            
            // Handle special cases for constraints
            if (field === 'bristol_scale') {
                // Bristol scale must be 1-7, default to 4 if 0 or invalid
                updateValues.push((value && value >= 1 && value <= 7) ? value : 4);
            } else if (field === 'menstruation') {
                // Ensure valid menstruation value
                updateValues.push(value || 'not_applicable');
            } else if (field === 'medication_type') {
                // Medication type must be one of the valid values, default to 'None' if empty/invalid
                updateValues.push((value && ['None', 'biologic', 'immunosuppressant', 'steroid'].includes(value)) ? value : 'None');
            } else if (field === 'pain_location') {
                // Pain location must be one of the valid values, default to 'None' if empty/invalid
                updateValues.push((value && ['None', 'full_abdomen', 'lower_abdomen', 'upper_abdomen'].includes(value)) ? value : 'None');
            } else if (field === 'pain_time') {
                // Pain time must be one of the valid values, default to 'None' if empty/invalid
                updateValues.push((value && ['None', 'morning', 'afternoon', 'evening', 'night', 'variable'].includes(value)) ? value : 'None');
            } else if (field === 'dosage_level') {
                // Dosage level must be text and match medication type constraints
                let validDosage = '0'; // default for 'None' medication type
                const medicationType = journalData.medication_type || 'None';
                
                if (medicationType === 'biologic') {
                    validDosage = (value && ['every_2_weeks', 'every_4_weeks', 'every_8_weeks'].includes(value)) ? value : 'every_4_weeks';
                } else if (medicationType === 'immunosuppressant') {
                    validDosage = (value && ['daily', 'twice_daily', 'weekly'].includes(value)) ? value : 'daily';
                } else if (medicationType === 'steroid') {
                    validDosage = (value && ['5', '10', '20'].includes(value)) ? value : '5';
                } else {
                    // For 'None' or any other medication type, use '0'
                    validDosage = '0';
                }
                updateValues.push(validDosage);
            } else {
                updateValues.push(value);
            }
            paramCount++;
        }
    });

    if (updateFields.length === 0) {
        return res.json({
            message: 'No fields to update',
            entry_id: entryId
        });
    }

    // Add updated_at timestamp
    updateFields.push(`updated_at = NOW()`);
    
    // Add entry_id for WHERE clause
    updateValues.push(entryId);

    const updateQuery = `
        UPDATE journal_entries SET
            ${updateFields.join(', ')}
        WHERE entry_id = $${paramCount}
        RETURNING entry_id;
    `;

    console.log('Executing journal entry update query:', updateQuery);
    console.log('Update values:', updateValues);
    
    const updateResult = await db.query(updateQuery, updateValues);
    
    if (updateResult.rows.length === 0) {
        throw new Error('Entry not found or unauthorized');
    }

    res.json({
        message: 'Journal entry updated successfully',
        entry_id: entryId
    });
}

// GET /api/journal/entries/:userId - Get all journal entries for a user
router.get('/entries/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        
        // Get journal entries
        const query = `
            SELECT * FROM journal_entries 
            WHERE user_id = $1 
            ORDER BY entry_date DESC, created_at DESC
        `;
        
        const result = await db.query(query, [userId]);
        res.json(result.rows);
    } catch (error) {
        console.error('Error fetching journal entries:', error);
        res.status(500).json({ error: 'Failed to fetch journal entries', details: error.message });
    }
});

// PUT /api/journal/entries/:entryId - Update an existing journal entry
router.put('/entries/:entryId', async (req, res) => {
    try {
        const { entryId } = req.params;
        const journalData = req.body;
        
        console.log('Server received journal update data for entry:', entryId, {
            medication_taken: journalData.medication_taken,
            medication_type: journalData.medication_type,
            dosage_level: journalData.dosage_level,
            typeOfDosage: typeof journalData.dosage_level,
            rawData: JSON.stringify(journalData)
        });

        // Use the same logic as updateJournalEntry - only update fields that are provided
        let updateFields = [];
        let updateValues = [];
        let paramCount = 1;

        // Only update fields that are provided (not undefined/null)
        const fieldsToUpdate = {
            'entry_date': journalData.entry_date,
            'calories': journalData.calories,
            'protein': journalData.protein,
            'carbs': journalData.carbs,
            'fiber': journalData.fiber,
            'has_allergens': journalData.has_allergens,
            'meals_per_day': journalData.meals_per_day,
            'hydration_level': journalData.hydration_level,
            'breakfast': journalData.breakfast,
            'lunch': journalData.lunch,
            'dinner': journalData.dinner,
            'snacks': journalData.snacks,
            'bowel_frequency': journalData.bowel_frequency,
            'bristol_scale': journalData.bristol_scale,
            'urgency_level': journalData.urgency_level,
            'blood_present': journalData.blood_present,
            'pain_location': journalData.pain_location,
            'pain_severity': journalData.pain_severity,
            'pain_time': journalData.pain_time,
            'medication_taken': journalData.medication_taken,
            'medication_type': journalData.medication_type,
            'dosage_level': journalData.dosage_level,
            'sleep_hours': journalData.sleep_hours,
            'stress_level': journalData.stress_level,
            'menstruation': journalData.menstruation,
            'fatigue_level': journalData.fatigue_level,
            'notes': journalData.notes,
            // Individual meal nutrition
            'breakfast_calories': journalData.breakfast_calories,
            'breakfast_protein': journalData.breakfast_protein,
            'breakfast_carbs': journalData.breakfast_carbs,
            'breakfast_fiber': journalData.breakfast_fiber,
            'breakfast_fat': journalData.breakfast_fat,
            'lunch_calories': journalData.lunch_calories,
            'lunch_protein': journalData.lunch_protein,
            'lunch_carbs': journalData.lunch_carbs,
            'lunch_fiber': journalData.lunch_fiber,
            'lunch_fat': journalData.lunch_fat,
            'dinner_calories': journalData.dinner_calories,
            'dinner_protein': journalData.dinner_protein,
            'dinner_carbs': journalData.dinner_carbs,
            'dinner_fiber': journalData.dinner_fiber,
            'dinner_fat': journalData.dinner_fat,
            'snack_calories': journalData.snack_calories,
            'snack_protein': journalData.snack_protein,
            'snack_carbs': journalData.snack_carbs,
            'snack_fiber': journalData.snack_fiber,
            'snack_fat': journalData.snack_fat
        };

        Object.entries(fieldsToUpdate).forEach(([field, value]) => {
            if (value !== undefined && value !== null) {
                updateFields.push(`${field} = $${paramCount}`);
                
                // Handle special cases for constraints
                if (field === 'bristol_scale') {
                    // Bristol scale must be 1-7, default to 4 if 0 or invalid
                    updateValues.push((value && value >= 1 && value <= 7) ? value : 4);
                } else if (field === 'menstruation') {
                    // Ensure valid menstruation value
                    updateValues.push(value || 'not_applicable');
                } else if (field === 'medication_type') {
                    // Medication type must be one of the valid values, default to 'None' if empty/invalid
                    updateValues.push((value && ['None', 'biologic', 'immunosuppressant', 'steroid'].includes(value)) ? value : 'None');
                } else if (field === 'pain_location') {
                    // Pain location must be one of the valid values, default to 'None' if empty/invalid
                    updateValues.push((value && ['None', 'full_abdomen', 'lower_abdomen', 'upper_abdomen'].includes(value)) ? value : 'None');
                } else if (field === 'pain_time') {
                    // Pain time must be one of the valid values, default to 'None' if empty/invalid
                    updateValues.push((value && ['None', 'morning', 'afternoon', 'evening', 'night', 'variable'].includes(value)) ? value : 'None');
                } else if (field === 'dosage_level') {
                    // Dosage level must be text and match medication type constraints
                    let validDosage = '0'; // default for 'None' medication type
                    
                    if (journalData.medication_type === 'biologic') {
                        validDosage = (value && ['every_2_weeks', 'every_4_weeks', 'every_8_weeks'].includes(value)) ? value : 'every_4_weeks';
                    } else if (journalData.medication_type === 'immunosuppressant') {
                        validDosage = (value && ['daily', 'twice_daily', 'weekly'].includes(value)) ? value : 'daily';
                    } else if (journalData.medication_type === 'steroid') {
                        validDosage = (value && ['5', '10', '20'].includes(value)) ? value : '5';
                    } else {
                        // For 'None' or any other medication type, use '0'
                        validDosage = '0';
                    }
                    updateValues.push(validDosage);
                } else {
                    updateValues.push(value);
                }
                paramCount++;
            }
        });

        if (updateFields.length === 0) {
            return res.json({
                message: 'No fields to update',
                entry_id: entryId
            });
        }

        // Add updated_at timestamp
        updateFields.push(`updated_at = NOW()`);
        
        // Add entry_id and user_id for WHERE clause
        updateValues.push(entryId);
        updateValues.push(journalData.user_id);

        const updateQuery = `
            UPDATE journal_entries SET
                ${updateFields.join(', ')}
            WHERE entry_id = $${paramCount} AND user_id = $${paramCount + 1}
            RETURNING entry_id;
        `;

        console.log('Executing journal entry update query:', updateQuery);
        console.log('Update values:', updateValues);
        
        const updateResult = await db.query(updateQuery, updateValues);
        
        if (updateResult.rows.length === 0) {
            throw new Error('Entry not found or unauthorized');
        }

        res.json({
            message: 'Journal entry updated successfully',
            entry_id: entryId
        });

    } catch (error) {
        console.error('Error updating journal entry:', error);
        res.status(500).json({
            error: 'Failed to update journal entry',
            details: error.message
        });
    }
});

// GET /api/flare-statistics - Get flare prediction statistics
router.get('/flare-statistics', async (req, res) => {
    try {
        const { user_id, days = 30 } = req.query;
        
        if (!user_id) {
            return res.status(400).json({ error: 'user_id is required' });
        }

        // For now, return mock data since we don't have flare predictions set up
        res.json({
            total_predictions: 0,
            total_flares: 0,
            avg_flare_probability: 0,
            highest_risk: 0
        });
    } catch (error) {
        console.error('Error fetching flare statistics:', error);
        res.status(500).json({ 
            error: 'Failed to fetch flare statistics',
            details: error.message 
        });
    }
});

// GET /api/recent-predictions - Get recent flare predictions
router.get('/recent-predictions', async (req, res) => {
    try {
        const { user_id, limit = 30 } = req.query;
        
        if (!user_id) {
            return res.status(400).json({ error: 'user_id is required' });
        }

        // For now, return mock data since we don't have flare predictions set up
        res.json({
            predictions: []
        });
    } catch (error) {
        console.error('Error fetching recent predictions:', error);
        res.status(500).json({ 
            error: 'Failed to fetch recent predictions',
            details: error.message 
        });
    }
});

// GET /api/journal/meals/:userId/:date - Get meal data for specific date
router.get('/meals/:userId/:date', async (req, res) => {
    try {
        const { userId, date } = req.params;
        
        const query = `
            SELECT breakfast, lunch, dinner, snacks,
                   breakfast_calories, breakfast_protein, breakfast_carbs, breakfast_fiber, breakfast_fat,
                   lunch_calories, lunch_protein, lunch_carbs, lunch_fiber, lunch_fat,
                   dinner_calories, dinner_protein, dinner_carbs, dinner_fiber, dinner_fat,
                   snack_calories, snack_protein, snack_carbs, snack_fiber, snack_fat,
                   calories, protein, carbs, fiber, fat, notes
            FROM journal_entries 
            WHERE user_id = $1 AND entry_date = $2 AND entry_type = 'meals'
        `;
        
        const result = await db.query(query, [userId, date]);
        res.json(result.rows[0] || {});
    } catch (error) {
        console.error('Error fetching meal data:', error);
        res.status(500).json({ error: 'Failed to fetch meal data', details: error.message });
    }
});

// GET /api/meal_logs - Get meal logs
router.get('/meal_logs', async (req, res) => {
    try {
        const { user_id, days = 30 } = req.query;
        
        if (!user_id) {
            return res.status(400).json({ error: 'user_id is required' });
        }

        // Get meal entries for the specified user and date range
        const query = `
            SELECT entry_date, breakfast, lunch, dinner, snacks,
                   breakfast_calories, breakfast_protein, breakfast_carbs, breakfast_fiber, breakfast_fat,
                   lunch_calories, lunch_protein, lunch_carbs, lunch_fiber, lunch_fat,
                   dinner_calories, dinner_protein, dinner_carbs, dinner_fiber, dinner_fat,
                   snack_calories, snack_protein, snack_carbs, snack_fiber, snack_fat,
                   calories, protein, carbs, fiber, fat, notes
            FROM journal_entries 
            WHERE user_id = $1 AND entry_type = 'meals'
            AND entry_date >= CURRENT_DATE - INTERVAL '${days} days'
            ORDER BY entry_date DESC
        `;
        
        const result = await db.query(query, [user_id]);
        res.json({ meal_logs: result.rows });
    } catch (error) {
        console.error('Error fetching meal logs:', error);
        res.status(500).json({ 
            error: 'Failed to fetch meal logs',
            details: error.message 
        });
    }
});

module.exports = router; 