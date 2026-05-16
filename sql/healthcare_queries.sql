-- =============================================================
-- Healthcare SQL Mini Project — CORRECTED QUERIES
-- Vitalis Healthcare Project
-- Dialect: PostgreSQL
-- =============================================================

-- Schema and tables (unchanged from original)
CREATE SCHEMA IF NOT EXISTS healthcare;

CREATE TABLE IF NOT EXISTS healthcare.patients (
    patient_id INT PRIMARY KEY,
    first_name VARCHAR(20),
    last_name VARCHAR(20),
    gender CHAR,
    date_of_birth DATE,
    city VARCHAR(20),
    insurance_provider VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS healthcare.medications (
    med_id INT PRIMARY KEY,
    patient_id INT,
    medication_name VARCHAR(30),
    dosage VARCHAR(30),
    start_date DATE,
    end_date DATE,
    FOREIGN KEY (patient_id) REFERENCES healthcare.patients(patient_id)
);

CREATE TABLE IF NOT EXISTS healthcare.doctors (
    doctor_id INT PRIMARY KEY,
    doctor_name VARCHAR(50),
    specialty VARCHAR(50),
    clinic_location VARCHAR(30)
);

CREATE TABLE IF NOT EXISTS healthcare.appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_date DATE,
    status VARCHAR(20),
    visit_reason TEXT,
    FOREIGN KEY (patient_id) REFERENCES healthcare.patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES healthcare.doctors(doctor_id)
);

CREATE TABLE IF NOT EXISTS healthcare.billing (
    bill_id INT PRIMARY KEY,
    appointment_id INT,
    amount BIGINT,
    insurance_covered BIGINT,
    patient_paid BIGINT,
    FOREIGN KEY (appointment_id) REFERENCES healthcare.appointments(appointment_id)
);

CREATE TABLE IF NOT EXISTS healthcare.diagnoses (
    diagnosis_id INT PRIMARY KEY,
    appointment_id INT,
    diagnosis_code VARCHAR(20),
    diagnosis_description TEXT,
    FOREIGN KEY (appointment_id) REFERENCES healthcare.appointments(appointment_id)
);


-- ------------------------------------------------------------
-- 1. List all patients who live in Seattle.
-- ------------------------------------------------------------
SELECT *
FROM healthcare.patients
WHERE city = 'Seattle';


-- ------------------------------------------------------------
-- 2. Find all medications where the dosage is greater than 50mg.
--    *** BUG FIX ***
--    Original: WHERE dosage > '50mg'  -- this is a STRING compare.
--    Lexicographically '9mg' > '50mg' is TRUE, which is wrong.
--    Fix: extract the numeric portion from the dosage string and
--    compare as a number. Works for values like '75mg', '100 mg', '5mg'.
-- ------------------------------------------------------------
SELECT *
FROM healthcare.medications
WHERE CAST(NULLIF(REGEXP_REPLACE(dosage, '[^0-9]', '', 'g'), '') AS INTEGER) > 50;


-- ------------------------------------------------------------
-- 3. Get all completed appointments in February 2024.
-- ------------------------------------------------------------
SELECT *
FROM healthcare.appointments
WHERE status = 'Completed'
  AND appointment_date >= '2024-02-01'
  AND appointment_date <  '2024-03-01';


-- ------------------------------------------------------------
-- 4. Show each doctor and how many appointments they completed.
--    Minor improvement: use INNER JOIN since we filter to 'Completed';
--    a LEFT JOIN followed by WHERE status='Completed' silently
--    becomes an INNER JOIN anyway.
-- ------------------------------------------------------------
SELECT
    d.doctor_id,
    d.doctor_name,
    COUNT(a.appointment_id) AS completed_appointments
FROM healthcare.doctors d
JOIN healthcare.appointments a
    ON d.doctor_id = a.doctor_id
WHERE a.status = 'Completed'
GROUP BY d.doctor_id, d.doctor_name
ORDER BY completed_appointments DESC;


-- ------------------------------------------------------------
-- 5. Find the most common diagnosis in the database.
--    *** BUG FIX ***
--    Original returned ALL diagnoses sorted — not "the most common".
--    Fix: add LIMIT 1 so we return the single top diagnosis.
--    (If you want ties, use a window function instead.)
-- ------------------------------------------------------------
SELECT
    diagnosis_description,
    COUNT(diagnosis_id) AS total_count_of_diagnosis
FROM healthcare.diagnoses
GROUP BY diagnosis_description
ORDER BY total_count_of_diagnosis DESC
LIMIT 1;


