********************************************************************************
* 7_ps_parents_clean_concerns.do
* ------------------------------------------------------------------------------
* Data needed: 6_ps_parents.dta
* Data output: 7_ps_parents.dta
* Purpose:
*   - Process and transform parental concerns related to apprenticeships
*   - Create binary indicators for different types of concerns (work environment,
*     work-life balance, skill fit, career opportunities, personality fit, and 
*     lack of knowledge about career)
*   - Process data from suit_concerns variables and other related concern variables
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
* 0. HOUSEKEEPING & LOGGING
********************************************************************************
clear all
set more off
version 18.0

if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/7_ps_parents_cleaning_concerns.log", replace text

timer clear
timer on 1

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Parents Clean Concerns"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD DATA
********************************************************************************
di as txt "----- Loading dataset: 6_ps_parents.dta -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Parents/6_ps_parents.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Parents/6_ps_parents.dta"
    di as error "Run 6_ps_parents_clean_other.do first."
    exit 601
}

use "${processed_data}/PS_Parents/6_ps_parents.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in dataset."
    exit 602
}

********************************************************************************
* 2. CLEAN CONCERNS
********************************************************************************
di as txt "----- Creating binary indicators for different types of concerns -----"

/* Create binary indicators for different types of concerns related to apprenticeships */
forval i = 1/6 {
    gen concern_`i' = .
    label var concern_`i' "Concern type `i'"
}

// Check for different types of concern variables in the dataset
local concern_vars_found = 0
foreach pattern in concern* suit_concerns* {
    ds `pattern'
    local found_vars `r(varlist)'
    if "`found_vars'" != "" {
        di as txt "Found concern variables matching pattern `pattern': `found_vars'"
        local concern_vars_found = 1
    }
}

