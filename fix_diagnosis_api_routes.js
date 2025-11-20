// Fix the diagnosis API routes to use username instead of user_id
// This is an alternative approach to Option 1

const express = require('express');
const { Pool } = require('pg');
const config = require('../database/config');

const router = express.Router();

// Get the environment
const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env].medivue;

// Create a new pool
const pool = new Pool({
    user: String(dbConfig.username),
    host: String(dbConfig.host),
    database: String(dbConfig.database),
    password: String(dbConfig.password),
    port: Number(dbConfig.port),
});

// POST /api/users/:username/diagnosis - Save diagnosis information (FIXED VERSION)
router.post('/:username', async (req, res) => {
    const { username } = req.params;
    const {
        diagnosis,
        diagnosisYear,
        diagnosisMonth,
        diseaseLocation,
        diseaseBehavior,
        diseaseSeverity,
        takingMedications,
        currentMedications,
        medicationComplications,
        isAnemic,
        anemiaSeverity,
        giSpecialistFrequency,
        lastGiVisit,
        familyHistory,
        surgeryHistory,
        hospitalizations,
        flareFrequency,
        currentSymptoms,
        dietaryRestrictions,
        comorbidities,
    } = req.body;

    console.log('DEBUG: Diagnosis save request for username:', username);
    console.log('DEBUG: Request body:', req.body);

    try {
        // First, verify the username exists in the users table
        const userCheck = await pool.query(
            'SELECT user_id, username FROM users WHERE username = $1',
            [username]
        );

        if (userCheck.rows.length === 0) {
            return res.status(404).json({
                error: 'User not found',
                message: `Username '${username}' does not exist in the database`
            });
        }

        const userId = userCheck.rows[0].user_id;
        console.log('DEBUG: Found user_id:', userId, 'for username:', username);

        // Construct diagnosis date from year and month
        let diagnosisDate = null;
        if (diagnosisYear && diagnosisMonth) {
            const monthMap = {
                'January': '01', 'February': '02', 'March': '03', 'April': '04',
                'May': '05', 'June': '06', 'July': '07', 'August': '08',
                'September': '09', 'October': '10', 'November': '11', 'December': '12'
            };
            const monthNum = monthMap[diagnosisMonth] || '01';
            diagnosisDate = `${diagnosisYear}-${monthNum}-01`;
        }

        // Convert arrays to text
        const medicationsText = Array.isArray(currentMedications) ? currentMedications.join(', ') : currentMedications || '';
        const complicationsText = Array.isArray(medicationComplications) ? medicationComplications.join(', ') : medicationComplications || '';
        const symptomsText = Array.isArray(currentSymptoms) ? currentSymptoms.join(', ') : currentSymptoms || '';
        const restrictionsText = Array.isArray(dietaryRestrictions) ? dietaryRestrictions.join(', ') : dietaryRestrictions || '';
        const comorbiditiesText = Array.isArray(comorbidities) ? comorbidities.join(', ') : comorbidities || '';

        // Check if record already exists
        const existingRecord = await pool.query(
            'SELECT id FROM user_diagnosis WHERE username = $1',
            [username]
        );

        if (existingRecord.rows.length > 0) {
            // Update existing record
            const updateQuery = `
                UPDATE user_diagnosis SET
                    diagnosis = $2,
                    diagnosis_year = $3,
                    diagnosis_month = $4,
                    disease_location = $5,
                    disease_behavior = $6,
                    disease_severity = $7,
                    taking_medications = $8,
                    current_medications = $9,
                    medication_complications = $10,
                    is_anemic = $11,
                    anemia_severity = $12,
                    gi_specialist_frequency = $13,
                    last_gi_visit = $14,
                    family_history = $15,
                    surgery_history = $16,
                    hospitalizations = $17,
                    flare_frequency = $18,
                    current_symptoms = $19,
                    dietary_restrictions = $20,
                    comorbidities = $21,
                    updated_at = CURRENT_TIMESTAMP
                WHERE username = $1
                RETURNING *
            `;

            const result = await pool.query(updateQuery, [
                username,
                diagnosis,
                diagnosisYear,
                diagnosisMonth,
                diseaseLocation,
                diseaseBehavior,
                diseaseSeverity,
                takingMedications,
                medicationsText,
                complicationsText,
                isAnemic,
                anemiaSeverity,
                giSpecialistFrequency,
                lastGiVisit,
                familyHistory,
                surgeryHistory,
                hospitalizations,
                flareFrequency,
                symptomsText,
                restrictionsText,
                comorbiditiesText
            ]);

            console.log('DEBUG: Updated existing diagnosis record:', result.rows[0]);

            res.json({
                message: 'Diagnosis information updated successfully',
                data: result.rows[0]
            });
        } else {
            // Create new record
            const insertQuery = `
                INSERT INTO user_diagnosis (
                    username, diagnosis, diagnosis_year, diagnosis_month,
                    disease_location, disease_behavior, disease_severity,
                    taking_medications, current_medications, medication_complications,
                    is_anemic, anemia_severity, gi_specialist_frequency,
                    last_gi_visit, family_history, surgery_history,
                    hospitalizations, flare_frequency, current_symptoms,
                    dietary_restrictions, comorbidities
                ) VALUES (
                    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10,
                    $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21
                )
                RETURNING *
            `;

            const result = await pool.query(insertQuery, [
                username,
                diagnosis,
                diagnosisYear,
                diagnosisMonth,
                diseaseLocation,
                diseaseBehavior,
                diseaseSeverity,
                takingMedications,
                medicationsText,
                complicationsText,
                isAnemic,
                anemiaSeverity,
                giSpecialistFrequency,
                lastGiVisit,
                familyHistory,
                surgeryHistory,
                hospitalizations,
                flareFrequency,
                symptomsText,
                restrictionsText,
                comorbiditiesText
            ]);

            console.log('DEBUG: Created new diagnosis record:', result.rows[0]);

            res.json({
                message: 'Diagnosis information saved successfully',
                data: result.rows[0]
            });
        }
    } catch (err) {
        console.error('Error saving diagnosis information:', err);
        res.status(500).json({
            error: 'Internal server error',
            details: err.message
        });
    }
});

module.exports = router;







