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
* Last edit: 11.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
********************************************************************************

//----------------------------------------------------------------------------
// 0. HOUSEKEEPING
//----------------------------------------------------------------------------
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

//----------------------------------------------------------------------------
// 1. PREPARE THE CHARACTERISTICS DATASET
//----------------------------------------------------------------------------
di as txt "----- Preparing apprenticeship characteristics dataset -----"

// Create a temporary dataset with apprenticeship characteristics
preserve
    use "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics.dta", clear
    
    // Create a specific variable name for labb code to avoid ambiguity
    rename labb_code temp_labb_code
    
    // Fix specific apprenticeships
    replace temp_labb_code = 1000004 if occname_skill == "Solarinstallateur/in EFZ"
    replace temp_labb_code = 1000005 if occname_skill == "Solarmonteur/-in EBA"
    
    // Clean data
    drop if missing(temp_labb_code)
    drop if temp_labb_code == 384450  // Old KV EBA version
    
    // Standardize Gebäudetechnikplaner entries
    replace temp_labb_code = 1000002 if strpos(occname_labb, "Gebäudetechnikplaner/in ")
    replace occname_labb = "Gebäudetechnikplaner/in EFZ" if strpos(occname_labb, "Gebäudetechnikplaner/in ")
    
    // Handle specializations
    egen tag = tag(temp_labb_code)
    bys temp_labb_code: egen nofspecs = total(labb_first)
    bys temp_labb_code: egen total_grad_allspecs = total(total_grad) if nofspecs > 1
    replace total_grad_allspecs = total_grad if nofspecs == 1
    
    // Rename for clarity
    drop total_grad
    rename total_grad_allspecs total_grad
    
    // Handle missing totals
    bys temp_labb_code: egen flag_total_grad_miss = total(missing(total_grad))
    bys temp_labb_code: replace flag_total_grad_miss = flag_total_grad_miss == _N
    replace total_grad = 1 if flag_total_grad_miss == 1
    
    // Collapse to get one entry per LABB code
    collapse (mean) skills_ave_math skills_ave_ownlang ///
             skills_ave_forlang skills_ave_science skills_ave_all ///
             female_grad total_grad expearn immigrant_grad ///
             (first) occname_skill occname_labb flag_total_grad_miss ///
             isced4_code isced4_name isced3_code isced3_name isced2_code ///
             isced2_name job_ch_isco_19 [w=total_grad], by(temp_labb_code)
    
    // Final cleaning         
    replace total_grad = . if flag_total_grad_miss == 1
    drop flag_total_grad_miss
    
    // Use skill name when LABB name is missing
    replace occname_labb = occname_skill if missing(occname_labb)
    drop occname_skill
    
    // Add digital business developer (newer profession)
    drop if temp_labb_code == 381400
    local nplusone = _N + 1
    set obs `nplusone'
    replace occname_labb = "Entwickler/in Digitales Business EFZ" in `nplusone'
    replace temp_labb_code = 1000001 in `nplusone'
    
    // Copy values from Informatiker for the new entry
    su skills_ave_math if occname_labb == "Informatiker/in EFZ"
    replace skills_ave_math = r(mean) in `nplusone'
    su female_grad if occname_labb == "Informatiker/in EFZ"
    replace female_grad = r(mean) in `nplusone'
    
    // Add special codes for non-apprenticeship options
    set obs `=_N+3'
    forvalues i = 1/3 {
        replace temp_labb_code = -`i' in `=_N-3+`i''
    }
    replace occname_labb = "None" in `=_N-2'
    replace occname_labb = "Gymnasium" in `=_N-1'
    replace occname_labb = "Has contract" in `=_N'
    
    // Add codes for unknown entries
    set obs `=_N+4'
    forvalues i = 1/4 {
        replace occname_labb = "Unknown(`i')" in `=_N-4+`i''
        replace temp_labb_code = -3 - `i' in `=_N-4+`i''
    }
    set obs `=_N+1'
    replace occname_labb = "Unknown (no apprenticeship)" in `=_N'
    replace temp_labb_code = -8 in `=_N'
    
    // Fix inconsistent naming
    replace occname_labb = "Kaufmann/-frau EFZ" if occname_labb == "Kaufmann/-frau EFZ E"
    replace occname_labb = "Fachmann/-frau Apotheke EFZ" if occname_labb == "Pharma-Assistent/in EFZ"
    
    // Save temporary characteristics file for merging
    tempfile appchardata
    save `appchardata'
restore

//----------------------------------------------------------------------------
// 2. LOAD PARENTS DATA
//----------------------------------------------------------------------------
di as txt "----- Loading parent data -----"
use "${processed_data}/PS_Parents/7_ps_parents.dta", clear

//----------------------------------------------------------------------------
// 3. MERGE PARENT PREFERENCES WITH CHARACTERISTICS
//----------------------------------------------------------------------------
// Define list of preference variables to process
local pref_vars "prefown_m prefown_f prefchild_m prefchild_f"

// Process each preference variable
foreach p of local pref_vars {
    di as txt "----- Processing variable: `p' -----"
    
    // Check if the code variable exists
    capture confirm variable `p'_code
    if _rc {
        di as error "Variable `p'_code not found. Skipping."
        continue
    }
    
    // Create merge key variable - use unique name to avoid conflicts
    gen temp_merge_key = `p'_code
    
    // Merge with apprenticeship characteristics
    merge m:1 temp_merge_key using `appchardata', ///
        keep(match master) nogen
    
    // Clean up temporary merge key
    drop temp_merge_key
    
    // Rename merged variables with the preference prefix for clarity
    rename female_grad   `p'_female_share
    rename skills_ave_math `p'_math_req
    rename skills_ave_ownlang `p'_lang_req
    
    // Create own-gender share variable based on parent gender
    local p_lab: variable label `p'
    gen `p'_og_share = `p'_female_share if female == 1
    replace `p'_og_share = 1 - `p'_female_share if female == 0
    
    // Label the new variables
    label var `p'_female_share  "`p_lab' female share"
    label var `p'_math_req      "`p_lab' math requirements"
    label var `p'_lang_req      "`p_lab' language requirements"
    label var `p'_og_share      "`p_lab' own gender share"
    
    di as txt "Completed merge for: `p'"
}

//----------------------------------------------------------------------------
// 4. FINAL HOUSEKEEPING & SAVE
//----------------------------------------------------------------------------
compress
save "${processed_data}/PS_Parents/8_ps_parents.dta", replace

timer off 1
timer list

log close