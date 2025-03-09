********************************************************************************
* 8_ps_parents_merge_chars.do
* ------------------------------------------------------------------------------
* Data needed: 7_ps_parents.dta
* Data output: 8_ps_parents.dta
* Purpose:
*   - Merge the PS Parents dataset with apprenticeship characteristics
*     (skill intensity, female share, math and language requirements).
*   - For each parental preference variable, use the corresponding "_code"
*     variable as the merge key.
*   - Save the updated dataset.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
********************************************************************************

/*

This file doesn't work yet. See 8_ps_parents_merge_chars.log for the error message.

*/

********************************************************************************
// 0. HOUSEKEEPING
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
log using "${dodir_log}/8_ps_parents_merge_chars.log", replace text

timer clear
timer on 1

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Parents Merge Characteristics"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
// 1. PREPARE THE CHARACTERISTICS DATASET
********************************************************************************
di as txt "----- Preparing apprenticeship characteristics dataset -----"

// Check if characteristic dataset exists
capture confirm file "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics.dta"
if _rc {
    di as error "ERROR: Apprenticeship characteristics dataset not found:"
    di as error "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics.dta"
    exit 601
}

// Create a temporary dataset with apprenticeship characteristics
preserve
    use "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics.dta", clear
    di as txt "Loaded characteristics dataset with `c(N)' observations."
    
    // Create a specific variable name for labb code to avoid ambiguity
    rename labb_code temp_labb_code
    
    // Fix specific apprenticeships
    di as txt "Fixing specialized apprenticeships..."
    replace temp_labb_code = 1000004 if occname_skill == "Solarinstallateur/in EFZ"
    replace temp_labb_code = 1000005 if occname_skill == "Solarmonteur/-in EBA"
    
    // Clean data
    di as txt "Cleaning characteristics data..."
    drop if missing(temp_labb_code)
    count if temp_labb_code == 384450
    if r(N) > 0 {
        di as txt "Dropping `r(N)' observations with labb code 384450 (old KV EBA version)."
        drop if temp_labb_code == 384450  // Old KV EBA version
    }
    
    // Standardize Gebäudetechnikplaner entries
    di as txt "Standardizing Gebäudetechnikplaner entries..."
    count if strpos(occname_labb, "Gebäudetechnikplaner/in ")
    if r(N) > 0 {
        di as txt "Found `r(N)' Gebäudetechnikplaner entries, standardizing."
        replace temp_labb_code = 1000002 if strpos(occname_labb, "Gebäudetechnikplaner/in ")
        replace occname_labb = "Gebäudetechnikplaner/in EFZ" if strpos(occname_labb, "Gebäudetechnikplaner/in ")
    }
    
    // Handle specializations
    di as txt "Processing specializations..."
    egen tag = tag(temp_labb_code)
    bys temp_labb_code: egen nofspecs = total(labb_first)
    bys temp_labb_code: egen total_grad_allspecs = total(total_grad) if nofspecs > 1
    replace total_grad_allspecs = total_grad if nofspecs == 1
    
    // Rename for clarity
    drop total_grad
    rename total_grad_allspecs total_grad
    
    // Handle missing totals
    di as txt "Handling missing total graduates..."
    bys temp_labb_code: egen flag_total_grad_miss = total(missing(total_grad))
    bys temp_labb_code: replace flag_total_grad_miss = flag_total_grad_miss == _N
    count if flag_total_grad_miss == 1
    local missing_grad_count = r(N)
    if `missing_grad_count' > 0 {
        di as txt "Found `missing_grad_count' entries with missing total graduates, setting to 1."
        replace total_grad = 1 if flag_total_grad_miss == 1
    }
    
    // Collapse to get one entry per LABB code
    di as txt "Collapsing to one entry per LABB code..."
    collapse (mean) skills_ave_math skills_ave_ownlang ///
             skills_ave_forlang skills_ave_science skills_ave_all ///
             female_grad total_grad expearn immigrant_grad ///
             (first) occname_skill occname_labb flag_total_grad_miss ///
             isced4_code isced4_name isced3_code isced3_name isced2_code ///
             isced2_name job_ch_isco_19 [w=total_grad], by(temp_labb_code)
    
    di as txt "Collapsed to `c(N)' unique LABB codes."
    
    // Final cleaning         
    replace total_grad = . if flag_total_grad_miss == 1
    drop flag_total_grad_miss
    
    // Use skill name when LABB name is missing
    replace occname_labb = occname_skill if missing(occname_labb)
    drop occname_skill
    
    // Add digital business developer (newer profession)
    di as txt "Adding special case: Digital Business Developer..."
    drop if temp_labb_code == 381400
    local nplusone = _N + 1
    set obs `nplusone'
    replace occname_labb = "Entwickler/in Digitales Business EFZ" in `nplusone'
    replace temp_labb_code = 1000001 in `nplusone'
    
    // Copy values from Informatiker for the new entry
    sum skills_ave_math if occname_labb == "Informatiker/in EFZ"
    replace skills_ave_math = r(mean) in `nplusone'
    sum female_grad if occname_labb == "Informatiker/in EFZ"
    replace female_grad = r(mean) in `nplusone'
    
    // Add special codes for non-apprenticeship options
    di as txt "Adding special codes for non-apprenticeship options..."
    set obs `=_N+3'
    forvalues i = 1/3 {
        replace temp_labb_code = -`i' in `=_N-3+`i''
    }
    replace occname_labb = "None" in `=_N-2'
    replace occname_labb = "Gymnasium" in `=_N-1'
    replace occname_labb = "Has contract" in `=_N'
    
    // Add codes for unknown entries
    di as txt "Adding codes for unknown/unmatched entries..."
    set obs `=_N+4'
    forvalues i = 1/4 {
        replace occname_labb = "Unknown(`i')" in `=_N-4+`i''
        replace temp_labb_code = -3 - `i' in `=_N-4+`i''
    }
    set obs `=_N+1'
    replace occname_labb = "Unknown (no apprenticeship)" in `=_N'
    replace temp_labb_code = -8 in `=_N'
    
    // Fix inconsistent naming
    di as txt "Standardizing common occupation names..."
    replace occname_labb = "Kaufmann/-frau EFZ" if occname_labb == "Kaufmann/-frau EFZ E"
    replace occname_labb = "Fachmann/-frau Apotheke EFZ" if occname_labb == "Pharma-Assistent/in EFZ"
    
    // Save temporary characteristics file for merging
    di as txt "Characteristics dataset prepared with `c(N)' entries."
    tempfile appchardata
    save `appchardata'
restore

********************************************************************************
// 2. LOAD PARENT DATA
********************************************************************************
di as txt "----- Loading parent data -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Parents/7_ps_parents.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Parents/7_ps_parents.dta"
    di as error "Run 7_ps_parents_clean_concerns.do first."
    exit 601
}

use "${processed_data}/PS_Parents/7_ps_parents.dta", clear
di as txt "Loaded parent data with `c(N)' observations and `c(k)' variables."

********************************************************************************
// 3. MERGE PARENT PREFERENCES WITH CHARACTERISTICS
********************************************************************************
di as txt "----- Merging parent preferences with characteristics -----"

// Define list of preference variables to process - specifically look for plan variable
di as txt "Checking available code variables..."
ds *code*
local code_vars = r(varlist)
di as txt "Found the following code variables: `code_vars'"

// Try to merge plan_code first
capture confirm variable plan_code
if !_rc {
    di as txt "Processing plan code variable..."
    // Check if it has values
    count if !missing(plan_code)
    if r(N) > 0 {
        di as txt "  Found `r(N)' non-missing values in plan_code."
        
        // Create merge key variable - use unique name to avoid conflicts
        gen merge_key_plan = plan_code
        
        // Merge with apprenticeship characteristics
        di as txt "  Merging using plan_code..."
        merge m:1 merge_key_plan using `appchardata', ///
            keep(match master) nogen
        
        // Count merged observations
        count if !missing(female_grad) & !missing(plan_code)
        local merged_count = r(N)
        
        if `merged_count' > 0 {
            di as txt "  Successfully merged characteristics for `merged_count' observations using plan_code."
            
            // Rename merged variables with plan prefix
            rename female_grad plan_female_share
            rename skills_ave_math plan_math_req
            rename skills_ave_ownlang plan_lang_req
            
            // Create own-gender share variable based on parent gender
            capture confirm variable female
            if !_rc {
                gen plan_og_share = plan_female_share if female == 1
                replace plan_og_share = 1 - plan_female_share if female == 0
                label var plan_og_share "Plan own gender share"
            }
            
            // Add labels
            label var plan_female_share "Plan female share"
            label var plan_math_req "Plan math requirements"
            label var plan_lang_req "Plan language requirements"
        }
        else {
            di as txt "  No observations were merged using plan_code."
        }
        
        // Clean up
        drop merge_key_plan
    }
    else {
        di as txt "  Variable plan_code has no non-missing values."
    }
}

