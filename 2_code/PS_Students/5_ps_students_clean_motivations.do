********************************************************************************
* 5_ps_students_clean_motivations.do
* ------------------------------------------------------------------------------
* Data needed: ps_stu_cleaned.dta
* Data output: ps_stu_cleaned.dta
* Purpose:
*   - Process and transform motivational factor data for students
*   - Create binary (0/1) variables for 12 motivational factors (e.g., salary, 
*     flexibility, further education, math requirements)
*   - Process factors for child, mother, and father perspectives
*   - Label all variables for better interpretation
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING
********************************************************************************

// Standard initialization
clear all
set more off
version 18.0

// Log initialization
cap log close
log using "${dodir_log}/5_ps_students_clean_motivations.log", replace text

// Performance monitoring
timer clear
timer on 1

// Enable or disable trace based on debug flag
if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Clean Motivations"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

*******************************************************************************
// 1. DATA VALIDATION
*******************************************************************************

// Check if input file exists
capture confirm file "${processed_data}/PS_Students/4_ps_students.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Students/4_ps_students.dta"
    di as error "Run 4_ps_students_clean_beliefs.do first."
    exit 601
}

use "${processed_data}/PS_Students/4_ps_students.dta", clear
di as txt "Loaded dataset with `c(N)' observations and `c(k)' variables."

// Dataset validation checks
if _N == 0 {
    di as error "ERROR: Empty dataset - ps_stu_cleaned.dta contains no observations"
    exit 601
}

// Check if required variables exist
local motfactor_found = 0
forval i = 1/12 {
    capture confirm variable motFactor`i'
    if !_rc {
        local motfactor_found = 1
        continue, break
    }
}

if `motfactor_found' == 0 {
    // Check alternative naming patterns
    foreach var in motFactors_child_1 motFactors_mother_1 motFactors_father_1 {
        capture confirm variable `var'
        if !_rc {
            local motfactor_found = 1
            continue, break
        }
    }
    
    if `motfactor_found' == 0 {
        di as error "ERROR: No motivational factor variables found in dataset."
        di as error "Required variables: motFactor*, motFactors_child_*, motFactors_mother_*, motFactors_father_*"
        exit
    }
}

// Report found motivational factor variables
di as txt "Found motivational factor variables in dataset."

********************************************************************************
// 2. CREATE MOTIVATIONAL FACTOR VARIABLES
*.   a. This is a loop that goes through the motivational factors and
*      This section creates binary (0/1) variables for 12 motivational factors 
*      separately for the child, mother, and father.
********************************************************************************
di as txt "Creating motivational factor binary variables..."

// Initialize factor variables
forval i = 1/12 {
    gen child_fac_`i' = .
    gen mother_fac_`i' = .
    gen father_fac_`i' = .
    
    // Add variable labels
    label var child_fac_`i' "Child motivation factor `i'"
    label var mother_fac_`i' "Mother motivation factor `i'"
    label var father_fac_`i' "Father motivation factor `i'"
}