if `concern_vars_found' == 0 {
    di as error "WARNING: No concern variables found in dataset."
    di as error "Creating empty concern variables."
    
    // Create empty concerns (all zeros)
    forval i = 1/6 {
        replace concern_`i' = 0
    }
}
else {
    // Process concern variables
    
    // First check for suit_concerns variables (most common pattern)
    di as txt "Checking for suit_concerns variables..."
    foreach j in 1 2 {
        capture confirm variable suit_concerns_`j'
        if !_rc {
            di as txt "Processing suit_concerns_`j'..."
            
            // Process concern type 1: Work Environment
            count if suit_concerns_`j' == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
            local count_1 = r(N)
            replace concern_1 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
            
            // Process concern type 2: Work-Life Balance
            count if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
            local count_2 = r(N)
            replace concern_2 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
            
            // Process concern type 3: Skill Fit
            count if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
            local count_3 = r(N)
            replace concern_3 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
            
            // Process concern type 4: Career Opportunities
            count if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
            local count_4 = r(N)
            replace concern_4 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
            
            // Process concern type 5: Personality Fit
            count if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
            local count_5 = r(N)
            replace concern_5 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
            
            // Process concern type 6: Lack of Knowledge
            count if suit_concerns_`j' == "Ich weiß nicht viel über diesen Beruf"
            local count_6 = r(N)
            replace concern_6 = 1 if suit_concerns_`j' == "Ich weiß nicht viel über diesen Beruf"
            
            di as txt "Found concerns in suit_concerns_`j':"
            di as txt "  Type 1 (Work Environment): `count_1'"
            di as txt "  Type 2 (Work-Life Balance): `count_2'"
            di as txt "  Type 3 (Skill Fit): `count_3'"
            di as txt "  Type 4 (Career Opportunities): `count_4'"
            di as txt "  Type 5 (Personality Fit): `count_5'"
            di as txt "  Type 6 (Lack of Knowledge): `count_6'"
        }
    }
    
    // Then check for generic concern variables
    di as txt "Checking for generic concern variables..."
    forval j = 1/6 {
        capture confirm variable concern`j'
        if !_rc {
            di as txt "Processing concern`j'..."
            
            // Process concern type 1: Work Environment
            count if concern`j' == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
            local count_1 = r(N)
            replace concern_1 = 1 if concern`j' == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
            
            // Process concern type 2: Work-Life Balance
            count if concern`j' == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
            local count_2 = r(N)
            replace concern_2 = 1 if concern`j' == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
            
            // Process concern type 3: Skill Fit
            count if concern`j' == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
            local count_3 = r(N)
            replace concern_3 = 1 if concern`j' == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
            
            // Process concern type 4: Career Opportunities
            count if concern`j' == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
            local count_4 = r(N)
            replace concern_4 = 1 if concern`j' == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
            
            // Process concern type 5: Personality Fit
            count if concern`j' == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
            local count_5 = r(N)
            replace concern_5 = 1 if concern`j' == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
            
            // Process concern type 6: Lack of Knowledge
            count if concern`j' == "Ich weiß nicht viel über diesen Beruf"
            local count_6 = r(N)
            replace concern_6 = 1 if concern`j' == "Ich weiß nicht viel über diesen Beruf"
            
            di as txt "Found concerns in concern`j':"
            di as txt "  Type 1 (Work Environment): `count_1'"
            di as txt "  Type 2 (Work-Life Balance): `count_2'"
            di as txt "  Type 3 (Skill Fit): `count_3'"
            di as txt "  Type 4 (Career Opportunities): `count_4'"
            di as txt "  Type 5 (Personality Fit): `count_5'"
            di as txt "  Type 6 (Lack of Knowledge): `count_6'"
        }
    }
    
    // Lastly, check for suit_case variables (less common)
    di as txt "Checking for suit_case variables..."
    foreach j in 1 2 3 {
        capture confirm variable suit_case_`j'_1
        if !_rc {
            di as txt "Processing suit_case_`j'_1..."
            
            // Process concern type 1: Work Environment
            count if suit_case_`j'_1 == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
            local count_1 = r(N)
            replace concern_1 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
            
            // Process concern type 2: Work-Life Balance
            count if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
            local count_2 = r(N)
            replace concern_2 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
            
            // Process concern type 3: Skill Fit
            count if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
            local count_3 = r(N)
            replace concern_3 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
            
            // Process concern type 4: Career Opportunities
            count if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
            local count_4 = r(N)
            replace concern_4 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
            
            // Process concern type 5: Personality Fit
            count if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
            local count_5 = r(N)
            replace concern_5 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
            
            // Process concern type 6: Lack of Knowledge
            count if suit_case_`j'_1 == "Ich weiß nicht viel über diesen Beruf"
            local count_6 = r(N)
            replace concern_6 = 1 if suit_case_`j'_1 == "Ich weiß nicht viel über diesen Beruf"
            
            di as txt "Found concerns in suit_case_`j'_1:"
            di as txt "  Type 1 (Work Environment): `count_1'"
            di as txt "  Type 2 (Work-Life Balance): `count_2'"
            di as txt "  Type 3 (Skill Fit): `count_3'"
            di as txt "  Type 4 (Career Opportunities): `count_4'"
            di as txt "  Type 5 (Personality Fit): `count_5'"
            di as txt "  Type 6 (Lack of Knowledge): `count_6'"
        }
    }
}

// Replace missing values with 0 (no concern)
di as txt "Replacing missing values with 0 (no concern)..."
forval i = 1/6 {
    replace concern_`i' = 0 if missing(concern_`i')
}

// Apply descriptive labels to the concern variables
local concern_1 "Work Environment Concerns"
local concern_2 "Work-Life Balance Concerns"
local concern_3 "Skill Fit Concerns"
local concern_4 "Career Opportunity Concerns"
local concern_5 "Personality Fit Concerns"
local concern_6 "Lack of Knowledge About Career"

forval i = 1/6 {
    label var concern_`i' "`concern_`i''"
}

// Count total concern instances
di as txt "Summary of concerns identified:"
local total_concerns = 0
forval i = 1/6 {
    count if concern_`i' == 1
    local count_`i' = r(N)
    local total_concerns = `total_concerns' + `count_`i''
    di as txt "  `concern_`i'': `count_`i'' observations"
}
di as txt "Total concern instances: `total_concerns'"

********************************************************************************
* 3. FINAL HOUSEKEEPING & SAVE
********************************************************************************
di as txt "----- Compressing and saving dataset -----"

// Compress and save
compress
save "${processed_data}/PS_Parents/7_ps_parents.dta", replace

// Final report
di as txt "Cleaned concerns dataset saved to: ${processed_data}/PS_Parents/7_ps_parents.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Parents Clean Concerns"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off