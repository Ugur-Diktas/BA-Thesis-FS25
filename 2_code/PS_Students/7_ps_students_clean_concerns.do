********************************************************************************
* 7_ps_students_clean_concerns.do
* ------------------------------------------------------------------------------
* Data needed: 6_ps_students.dta
* Data output: 7_ps_students.dta
* Purpose:
*   - Process and transform student concerns related to apprenticeships
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
log using "${dodir_log}/7_ps_students_clean_concerns.log", replace text

timer clear
timer on 1

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Clean Concerns"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD DATA
********************************************************************************
di as txt "----- Loading dataset: 6_ps_students.dta -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Students/6_ps_students.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Students/6_ps_students.dta"
    di as error "Run 6_ps_students_clean_other.do first."
    exit 601
}

use "${processed_data}/PS_Students/6_ps_students.dta", clear

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

// Map concern types from suit_concerns variables to standardized concerns
di as txt "Checking for suit_concerns variables..."
local concerns_found = 0

forval j = 1/2 {
    capture confirm variable suit_concerns_`j'
    if !_rc {
        di as txt "Found suit_concerns_`j', processing..."
        local concerns_found = 1
        
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
        
        di as txt "  Found concerns in suit_concerns_`j':"
        di as txt "    Type 1 (Work Environment): `count_1'"
        di as txt "    Type 2 (Work-Life Balance): `count_2'"
        di as txt "    Type 3 (Skill Fit): `count_3'"
        di as txt "    Type 4 (Career Opportunities): `count_4'"
        di as txt "    Type 5 (Personality Fit): `count_5'"
        di as txt "    Type 6 (Lack of Knowledge): `count_6'"
    }
}

// Check for additional concern variables (suit_case_* if they exist)
di as txt "Checking for suit_case variables..."
forval j = 1/3 {
    capture confirm variable suit_case_`j'_1
    if !_rc {
        di as txt "Found suit_case_`j'_1, processing..."
        local concerns_found = 1
        
        // Check if variable is numeric or string
        capture confirm numeric variable suit_case_`j'_1
        if !_rc {
            // It's numeric - try to decode it
            capture decode suit_case_`j'_1, gen(temp_suit_case)
            if !_rc {
                // Successfully decoded
                replace concern_1 = 1 if temp_suit_case == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
                replace concern_2 = 1 if temp_suit_case == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
                replace concern_3 = 1 if temp_suit_case == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
                replace concern_4 = 1 if temp_suit_case == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
                replace concern_5 = 1 if temp_suit_case == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
                replace concern_6 = 1 if temp_suit_case == "Ich weiß nicht viel über diesen Beruf"
                drop temp_suit_case
            }
            else {
                // Fallback to numeric values (replace these with actual codes if known)
                replace concern_1 = 1 if suit_case_`j'_1 == 1
                replace concern_2 = 1 if suit_case_`j'_1 == 2
                replace concern_3 = 1 if suit_case_`j'_1 == 3
                replace concern_4 = 1 if suit_case_`j'_1 == 4
                replace concern_5 = 1 if suit_case_`j'_1 == 5
                replace concern_6 = 1 if suit_case_`j'_1 == 6
            }
        }
        else {
            // It's a string variable
            replace concern_1 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
            replace concern_2 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
            replace concern_3 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
            replace concern_4 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
            replace concern_5 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
            replace concern_6 = 1 if suit_case_`j'_1 == "Ich weiß nicht viel über diesen Beruf"
        }
        
        di as txt "  Found concerns in suit_case_`j'_1:"
        count if concern_1 == 1
        di as txt "    Type 1 (Work Environment): `r(N)'"
        count if concern_2 == 1
        di as txt "    Type 2 (Work-Life Balance): `r(N)'"
        count if concern_3 == 1
        di as txt "    Type 3 (Skill Fit): `r(N)'"
        count if concern_4 == 1
        di as txt "    Type 4 (Career Opportunities): `r(N)'"
        count if concern_5 == 1
        di as txt "    Type 5 (Personality Fit): `r(N)'"
        count if concern_6 == 1
        di as txt "    Type 6 (Lack of Knowledge): `r(N)'"
    }
}

// Check if any concerns were found
if `concerns_found' == 0 {
    di as error "WARNING: No concern variables found (suit_concerns_* or suit_case_*_1)."
    di as error "No concerns could be processed."
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
save "${processed_data}/PS_Students/7_ps_students.dta", replace

// Final report
di as txt "Cleaned concerns dataset saved to: ${processed_data}/PS_Students/7_ps_students.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Clean Concerns"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off