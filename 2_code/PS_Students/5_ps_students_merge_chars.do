********************************************************************************
// 5_ps_students_merge_chars.do
// Purpose : Merges student apprenticeship preference variables with the
//           apprenticeship characteristics dataset (skill intensity, female shares,
//           language and math requirements, etc.).
//           For each preference variable, the corresponding "_code" variable is
//           used as the merge key.
// 
// Author  : Your Name (BA Thesis FS25, dd.mm.yyyy)
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 17.0

cap log close
log using "${dodir_log}/ps_students_merge_chars.log", replace text

timer clear
timer on 1

set seed 123

********************************************************************************
// 1. PREPARE THE CHARACTERISTICS DATASET
//    This section loads the skill intensity data (from anforderungsprofile.ch
//    merged with LABB data), cleans it, collapses it by LABB code, and saves it
//    as a temporary file for merging.
********************************************************************************

di as txt "----- Preparing characteristics dataset -----"

use "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics", clear

    // Adjust LABB codes for specific occupations
replace labb_code = 1000004 if occname_skill == "Solarinstallateur/in EFZ"
replace labb_code = 1000005 if occname_skill == "Solarmonteur/-in EBA"

drop if missing(labb_code)
drop if labb_code == 384450         // drop old version of KV EBA (Profil B)

    // Collapse to LABB code level
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

    // Use occname from skill data if missing in LABB data
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

    // Add additional observations for "None", "Gymnasium", "Has contract",
    // and unknown apprenticeships (to facilitate cleaning of text entries)
set obs `=_N+3'
forvalues i = 1/3 {
    replace labb_code = -`i' in `=_N-3+`i''
}
replace occname_labb = "None"      in `=_N-2'
replace occname_labb = "Gymnasium"  in `=_N-1'
replace occname_labb = "Has contract" in `=_N'
set obs `=_N+4'
forvalues i = 1/4 {
    replace occname_labb = "Unknown(`i')" in `=_N-4+`i''
    replace labb_code = -3 - `i' in `=_N-4+`i''
}
set obs `=_N+1'
replace occname_labb = "Unknown (no apprenticeship)" in `=_N'
replace labb_code = -8 in `=_N'

    // Change names for consistency with your TA list if needed
replace occname_labb = "Kaufmann/-frau EFZ" if occname_labb == "Kaufmann/-frau EFZ E"
replace occname_labb = "Fachmann/-frau Apotheke EFZ" if occname_labb == "Pharma-Assistent/in EFZ"

tempfile appchardata
save `appchardata'

********************************************************************************
// 2. MERGE CHARACTERISTICS WITH STUDENT PREFERENCE VARIABLES
//    Here we merge the characteristics (by labb_code) into the students dataset.
//    For each student preference variable, we use the corresponding "_code" variable
//    as the key.
********************************************************************************

di as txt "----- Loading PS Students data -----"
use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

    // List of student preference variables to merge with characteristics.
    // Adjust this list according to your cleaned variables.
local pref_vars "prefchild_best_m prefchild_best_f prefchild_m prefchild_f"

foreach x of local pref_vars {

    di as txt "----- Merging characteristics for variable: `x' -----"

    // Generate a merge key using the corresponding _code variable.
    // It is assumed that the cleaning steps have created a variable named e.g.
    // "prefchild_best_m_code" for the variable "prefchild_best_m".
    capture confirm variable `x'_code
    if _rc {
        di as error "Variable `x'_code not found. Please check your cleaning steps."
        continue, break
    }
    gen labb_code = `x'_code

    merge m:1 labb_code using `appchardata', ///
         keep(match master) keepusing(isced2_code isced2_name female_grad skills_ave_math skills_ave_ownlang) nogen

        // Rename merged variables for clarity
    rename female_grad   female_share
    rename skills_ave_math math_req
    rename skills_ave_ownlang lang_req

    local skills_var_list isced2_code isced2_name female_share math_req lang_req
    foreach var of varlist `skills_var_list' {
         rename `var' `x'_`var'
    }

        // Optionally, create an "own gender share" variable.
    local x_lab: variable label `x'
    gen `x'_og_share = `x'_female_share if female == 1
    replace `x'_og_share = 1 - `x'_female_share if female == 0

        // Add informative labels.
    lab var `x'_female_share "`x_lab' female share"
    lab var `x'_math_req     "`x_lab' math requirements"
    lab var `x'_lang_req     "`x_lab' language requirements"
    lab var `x'_og_share     "`x_lab' own gender share"
    lab var `x'_isced2_code  "`x_lab' ISCED2 code"
    lab var `x'_isced2_name  "`x_lab' ISCED2 name"

    drop labb_code

    // If desired, you can check merge results here.
    di as txt "Completed merge for: `x'"
}

********************************************************************************
// 3. FINAL HOUSEKEEPING & SAVE
********************************************************************************

compress
save "${processed_data}/PS_Students/ps_stu_chars_merged.dta", replace

timer off 1
timer list

log close
