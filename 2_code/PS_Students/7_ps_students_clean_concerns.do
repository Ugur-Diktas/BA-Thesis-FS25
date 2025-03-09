********************************************************************************
* 7_ps_students_clean_concerns.do
* ------------------------------------------------------------------------------
* Data needed: ps_stu_cleaned.dta
* Data output: ps_stu_clean_concerns.dta
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

********************************************************************************
* 1. LOAD DATA
********************************************************************************
di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"
use "${processed_data}/PS_Students/6_ps_students.dta", clear
di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    error 602
}

********************************************************************************
* 2. CLEAN CONCERNS
********************************************************************************
/* Create binary indicators for different types of concerns related to apprenticeships */
forval i = 1/6 {
    gen concern_`i' = .
}

// Map concern types from suit_concerns variables to standardized concerns
forval j = 1/2 {
    capture confirm variable suit_concerns_`j'
    if !_rc {
        replace concern_1 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
        replace concern_2 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
        replace concern_3 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
        replace concern_4 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
        replace concern_5 = 1 if suit_concerns_`j' == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
        replace concern_6 = 1 if suit_concerns_`j' == "Ich weiß nicht viel über diesen Beruf"
    }
}

// If there are additional concern variables (like suit_case_* or similar), process them here
/* capture confirm variable suit_case_2_1
if !_rc {
    forval j = 1/3 {
        capture confirm variable suit_case_`j'_1
        if !_rc {
            replace concern_1 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich des <strong>Arbeitsumfelds</strong>"
            replace concern_2 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Work-Life-Balance</strong>"
            replace concern_3 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Fähigkeitenanpassung</strong>"
            replace concern_4 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Karrierechancen</strong>"
            replace concern_5 = 1 if suit_case_`j'_1 == "Bedenken hinsichtlich der <strong>Persönlichkeitsanpassung</strong>"
            replace concern_6 = 1 if suit_case_`j'_1 == "Ich weiß nicht viel über diesen Beruf"
        }
    }
} */

// Replace missing values with 0 (no concern)
forval i = 1/6 {
    replace concern_`i' = 0 if missing(concern_`i')
}

// Label the concern variables
local concern_1 "Work Environment Concerns"
local concern_2 "Work-Life Balance Concerns"
local concern_3 "Skill Fit Concerns"
local concern_4 "Career Opportunity Concerns"
local concern_5 "Personality Fit Concerns"
local concern_6 "Lack of Knowledge About Career"

forval i = 1/6 {
    label var concern_`i' "`concern_`i''"
}

********************************************************************************
* 3. FINAL HOUSEKEEPING & SAVE
********************************************************************************
compress
save "${processed_data}/PS_Students/7_ps_students.dta", replace

timer off 1
timer list
log close