-- ------------------------------------------------------------
-- 6. List the total billing amount per patient.
--    Note: original GROUP BY uses an alias, which works in
--    PostgreSQL but not in all dialects. Grouping by patient_id is
--    safer (two different patients could share the same full name).
-- ------------------------------------------------------------
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    SUM(b.amount) AS total_billing
FROM healthcare.patients p
JOIN healthcare.appointments a ON p.patient_id = a.patient_id
JOIN healthcare.billing b      ON a.appointment_id = b.appointment_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY patient_name;


-- ------------------------------------------------------------
-- 7. Which clinic location has the highest number of appointments?
-- ------------------------------------------------------------
SELECT
    d.clinic_location,
    COUNT(a.appointment_id) AS total_appointments
FROM healthcare.doctors d
JOIN healthcare.appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY d.clinic_location
ORDER BY total_appointments DESC;


-- ------------------------------------------------------------
-- 8. Identify patients who have more than one diagnosis in 2024.
--    *** BUG FIX ***
--    Original grouped by Patient_name only. Two different patients
--    with the same full name would be merged into one row.
--    Fix: group by patient_id (and include first/last_name for display).
-- ------------------------------------------------------------
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    COUNT(d.diagnosis_id) AS diagnosis_count
FROM healthcare.patients p
JOIN healthcare.appointments a ON p.patient_id = a.patient_id
JOIN healthcare.diagnoses    d ON a.appointment_id = d.appointment_id
WHERE EXTRACT(YEAR FROM a.appointment_date) = 2024
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(d.diagnosis_id) > 1
ORDER BY diagnosis_count DESC;


-- ------------------------------------------------------------
-- 9. Rank doctors by total revenue generated.
-- ------------------------------------------------------------
SELECT
    d.doctor_id,
    d.doctor_name,
    SUM(b.amount) AS total_revenue,
    RANK() OVER (ORDER BY SUM(b.amount) DESC) AS revenue_rank
FROM healthcare.doctors d
JOIN healthcare.appointments a ON d.doctor_id = a.doctor_id
JOIN healthcare.billing      b ON a.appointment_id = b.appointment_id
GROUP BY d.doctor_id, d.doctor_name
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- 10. For each patient, show their most recent appointment.
--     *** BUG FIX ***
--     Original had a stray "SELECT * FROM healthcare.appointments"
--     right before the real query — running the script would fail
--     or return two result sets. Removed.
-- ------------------------------------------------------------
SELECT
    a.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    MAX(a.appointment_date) AS most_recent_appointment
FROM healthcare.appointments a
JOIN healthcare.patients p
    ON a.patient_id = p.patient_id
GROUP BY a.patient_id, p.first_name, p.last_name
ORDER BY a.patient_id;


-- ------------------------------------------------------------
-- 11. Identify patients whose insurance covered less than 70% of their bill.
--     *** CRITICAL BUG FIX ***
--     Original: b.insurance_covered / b.amount with BIGINT/BIGINT
--     does INTEGER division in PostgreSQL → result is always 0
--     unless insurance_covered >= amount.
--     Also SUM(ratio_per_row) is mathematically wrong; we need
--     SUM(insurance_covered) / SUM(amount) for an overall percentage.
--     Fix: cast to NUMERIC, aggregate first, then compute the ratio.
-- ------------------------------------------------------------
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    SUM(b.amount)            AS total_billed,
    SUM(b.insurance_covered) AS total_insurance_covered,
    ROUND(
        SUM(b.insurance_covered)::NUMERIC
        / NULLIF(SUM(b.amount), 0) * 100,
        2
    ) AS insurance_percent_covered
FROM healthcare.patients p
JOIN healthcare.appointments a ON p.patient_id = a.patient_id
JOIN healthcare.billing      b ON a.appointment_id = b.appointment_id
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING SUM(b.insurance_covered)::NUMERIC / NULLIF(SUM(b.amount), 0) * 100 < 70
ORDER BY insurance_percent_covered ASC;


-- ------------------------------------------------------------
-- 12. Identify all diabetic patients and list their last medication renewal date.
--     Cleaned up the WHERE EXISTS subquery — original used
--     LIKE ANY (ARRAY[...]) which works in Postgres but mixed two
--     styles. Consolidated into a single LIKE ANY list.
--     Use renewal_rank = 1 to filter to the last renewal.
-- ------------------------------------------------------------
SELECT *
FROM (
    SELECT
        p.patient_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        m.medication_name,
        m.dosage,
        m.start_date,
        ROW_NUMBER() OVER (
            PARTITION BY p.patient_id
            ORDER BY m.start_date DESC
        ) AS renewal_rank
    FROM healthcare.patients p
    JOIN healthcare.medications m ON p.patient_id = m.patient_id
    WHERE EXISTS (
        SELECT 1
        FROM healthcare.medications m2
        WHERE m2.patient_id = p.patient_id
          AND LOWER(m2.medication_name) LIKE ANY (ARRAY[
                '%insulin%', '%metformin%', '%glipizide%',
                '%glyburide%', '%glimepiride%', '%pioglitazone%',
                '%sitagliptin%', '%linagliptin%'
          ])
    )
) ranked
WHERE renewal_rank = 1   -- comment this line out to see ALL prescriptions
ORDER BY patient_id;