// Try to use labb_code_2
capture confirm variable labb_code_2
if !_rc {
    di as txt "Processing labb_code_2 variable..."
    // Check if it has values
    count if !missing(labb_code_2)
    if r(N) > 0 {
        di as txt "  Found `r(N)' non-missing values in labb_code_2."
        
        // Create merge key variable - use unique name to avoid conflicts
        gen merge_key_labb = labb_code_2
        
        // Merge with apprenticeship characteristics
        di as txt "  Merging using labb_code_2..."
        merge m:1 merge_key_labb using `appchardata', ///
            keep(match master) nogen
        
        // Count merged observations
        count if !missing(female_grad) & !missing(labb_code_2)
        local merged_count_labb = r(N)
        
        if `merged_count_labb' > 0 {
            di as txt "  Successfully merged characteristics for `merged_count_labb' observations using labb_code_2."
            
            // Check if plan variables already exist from previous merge
            capture confirm variable plan_female_share
            if _rc {
                // Variables don't exist yet, create them
                rename female_grad plan_female_share
                rename skills_ave_math plan_math_req
                rename skills_ave_ownlang plan_lang_req
                
                // Create own-gender share variable based on parent gender
                capture confirm variable female
                if !_rc {
                    gen plan_og_share = plan_female_share if female == 1
                    replace plan_og_share = 1 - plan_female_share if female == 0
                    label var plan_og_share "Plan own gender share"
                }
                
                // Add labels
                label var plan_female_share "Plan female share"
                label var plan_math_req "Plan math requirements"
                label var plan_lang_req "Plan language requirements"
            }
            else {
                // Variables already exist, update missing values
                replace plan_female_share = female_grad if missing(plan_female_share)
                replace plan_math_req = skills_ave_math if missing(plan_math_req)
                replace plan_lang_req = skills_ave_ownlang if missing(plan_lang_req)
                
                capture confirm variable plan_og_share
                if !_rc {
                    // Update own-gender share
                    capture confirm variable female
                    if !_rc {
                        replace plan_og_share = female_grad if missing(plan_og_share) & female == 1
                        replace plan_og_share = 1 - female_grad if missing(plan_og_share) & female == 0
                    }
                }
                
                // Drop duplicated variables
                drop female_grad skills_ave_math skills_ave_ownlang
            }
        }
        else {
            di as txt "  No observations were merged using labb_code_2."
        }
        
        // Clean up
        drop merge_key_labb
    }
    else {
        di as txt "  Variable labb_code_2 has no non-missing values."
    }
}

// If we didn't merge anything, flag it
capture confirm variable plan_female_share
if _rc {
    di as txt "WARNING: No characteristics were merged. Adding merge failed flag."
    gen byte chars_merge_failed = 1
    label var chars_merge_failed "Flag indicating characteristics merge failed"
}

********************************************************************************
// 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************
di as txt "----- Compressing and saving dataset -----"

// Compress and save
compress
save "${processed_data}/PS_Parents/8_ps_parents.dta", replace

// Final report
di as txt "Merged characteristics dataset saved to: ${processed_data}/PS_Parents/8_ps_parents.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Parents Merge Characteristics"
di as txt "======================================================="

timer off 1
timer list

log close
set trace off