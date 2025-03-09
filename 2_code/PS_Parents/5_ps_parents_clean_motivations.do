********************************************************************************
* 5_ps_parents_clean_motivations.do
* ------------------------------------------------------------------------------
* Data needed: 4_ps_parents.dta
* Data output: 5_ps_parents.dta
* Purpose:
*   - Process and transform parental motivation factor data from the PS Parents dataset
*   - Create binary (0/1) variables for 12 motivational factors (e.g., salary, 
*     flexibility, further education, math requirements)
*   - Create variables for parent's own motivations and what they think about
*     the other parent's motivations
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
log using "${dodir_log}/5_ps_parents_clean_motivations.log", replace text

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
di as txt "STARTING: PS Parents Clean Motivations"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. DATA VALIDATION
********************************************************************************

// Check if input file exists
capture confirm file "${processed_data}/PS_Parents/4_ps_parents.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Parents/4_ps_parents.dta"
    di as error "Run 4_ps_parents_clean_beliefs.do first."
    exit 601
}

use "${processed_data}/PS_Parents/4_ps_parents.dta", clear
di as txt "Loaded dataset with `c(N)' observations and `c(k)' variables."

// Dataset validation checks
if _N == 0 {
    di as error "ERROR: Empty dataset - contains no observations"
    exit 601
}

// Check if any motivational factor variables exist
local motfactor_found = 0
forval i = 1/12 {
    capture confirm variable motFactor`i'
    if !_rc {
        local motfactor_found = 1
        continue, break
    }
}

foreach var in motFactors_this motFactors_other {
    capture confirm variable `var'
    if !_rc {
        local motfactor_found = 1
        continue, break
    }
}

if `motfactor_found' == 0 {
    di as error "ERROR: No motivational factor variables found in dataset."
    di as error "Required variables: motFactor*, motFactors_this, or motFactors_other"
    exit 111
}

// Report found motivational factor variables
di as txt "Found motivational factor variables in dataset."

********************************************************************************
* 2. CREATE MOTIVATIONAL FACTOR VARIABLES
********************************************************************************
di as txt "Creating motivational factor binary variables..."

// Initialize factor variables for this parent and other parent
forval i = 1/12 {
    gen fac_this_`i' = .
    label var fac_this_`i' "Motivation factor `i' (this parent)"
    
    gen fac_other_`i' = .
    label var fac_other_`i' "Motivation factor `i' (other parent)"
}

// Process motivational factors for this parent and other parent
foreach q in "this" "other" {
    di as txt "Processing `q' parent motivation factors..."
    
    // Check which format of motivation variables exists
    local factors_var_exists = 0
    capture confirm variable motFactors_`q'
    if !_rc {
        local factors_var_exists = 1
    }
    
    local factor_vars_exist = 0
    forval j = 1/12 {
        capture confirm variable motFactors_`q'_`j'
        if !_rc {
            local factor_vars_exist = 1
            continue, break
        }
    }
    
    if `factors_var_exists' == 0 & `factor_vars_exist' == 0 {
        di as txt "  No motFactors_`q' variables found, skipping."
        continue
    }
    
    // Process factor 1: Salary
    di as txt "  Processing Factor 1: Salary"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_1 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der zukünftige <strong>Lohn</strong>"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_1 = 1 if strpos(motFactors_`q', "Der zukünftige <strong>Lohn</strong>") > 0
    }
    
    // Process factor 2: Flexibility
    di as txt "  Processing Factor 2: Flexibility"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_2 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die zukünftige berufliche <strong>Flexibilität</strong> (z. B. die Möglichkeit, in Teilzeit zu arbeiten)"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_2 = 1 if strpos(motFactors_`q', "Die zukünftige berufliche <strong>Flexibilität</strong>") > 0
    }
    
    // Process factor 3: Further education
    di as txt "  Processing Factor 3: Further education"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_3 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_3 = 1 if strpos(motFactors_`q', "Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>") > 0
    }
    
    // Process factor 4: Math requirements
    di as txt "  Processing Factor 4: Math requirements"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_4 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>mathematischen</strong> Anforderungen"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_4 = 1 if strpos(motFactors_`q', "Die <strong>mathematischen</strong> Anforderungen") > 0
    }
    
    // Process factor 5: Language requirements
    di as txt "  Processing Factor 5: Language requirements"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_5 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>sprachlichen</strong> Anforderungen"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_5 = 1 if strpos(motFactors_`q', "Die <strong>sprachlichen</strong> Anforderungen") > 0
    }
    
    // Process factor 6: Gender composition
    di as txt "  Processing Factor 6: Gender composition"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_6 = 1 if motFactors_`q'_`j' == 1 & trim(motFactor`j') == "Die <strong>Geschlechterzusammensetzung</strong> im Beruf"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_6 = 1 if strpos(motFactors_`q', "Die <strong>Geschlechterzusammensetzung</strong> im Beruf") > 0
    }
    
    // Process factor 7: Social contact
    di as txt "  Processing Factor 7: Social contact"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_7 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Das Ausmass an <strong>sozialem Kontakt</strong>"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_7 = 1 if strpos(motFactors_`q', "Das Ausmass an <strong>sozialem Kontakt</strong>") > 0
    }
    
    // Process factor 8: Helping people
    di as txt "  Processing Factor 8: Helping people"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_8 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Menschen zu <strong>helfen</strong> (z.B. Kunden oder Patienten)"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_8 = 1 if strpos(motFactors_`q', "Menschen zu <strong>helfen</strong>") > 0
    }
    
    // Process factor 9: Type of workplace
    di as txt "  Processing Factor 9: Type of workplace"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_9 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der <strong>Arbeitsort</strong> (z.B. Büro, Aussenbereich, Baustelle)"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_9 = 1 if strpos(motFactors_`q', "Der <strong>Arbeitsort</strong>") > 0
    }
    
    // Process factor 10: Ability to obtain contract
    di as txt "  Processing Factor 10: Ability to obtain contract"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_10 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_10 = 1 if strpos(motFactors_`q', "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen") > 0
    }
    
    // Process factor 11: Promotion prospects
    di as txt "  Processing Factor 11: Promotion prospects"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_11 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die Aussicht auf <strong>Beförderungen</strong>"
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_11 = 1 if strpos(motFactors_`q', "Die Aussicht auf <strong>Beförderungen</strong>") > 0
    }
    
    // Process factor 12: Interests
    di as txt "  Processing Factor 12: Interests"
    if `factor_vars_exist' {
        forval j = 1/12 {
            capture replace fac_`q'_12 = 1 if motFactors_`q'_`j' == 1 & (trim(motFactor`j') == "Persönlichen <strong>Interessen</strong>" | ///
                                                                       trim(motFactor`j') == "Ihre persönlichen <strong>Interessen</strong>")
        }
    }
    else if `factors_var_exists' {
        replace fac_`q'_12 = 1 if strpos(motFactors_`q', "<strong>Interessen</strong>") > 0
    }
    
    // Count populated factors
    local total_populated = 0
    forval i = 1/12 {
        count if !missing(fac_`q'_`i')
        local factor_count = r(N)
        local total_populated = `total_populated' + `factor_count'
        di as txt "    Factor `i': `factor_count' observations populated"
    }
    di as txt "  Total populated cells for `q': `total_populated'"
}