-- ------------------------------------------------------------
-- 13. Which doctor has the lowest no-show rate?
--     Added NULLIF guard against divide-by-zero, plus a minimum
--     appointment threshold so a doctor with 1 appointment doesn't
--     win the "lowest rate" race.
-- ------------------------------------------------------------
SELECT
    d.doctor_id,
    d.doctor_name,
    COUNT(*) AS total_appointments,
    ROUND(
        COUNT(CASE WHEN a.status = 'No-show' THEN 1 END) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS no_show_rate
FROM healthcare.doctors d
JOIN healthcare.appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.doctor_name
HAVING COUNT(*) >= 10   -- only include doctors with a meaningful sample size
ORDER BY no_show_rate ASC
LIMIT 1;


-- ------------------------------------------------------------
-- 14. Which age group has the highest incidence of hypertension (I10)?
-- ------------------------------------------------------------
WITH age_calc AS (
    SELECT
        p.patient_id,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth)) AS age
    FROM healthcare.patients p
),
age_groups AS (
    SELECT
        patient_id,
        CASE
            WHEN age < 18                  THEN 'Child'
            WHEN age BETWEEN 18 AND 39     THEN 'Adult'
            WHEN age BETWEEN 40 AND 59     THEN 'Middle Age'
            ELSE 'Senior'
        END AS age_group
    FROM age_calc
)
SELECT
    ag.age_group,
    COUNT(*) AS hypertension_cases
FROM age_groups ag
JOIN healthcare.appointments a ON ag.patient_id = a.patient_id
JOIN healthcare.diagnoses    d ON a.appointment_id = d.appointment_id
WHERE d.diagnosis_code = 'I10'
GROUP BY ag.age_group
ORDER BY hypertension_cases DESC;


-- ------------------------------------------------------------
-- 15. Which insurance provider covers the highest average amount?
-- ------------------------------------------------------------
SELECT
    p.insurance_provider,
    ROUND(AVG(b.insurance_covered), 2) AS avg_coverage
FROM healthcare.patients p
JOIN healthcare.appointments a ON p.patient_id = a.patient_id
JOIN healthcare.billing      b ON a.appointment_id = b.appointment_id
GROUP BY p.insurance_provider
ORDER BY avg_coverage DESC;


-- ------------------------------------------------------------
-- 16. Determine peak days of the week for appointments.
--     Improvement: TO_CHAR(..., 'Day') returns padded strings like
--     'Monday   '. Used TRIM to clean up. Also added the numeric
--     day-of-week so you could re-order Mon→Sun if needed.
-- ------------------------------------------------------------
SELECT
    TRIM(TO_CHAR(appointment_date, 'Day')) AS day_of_week,
    COUNT(appointment_id) AS total_appointments
FROM healthcare.appointments
GROUP BY TRIM(TO_CHAR(appointment_date, 'Day'))
ORDER BY total_appointments DESC;


-- ============================================================
-- 17. Three additional queries
-- ============================================================

-- 17a. Patients who visited more than 3 times.
--      *** BUG FIX ***  Group by patient_id, not just name (two patients
--      could share the same full name). Also added ORDER BY DESC.
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    COUNT(a.appointment_id) AS no_of_visits
FROM healthcare.patients p
JOIN healthcare.appointments a
    ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
HAVING COUNT(a.appointment_id) > 3
ORDER BY no_of_visits DESC;


-- 17b. Patients who frequently miss or cancel appointments.
--      *** BUG FIX ***  Same name-collision issue. Group by patient_id.
SELECT
    p.patient_id,
    p.first_name || ' ' || p.last_name AS patient_name,
    a.status,
    COUNT(a.appointment_id) AS no_of_cancelled_or_no_show
FROM healthcare.patients p
JOIN healthcare.appointments a
    ON p.patient_id = a.patient_id
WHERE a.status IN ('No-show', 'Cancelled')
GROUP BY p.patient_id, p.first_name, p.last_name, a.status
HAVING COUNT(a.appointment_id) >= 2
ORDER BY no_of_cancelled_or_no_show DESC;


-- 17c. Count diagnoses per specialty.
SELECT
    d.specialty,
    COUNT(di.diagnosis_id) AS diagnosis_count
FROM healthcare.doctors d
JOIN healthcare.appointments a ON d.doctor_id = a.doctor_id
JOIN healthcare.diagnoses    di ON a.appointment_id = di.appointment_id
GROUP BY d.specialty
ORDER BY diagnosis_count DESC;
