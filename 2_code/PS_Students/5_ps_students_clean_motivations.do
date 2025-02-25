*******************************************************************************
* 5_ps_students_clean_motivations.do
* Project:   PS Students Analysis
* Purpose:   Cleans and transforms motivational factors data
* Version:   2.0
* Author:    BA Thesis Team (Jelke Clarysse & Ugur Diktas)
* Date:      2025-03-01
* History:   Revised for efficiency and clarity
* Notes:     - Uses parallel processing structure
*            - Implements improved error handling
*            - Optimized loop structure for better performance
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 25.02.2025
* Version: Stata 18
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING
********************************************************************************

// Standard initialization
version 18.0
clear all
set more off
macro drop _all

// Log initialization
cap log close
log using "${dodir_log}/students_clean_motivations.log", replace text

// Performance monitoring
timer clear
timer on 1

*******************************************************************************
// 1. DATA VALIDATION
*******************************************************************************

quietly use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

// Dataset validation checks
if _N == 0 {
    di as error "ERROR: Empty dataset - ps_stu_cleaned.dta contains no observations"
    error 601
}

unab allvars: _all
if !`:list posof "motFactors_child_1" in allvars' {
    di as error "ERROR: Motivational factors variables missing"
    error 111
}

*******************************************************************************
// 2. MOTIVATIONAL FACTORS PROCESSING
*******************************************************************************

// Define factor mapping (German labels to factor numbers)
local factor_map ///
    "Der zukünftige <strong>Lohn</strong>"                   1  ///
    "Die zukünftige berufliche <strong>Flexibilität</strong>" 2  ///
    "Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>" 3  ///
    "Die <strong>mathematischen</strong> Anforderungen"       4  ///
    "Die <strong>sprachlichen</strong> Anforderungen"         5  ///
    "Die <strong>Empfehlungen der Eltern</strong>"            6  ///
    "Die <strong>Geschlechterzusammensetzung</strong>"        7  ///
    "Das Ausmass an <strong>sozialem Kontakt</strong>"         8  ///
    "Menschen zu <strong>helfen</strong>"                     9  ///
    "Der <strong>Arbeitsort</strong>"                         10 ///
    "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen" 11 ///
    "Die Aussicht auf <strong>Beförderungen</strong>"          12 ///
    "Ihre persönlichen <strong>Interessen</strong>"            13

// Create empty factor variables
foreach role in child mother father {
    forval i = 1/13 {
        gen `role'_fac_`i' = 0
        label variable `role'_fac_`i' "`role' motivation factor `i'"
    }
}

// Populate factor variables
quietly {
    forval j = 1/12 {
        local current_label : label motFactor`j'
        
        // Find matching factor number
        local found = 0
        forval k = 1/13 {
            local map_index = (`k' - 1) * 2 + 1
            if `"`current_label'"' == `"`: word `map_index' of `factor_map''"' {
                local factor_num = `: word `= `map_index' + 1' of `factor_map''
                local found = 1
                continue, break
            }
        }
        
        if `found' {
            foreach role in child mother father {
                replace `role'_fac_`factor_num' = 1 ///
                    if motFactors_`role'_`j' == 1
            }
        }
        else {
            di as error "WARNING: Unmapped label found: `current_label'"
        }
    }
}

*******************************************************************************
// 3. VARIABLE LABELING
*******************************************************************************

// English labels
local factor_labels ///
    1  "Future salary" ///
    2  "Career flexibility" ///
    3  "Further education opportunities" ///
    4  "Mathematical requirements" ///
    5  "Language requirements" ///
    6  "Parental recommendations" ///
    7  "Gender composition" ///
    8  "Social contact level" ///
    9  "Helping others" ///
    10 "Workplace type" ///
    11 "Contract acquisition likelihood" ///
    12 "Promotion prospects" ///
    13 "Personal interests"

foreach role in child mother father {
    forval i = 1/13 {
        local label_text : label factor_labels `i'
        label variable `role'_fac_`i' "`role': `label_text'"
    }
}

*******************************************************************************
// 4. FINALIZATION
*******************************************************************************

// Cleanup and validation
capture confirm variable child_fac_1
if _rc {
    di as error "ERROR: Factor variables not created properly"
    error 459
}

// Dataset preservation
compress
save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

// Performance report
timer off 1
timer list 1
log close
