********************************************************************************
* 3_ps_parents_clean_relabeling.do
*
* Purpose:
* - Load cleaned PS Parents data (duplicates removed).
* - Convert string variables to numeric (if needed).
* - Create duration variables from Qualtrics timing data.
* - Clean or rename certain background variables (home situation, track, etc.).
* - Save updated dataset.
*
* Author  : [Your Name / Team]
* Version : Stata 18
* Date    : [YYYY-MM-DD]
********************************************************************************

clear all
set more off
version 18.0

if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/3_ps_parents_clean_relabeling.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD CLEANED DATA
********************************************************************************

use "${processed_data}/PS_Parents/ps_par_cleaned.dta", clear
di as txt "Loaded ps_par_cleaned.dta: `c(N)' obs, `c(k)' vars"
if _N == 0 {
    di as error "ERROR: No observations found in ps_par_cleaned.dta."
    error 602
}

********************************************************************************
* 2. CONVERT STRING VARS & CREATE DURATION VARS
********************************************************************************

capture confirm variable contract
if !_rc {
    destring contract, replace
}
capture confirm variable female
if !_rc {
    destring female, replace
}

gen el = (contract == 1)
label var el "EL (1 if contract==1, else 0)"

capture confirm variable Duration__in_seconds_
if !_rc {
    gen duration_mins = Duration__in_seconds_ / 60
    label var duration_mins "Total duration (minutes)"
}

* Create page-level duration variables from Qualtrics timestamps
ds t_*_First_Click
local first_vars `r(varlist)'
foreach var of local first_vars {
    quietly count if missing(`var')
    if r(N) < _N {
        local base : subinstr local var "t_" "", all
        local base : subinstr local base "_First_Click" "", all
        capture confirm variable `base'_Page_Submit
        if !_rc {
            gen duration_`base' = (`base'_Page_Submit)/60
            label var duration_`base' "Duration (minutes) for `base'"
        }
    }
}

********************************************************************************
* 3. RELABEL HOME SITUATION
********************************************************************************

capture confirm variable home_sit
if !_rc {
    rename home_sit home_sit_par
    label define home_sit_par_lbl 1 "Both parents" 2 "Sometimes mother/father" 3 "Only mother, contact father" ///
        4 "Only father, contact mother" 5 "Only mother, no father" 6 "Only father, no mother" 7 "Other", replace
    label values home_sit_par home_sit_par_lbl
}

********************************************************************************
* 4. OPTIONAL: CLEAN/RENAME TRACK, EDUCATION, MIGRATION, ETC.
********************************************************************************

* Example for track variables
capture confirm variable track_1
if !_rc {
    * decode track_1, gen(decoded_track_1)
    * etc.
    di as txt "track_1 not found, skipping track cleaning."
}

* Example for parent education
capture confirm variable educ_parent1
if !_rc {
    di as txt "No educ_parent1 found, skipping..."
}
else {
    decode educ_parent1, gen(field_educ_1)
    decode educ_parent2, gen(field_educ_2)
    drop educ_parent1 educ_parent2
}

********************************************************************************
* 5. FINAL HOUSEKEEPING & SAVE
********************************************************************************

compress
save "${processed_data}/PS_Parents/ps_par_cleaned.dta", replace