// Replace missing values with 0 (not selected)
di as txt "Replacing missing values with 0 (not selected)..."
foreach q in "this" "other" {
    forval i = 1/12 {
        replace fac_`q'_`i' = 0 if missing(fac_`q'_`i')
    }
}

********************************************************************************
* 3. CREATING MOTHER AND FATHER VARIABLES
********************************************************************************
di as txt "Creating mother and father motivation variables..."

// Check if Parent_type_ variable exists
capture confirm variable Parent_type_
if _rc {
    di as error "WARNING: Parent_type_ variable not found. Cannot determine which parent is responding."
    di as error "Will skip creating mother/father-specific variables."
}
else {
    // Create mother and father factor variables
    forval i = 1/12 {
        gen mother_fac_`i' = .
        gen father_fac_`i' = .
        
        // When Parent_type_ = 1, respondent is mother
        replace mother_fac_`i' = fac_this_`i' if Parent_type_ == 1
        replace father_fac_`i' = fac_other_`i' if Parent_type_ == 1
        
        // When Parent_type_ = 2, respondent is father
        replace mother_fac_`i' = fac_other_`i' if Parent_type_ == 2
        replace father_fac_`i' = fac_this_`i' if Parent_type_ == 2
    }
    
    // Count populated mother/father factors
    di as txt "Mother factor populations:"
    forval i = 1/12 {
        count if !missing(mother_fac_`i')
        di as txt "  Factor `i': `r(N)' observations"
    }
    
    di as txt "Father factor populations:"
    forval i = 1/12 {
        count if !missing(father_fac_`i')
        di as txt "  Factor `i': `r(N)' observations"
    }
}

********************************************************************************
* 4. RELABEL MOTIVATIONAL FACTORS
********************************************************************************
di as txt "Assigning descriptive labels to motivation factor variables..."

// Define factor descriptions
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
    // Apply mother/father labels if these variables exist
    capture confirm variable mother_fac_`i'
    if !_rc {
        label var mother_fac_`i' "Mother's motivation factor: `fac_`i''"
    }
    
    capture confirm variable father_fac_`i'
    if !_rc {
        label var father_fac_`i' "Father's motivation factor: `fac_`i''"
    }
    
    // Relabel this/other variables
    label var fac_this_`i' "This parent's motivation factor: `fac_`i''"
    label var fac_other_`i' "Other parent's motivation factor: `fac_`i''"
}

// Drop original motivation factor variables
capture drop motFactor*

********************************************************************************
* 5. FINALIZATION
********************************************************************************
di as txt "----- Compressing and saving dataset -----"

// Compress and save
compress
save "${processed_data}/PS_Parents/5_ps_parents.dta", replace

// Final report
di as txt "Cleaned motivations dataset saved to: ${processed_data}/PS_Parents/5_ps_parents.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Parents Clean Motivations"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off