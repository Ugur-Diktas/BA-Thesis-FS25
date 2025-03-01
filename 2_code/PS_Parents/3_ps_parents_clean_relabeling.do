********************************************************************************
* 3_ps_parents_clean_relabeling.do
*
* Purpose:
* - Load cleaned PS Parents data (duplicates removed).
* - Convert string variables to numeric (if needed).
* - Create duration variables from Qualtrics timing data.
* - Clean/rename background variables (e.g. home situation, track if available, 
*   parent education).
* - Save updated dataset.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 25.02.2025
* Version: Stata 18
********************************************************************************

*---------------------------------------------------------------
* 0. HOUSEKEEPING & LOGGING
*---------------------------------------------------------------
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
log using "${dodir_log}/ps_parents_clean_relabeling.log", replace text

timer clear
timer on 1

*---------------------------------------------------------------
* 1. LOAD CLEANED DATA
*---------------------------------------------------------------
di as txt "----- Loading dataset: ps_par_cleaned.dta -----"
quietly use "${processed_data}/PS_Parents/ps_par_cleaned.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_par_cleaned.dta."
    error 602
}

*---------------------------------------------------------------
* 2. CONVERT STRING VARIABLES & CREATE DURATION VARIABLES
*---------------------------------------------------------------

* Convert string variables to numeric if needed:
capture confirm variable contract
if !_rc {
    destring contract, replace
}
capture confirm variable female
if !_rc {
    destring female, replace
}

* Create indicator for EL (e.g. if contract == 1)
gen el = (contract == 1)
label var el "EL (1 if contract==1, else 0)"

* Create overall duration (minutes) if available:
capture confirm variable Duration__in_seconds_
if !_rc {
    gen duration_mins = Duration__in_seconds_ / 60
    label var duration_mins "Total duration (minutes)"
}

* Create page-level duration variables from Qualtrics timestamps:
ds t_*_First_Click
local first_vars `r(varlist)'
if "`first_vars'" != "" {
    foreach var of local first_vars {
        quietly count if missing(`var')
        if r(N) < _N {
            local base : subinstr local var "t_" "", all
            local base : subinstr local base "_First_Click" "", all
            capture confirm variable `base'_Page_Submit
            if !_rc {
                gen duration_`base' = (`base'_Page_Submit) / 60
                label var duration_`base' "Duration (minutes) for `base'"
            }
            else {
                di as error "Warning: Matching variable `base'_Page_Submit not found for `var'"
            }
        }
        else {
            di as txt "`var' is missing for all observations."
        }
    }
}

*---------------------------------------------------------------
* 3. RELABEL HOME SITUATION
*---------------------------------------------------------------
capture confirm variable home_sit
if !_rc {
    rename home_sit home_sit_par
    label define home_sit_par_lbl ///
        1 "Both parents" ///
        2 "Sometimes mother/father" ///
        3 "Only mother, contact father" ///
        4 "Only father, contact mother" ///
        5 "Only mother, no father" ///
        6 "Only father, no mother" ///
        7 "Other", replace
    label values home_sit_par home_sit_par_lbl
}

*---------------------------------------------------------------
* 4. RELABELING TRACKS & SCHOOL TRACK OVERVIEW
*---------------------------------------------------------------

// THIS CODE CAUSES THIS ERROR, SO SKIP IT FOR NOW:

/* 
count if !missing(canton) & (r_canton != canton & canton != "Grigioni")
canton ambiguous abbreviation	
*/

/* capture confirm variable track_1
if !_rc {
    decode track_1, gen(r_canton)
    decode track_2, gen(r_school_track_name)
    
    * Check if decoded canton differs from existing "canton" (unless canton is "Grigioni")
    count if !missing(canton) & (r_canton != canton & canton != "Grigioni")
    if r(N) > 0 {
         di as txt "Warning: " r(N) " observations: decoded canton does not match 'canton'. Replacing 'canton' with decoded value."
    }
    replace canton = r_canton
    drop r_canton

    * Check if decoded school track name differs from school_type (except when school_type is "Karışik")
    count if !missing(school_type) & (r_school_track_name != school_type & school_type != "Karışik")
    if r(N) > 0 {
         di as txt "Warning: " r(N) " observations: decoded school track name does not match 'school_type'. Replacing 'school_type' with decoded value."
    }
    rename r_school_track_name school_track_name
    replace school_type = school_track_name

    * Encode final track variable based on standardized values:
    gen track = .
    replace track = 1 if school_type == "low"
    replace track = 2 if school_type == "middle"
    replace track = 3 if school_type == "intermediate"
    replace track = 4 if school_type == "high"
    replace track = 5 if school_type == "mixed"
    replace track = 6 if school_type == "other"
    
    label define track_labels 1 "Low" 2 "Middle" 3 "Intermediate" 4 "High" 5 "Mixed" 6 "Other", replace
    label values track track_labels
    label var track "School track"
} */

*---------------------------------------------------------------
* 5. RELABEL PARENTS EDUCATION
*---------------------------------------------------------------
capture confirm variable educ_parent1
if !_rc {
    decode educ_parent1, gen(field_educ_1)
    decode educ_parent2, gen(field_educ_2)
    * If text versions exist, rename them:
    capture confirm variable educ_parent1_7_TEXT
    if !_rc {
        rename educ_parent1_7_TEXT field_educ_1_text
    }
    capture confirm variable educ_parent2_7_TEXT
    if !_rc {
        rename educ_parent2_7_TEXT field_educ_2_text
    }
    drop educ_parent1 educ_parent2
}
else {
    di as txt "No educ_parent1 found, skipping parent education relabeling."
}

*---------------------------------------------------------------
* 6. FINAL HOUSEKEEPING & SAVE
*---------------------------------------------------------------
di as txt "----- Compressing and saving dataset -----"
compress
save "${processed_data}/PS_Parents/ps_par_cleaned.dta", replace

timer off 1
timer list
log close
