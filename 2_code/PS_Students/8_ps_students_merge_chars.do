********************************************************************************
* 8_ps_students_merge_chars.do
* ------------------------------------------------------------------------------
* Data needed: ps_stu_clean_concerns.dta
* Data output: ps_stu_chars_merged.dta
* Purpose:
*   - Merges student apprenticeship preference variables with the apprenticeship
*     characteristics dataset. This characteristics dataset contains information 
*     on skill intensity, female shares, math and language requirements, and ISCED2 
*     classifications derived from the raw skill intensity data.
*   - For each student preference variable (e.g., "prefchild_best_m", "prefchild_best_f", 
*     "prefchild_m", "prefchild_f"), the corresponding "_code" variable is used as the 
*     merge key. The merged characteristics (such as ISCED2 code, female share, math 
*     and language requirements) are then renamed with a prefix corresponding to the 
*     original preference variable.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
********************************************************************************

//----------------------------------------------------------------------------
// 0. HOUSEKEEPING
//----------------------------------------------------------------------------
clear all
set more off
version 18.0

// Enable/disable trace based on debug flag
if ("${debug}" == "yes") {
    set trace on
} 
else {
    set trace off
}

// Start logging
cap log close
log using "${dodir_log}/8_ps_students_merge_chars.log", replace text

timer clear
timer on 1

//----------------------------------------------------------------------------
// 1. PREPARE THE CHARACTERISTICS DATASET
//    Load, clean, and collapse the raw skill intensity data by LABB code, then 
//    save it as a temporary file for later merging.
//----------------------------------------------------------------------------
di as txt "----- Preparing characteristics dataset -----"

use "${processed_data}/PS_Students/7_ps_students.dta", clear

// Adjust LABB codes for specific occupations
replace labb_code = 1000004 if occname_skill == "Solarinstallateur/in EFZ"
replace labb_code = 1000005 if occname_skill == "Solarmonteur/-in EBA"

// Remove observations with missing LABB codes and drop the old KV EBA version
drop if missing(labb_code)
drop if labb_code == 384450

// Collapse to LABB code level (handle multiple specializations)
replace labb_code = 1000002 if strpos(occname_labb, "Gebäudetechnikplaner/in ")
replace occname_labb = "Gebäudetechnikplaner/in EFZ" if strpos(occname_labb, "Gebäudetechnikplaner/in ")
egen tag = tag(labb_code)
bys labb_code: egen nofspecs = total(labb_first)
bys labb_code: egen total_grad_allspecs = total(total_grad) if nofspecs > 1
replace total_grad_allspecs = total_grad if nofspecs == 1
drop total_grad
rename total_grad_allspecs total_grad

bys labb_code: egen flag_total_grad_miss = total(missing(total_grad))
bys labb_code: replace flag_total_grad_miss = flag_total_grad_miss == _N
replace total_grad = 1 if flag_total_grad_miss == 1

collapse (mean) skills_ave_math skills_ave_ownlang ///
         skills_ave_forlang skills_ave_science skills_ave_all ///
         female_grad total_grad expearn immigrant_grad ///
         (first) occname_skill occname_labb flag_total_grad_miss ///
         isced4_code isced4_name isced3_code isced3_name isced2_code ///
         isced2_name job_ch_isco_19 [w=total_grad], by(labb_code)

replace total_grad = . if flag_total_grad_miss == 1
drop flag_total_grad_miss

// Use occname from skill data when LABB data is missing
replace occname_labb = occname_skill if missing(occname_labb)
drop occname_skill

// Add an observation for "Entwickler/in Digitales Business EFZ"
drop if labb_code == 381400
local nplusone = _N + 1
set obs `nplusone'
replace occname_labb = "Entwickler/in Digitales Business EFZ" in `nplusone'
replace labb_code = 1000001 in `nplusone'
su skills_ave_math if occname_labb == "Informatiker/in EFZ"
replace skills_ave_math = r(mean) in `nplusone'
su female_grad if occname_labb == "Informatiker/in EFZ"
replace female_grad = r(mean) in `nplusone'

// Add extra observations for "None", "Gymnasium", "Has contract", and unknown responses
set obs `=_N+3'
forvalues i = 1/3 {
    replace labb_code = -`i' in `=_N-3+`i''
}
replace occname_labb = "None" in `=_N-2'
replace occname_labb = "Gymnasium" in `=_N-1'
replace occname_labb = "Has contract" in `=_N'

set obs `=_N+4'
forvalues i = 1/4 {
    replace occname_labb = "Unknown(`i')" in `=_N-4+`i''
    replace labb_code = -3 - `i' in `=_N-4+`i''
}
set obs `=_N+1'
replace occname_labb = "Unknown (no apprenticeship)" in `=_N'
replace labb_code = -8 in `=_N'

// (Optional) Adjust occupation names for consistency
replace occname_labb = "Kaufmann/-frau EFZ" if occname_labb == "Kaufmann/-frau EFZ E"
replace occname_labb = "Fachmann/-frau Apotheke EFZ" if occname_labb == "Pharma-Assistent/in EFZ"

// Save prepared characteristics to a temporary file
tempfile appchardata
save `appchardata'

//----------------------------------------------------------------------------
// 2. MERGE CHARACTERISTICS WITH STUDENT PREFERENCE VARIABLES
//    For each student preference variable, use the corresponding "_code" variable 
//    as the merge key to append apprenticeship characteristics.
//----------------------------------------------------------------------------
di as txt "----- Loading PS Students data -----"
use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

// Define list of student preference variables (adjust this list if needed)
local pref_vars "prefchild_best_m prefchild_best_f prefchild_m prefchild_f"

foreach x of local pref_vars {
    di as txt "----- Merging characteristics for variable: `x' -----"
    
    // Check for the corresponding _code variable
    capture confirm variable `x'_code
    if _rc {
        di as error "Variable `x'_code not found. Please check your cleaning steps."
        continue
    }
    
    // Create a temporary merge key from the _code variable
    gen labb_code = `x'_code

    merge m:1 labb_code using `appchardata', ///
         keep(match master) ///
         keepusing(isced2_code isced2_name female_grad skills_ave_math skills_ave_ownlang) ///
         nogen

    // Rename merged variables for clarity
    rename female_grad   female_share
    rename skills_ave_math math_req
    rename skills_ave_ownlang lang_req

    // Rename merged variables with a prefix corresponding to the preference variable
    local skills_var_list isced2_code isced2_name female_share math_req lang_req
    foreach var of varlist `skills_var_list' {
         rename `var' `x'_`var'
    }

    // Optionally, create an "own gender share" variable based on the student's gender
    // (Assumes the student dataset contains a variable "female": 1 for female, 0 for male)
    local x_lab: variable label `x'
    gen `x'_og_share = `x'_female_share if female == 1
    replace `x'_og_share = 1 - `x'_female_share if female == 0

    // Add informative labels to the merged variables
    lab var `x'_female_share  "`x_lab' female share"
    lab var `x'_math_req      "`x_lab' math requirements"
    lab var `x'_lang_req      "`x_lab' language requirements"
    lab var `x'_og_share      "`x_lab' own gender share"
    lab var `x'_isced2_code   "`x_lab' ISCED2 code"
    lab var `x'_isced2_name   "`x_lab' ISCED2 name"

    drop labb_code

    di as txt "Completed merge for: `x'"
}

//----------------------------------------------------------------------------
// 3. FINAL HOUSEKEEPING & SAVE
//----------------------------------------------------------------------------
compress
save "${processed_data}/PS_Students/8_ps_students.dta", replace

timer off 1
timer list

log close