// Process each perspective (child, mother, father)
foreach q in "child" "mother" "father" {
    di as txt "Processing `q' motivation factors..."
    
    // Check if motFactors_`q'_* variables exist
    local found_vars = 0
    forval j = 1/12 {
        capture confirm variable motFactors_`q'_`j'
        if !_rc {
            local found_vars = 1
        }
    }
    
    if `found_vars' == 0 {
        di as txt "  No motFactors_`q'_* variables found, skipping."
        continue
    }
    
    // Process Factor 1: Salary
    di as txt "  Processing Factor 1: Salary"
    forval j = 1/12 {
        capture replace `q'_fac_1 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der zukünftige <strong>Lohn</strong>"
    }
    
    // Process Factor 2: Flexibility
    di as txt "  Processing Factor 2: Flexibility"
    forval j = 1/12 {
        capture replace `q'_fac_2 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die zukünftige berufliche <strong>Flexibilität</strong> (z. B. die Möglichkeit, in Teilzeit zu arbeiten)"
    }
    
    // Process Factor 3: Further education
    di as txt "  Processing Factor 3: Further education"
    forval j = 1/12 {
        capture replace `q'_fac_3 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>"
    }
    
    // Process Factor 4: Math requirements
    di as txt "  Processing Factor 4: Math requirements"
    forval j = 1/12 {
        capture replace `q'_fac_4 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>mathematischen</strong> Anforderungen"
    }
    
    // Process Factor 5: Language requirements
    di as txt "  Processing Factor 5: Language requirements"
    forval j = 1/12 {
        capture replace `q'_fac_5 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>sprachlichen</strong> Anforderungen"
    }
    
    // Process Factor 6: Gender composition
    di as txt "  Processing Factor 6: Gender composition"
    forval j = 1/12 {
        capture replace `q'_fac_6 = 1 if motFactors_`q'_`j' == 1 & trim(motFactor`j') == "Die <strong>Geschlechterzusammensetzung</strong> im Beruf"
    }
    
    // Process Factor 7: Social contact
    di as txt "  Processing Factor 7: Social contact"
    forval j = 1/12 {
        capture replace `q'_fac_7 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Das Ausmass an <strong>sozialem Kontakt</strong>"
    }
    
    // Process Factor 8: Helping people
    di as txt "  Processing Factor 8: Helping people"
    forval j = 1/12 {
        capture replace `q'_fac_8 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Menschen zu <strong>helfen</strong> (z.B. Kunden oder Patienten)"
    }
    
    // Process Factor 9: Type of workplace
    di as txt "  Processing Factor 9: Type of workplace"
    forval j = 1/12 {
        capture replace `q'_fac_9 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der <strong>Arbeitsort</strong> (z.B. Büro, Aussenbereich, Baustelle)"
    }
    
    // Process Factor 10: Ability to obtain contract
    di as txt "  Processing Factor 10: Ability to obtain contract"
    forval j = 1/12 {
        capture replace `q'_fac_10 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen"
    }
    
    // Process Factor 11: Promotion prospects
    di as txt "  Processing Factor 11: Promotion prospects"
    forval j = 1/12 {
        capture replace `q'_fac_11 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die Aussicht auf <strong>Beförderungen</strong>"
    }
    
    // Process Factor 12: Interests
    di as txt "  Processing Factor 12: Interests"
    forval j = 1/12 {
        capture replace `q'_fac_12 = 1 if motFactors_`q'_`j' == 1 & (trim(motFactor`j') == "Persönlichen <strong>Interessen</strong>" | ///
                                                                     trim(motFactor`j') == "Ihre persönlichen <strong>Interessen</strong>")
    }
    
    // Count populated factors
    local total_populated = 0
    forval i = 1/12 {
        count if !missing(`q'_fac_`i')
        local factor_count = r(N)
        local total_populated = `total_populated' + `factor_count'
        di as txt "    Factor `i': `factor_count' observations populated"
    }
    di as txt "  Total populated cells for `q': `total_populated'"
}

// Replace missing values with 0 (not selected)
di as txt "Replacing missing values with 0 (not selected)..."
foreach q in "child" "mother" "father" {
    forval i = 1/12 {
        replace `q'_fac_`i' = 0 if missing(`q'_fac_`i')
    }
}

// Drop original motivation factor variables
di as txt "Dropping original motivation factor variables..."
capture drop motFactor*

********************************************************************************
// 3. RELABEL MOTIVATIONAL FACTORS IN ENGLISH CORRESPONDING FACTORS
*.   a. Assign the right labels to the motivational factors for easier understanding
********************************************************************************
di as txt "Assigning descriptive labels to motivation factor variables..."

// Define factor labels
local fac_1 "salary"
local fac_2 "flexibility"
local fac_3 "further education possibilities"
local fac_4 "math requirements"
local fac_5 "language requirements"
local fac_6 "gender composition"
local fac_7 "social contact"
local fac_8 "helping people"
local fac_9 "type of workplace"
local fac_10 "ability to obtain contract"
local fac_11 "promotion prospects"
local fac_12 "interests"

// Apply labels to all factor variables
forval i = 1/12 {
    label var mother_fac_`i' "Mother's motivation factor: `fac_`i''"
    label var father_fac_`i' "Father's motivation factor: `fac_`i''"
    label var child_fac_`i' "Student's motivation factor: `fac_`i''"
}

*******************************************************************************
// 4. FINALIZATION
*******************************************************************************

// Validate created variables
di as txt "Validating created factor variables..."
capture confirm variable child_fac_1
if _rc {
    di as error "ERROR: Factor variables not created properly"
    exit 459
}

// Compress and save dataset
compress
save "${processed_data}/PS_Students/5_ps_students.dta", replace

// Final report
di as txt "Cleaned motivations dataset saved to: ${processed_data}/PS_Students/5_ps_students.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Clean Motivations"
di as txt "======================================================="

// Performance report
timer off 1
timer list 1
log close
set trace off