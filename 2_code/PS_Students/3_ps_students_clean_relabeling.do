********************************************************************************
* 3_ps_students_clean_relabeling.do
* ------------------------------------------------------------------------------
* Data needed: ps_stu_cleaned.dta
* Data output: ps_stu_cleaned.dta
* Purpose:
*   - Load the cleaned PS Students dataset (duplicates removed and test answers dropped).
*   - Convert string variables (e.g., contract, female) to numeric and recode as needed.
*   - Create new variables (e.g., el, duration_mins, and duration_* variables).
*   - Standardize track/canton via merge with new_drill_down_school_tracks.dta.
*   - Rename and label variables for home situation, tracks, math/language, parent education,
*     and occupational preferences.
*   - Drop unneeded variables.
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

* Set tracing based on debug flag:
if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/3_ps_students_clean_relabeling.log", replace text

timer clear
timer on 1

* Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Clean Relabeling"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************
di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"

* Check if input file exists
capture confirm file "${processed_data}/PS_Students/2_ps_students.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Students/2_ps_students.dta"
    di as error "Run 2_ps_students_remove_duplicates.do first."
    exit 601
}

use "${processed_data}/PS_Students/2_ps_students.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    exit 602
}

********************************************************************************
* 2. CONVERT STRING VARIABLES & CREATE DURATION VARIABLES
********************************************************************************
di as txt "----- Converting string variables & creating duration variables -----"

*--- Convert string variables to numeric if needed ---
foreach var in contract female {
    capture confirm variable `var'
    if !_rc {
        capture confirm string variable `var'
        if !_rc {
            di as txt "Converting `var' from string to numeric..."
            destring `var', replace
            di as txt "  Conversion complete."
        }
        else {
            di as txt "Variable `var' is already numeric, no conversion needed."
        }
    }
    else {
        di as txt "Variable `var' not found in dataset, skipping."
    }
}

*--- Create indicator for EL ---
di as txt "Creating EL indicator variable..."
capture confirm variable el
if _rc == 0 {
    di as txt "Variable 'el' already exists, updating values."
    replace el = (contract == 1)
} 
else {
    di as txt "Creating new 'el' variable."
    gen el = (contract == 1)
}
label var el "EL (1 if contract==1, else 0)"

*--- Create overall duration (minutes) if available ---
di as txt "Creating duration_mins variable..."
capture confirm variable Duration__in_seconds_
if !_rc {
    capture confirm variable duration_mins
    if _rc == 0 {
        di as txt "Variable 'duration_mins' already exists, updating values."
        replace duration_mins = Duration__in_seconds_ / 60
    } 
    else {
        di as txt "Creating new 'duration_mins' variable."
        gen duration_mins = Duration__in_seconds_ / 60
    }
    label var duration_mins "Total duration (minutes)"
}
else {
    di as txt "Variable 'Duration__in_seconds_' not found, cannot create duration_mins."
}

*--- Create duration variables from click timestamps ---
di as txt "Creating page-specific duration variables..."
ds t_*_First_Click
local first_click_vars `r(varlist)'

if "`first_click_vars'" != "" {
    di as txt "Found `=wordcount("`first_click_vars'")' First_Click variables."
    
    foreach var of local first_click_vars {
        * Extract base name without prefix and suffix
        local base = subinstr("`var'", "t_", "", 1)
        local base = subinstr("`base'", "_First_Click", "", 1)
        
        * Check for corresponding Page_Submit variable
        capture confirm variable `base'_Page_Submit
        if !_rc {
            di as txt "Creating duration variable for `base'..."
            capture gen duration_`base' = (`base'_Page_Submit) / 60
            if _rc {
                di as error "Error creating duration_`base': `_rc'"
            }
            else {
                di as txt "  Created duration_`base'."
            }
        }
    }
}
else {
    di as txt "No t_*_First_Click variables found, skipping duration variable creation."
}

*--- Label the duration variables ---
di as txt "Labeling duration variables..."

* Map of duration variable names to labels
local duration_labels = "duration_consent1:Consent page 1;duration_sure:Sure;duration_consent2:Consent page 2;" + ///
                       "duration_background_1_:Background page 1;duration_background_2_:Background page 2;" + ///
                       "duration_child_prefs_1:Own prefs page 1;duration_child_prefs_2:Own prefs page 2;" + ///
                       "duration_mother_prefs_1:Mothers prefs page 1;duration_mother_prefs_2:Mother's prefs page 2;" + ///
                       "duration_father_prefs_1:Father's prefs page 1;duration_father_prefs_2:Father's prefs page 2;" + ///
                       "duration_motivation_child:Own motivation factors;duration_motivation_mother:Mother's motivation factors;" + ///
                       "duration_motivation_father:Father's motivation factors;duration_beliefs_1_:Beliefs page 1;" + ///
                       "duration_beliefs_2_:Beliefs page 2;duration_debriefing_1:Debriefing page 1;" + ///
                       "duration_debriefing_2:Debriefing page 2;duration_contract_occ_:Contract occupation;" + ///
                       "duration_ta_occs_:TA occupations;duration_reject_occs_:Rejection occupations;" + ///
                       "duration_apply_:Application occupations;duration_offers_:Offers occupations;" + ///
                       "duration_perc_contract_:Advantages/disadvantages of contract occ;" + ///
                       "duration_perc_disadv_hc_:Advantages/disadvantages of HC;" + ///
                       "duration_suggest_hc_:Suggestion HC (no contract or TA);" + ///
                       "duration_no_consider_hc_:Why considered or not HC;" + ///
                       "duration_suggest_hc_2_:Suggestion HC (no contract, but TA);" + ///
                       "duration_no_appr_hc_:Why no TA in HC;" + ///
                       "duration_concern_contract_:Others' concerns p1 (contract);" + ///
                       "duration_reason_concern_:Others' concerns p2 (contract);" + ///
                       "duration_social_skills_:Social skills;duration_gender_id:Gender identity;" + ///
                       "duration_belief_society_:Societal perception;duration_ses_1:SES page 1;" + ///
                       "duration_ses_2_:SES page 2;duration_end:Final page"

* Parse the duration_labels string and apply labels
foreach pair of local duration_labels {
    if strpos("`pair'", ":") > 0 {
        local varname = substr("`pair'", 1, strpos("`pair'", ":") - 1)
        local lbl = substr("`pair'", strpos("`pair'", ":") + 1, .)
        
        capture confirm variable `varname'
        if !_rc {
            label variable `varname' "`lbl'"
            di as txt "  Labeled `varname' as '`lbl''"
        }
    }
}

********************************************************************************
* 3. CLEAN HOME SITUATION
********************************************************************************
di as txt "----- Cleaning home situation variables -----"

capture confirm variable home_sit
if !_rc {
    di as txt "Renaming and labeling home_sit variable..."
    rename home_sit home_sit_stu
    
    * Define label for home situation
    capture label define home_sit_stu_lab ///
        1 "Both parents" ///
        2 "Sometimes mother, sometimes father" ///
        3 "Only mother, contact with father" ///
        4 "Only father, contact with mother" ///
        5 "Only mother, no contact with father" ///
        6 "Only father, no contact with mother" ///
        7 "Other", replace
        
    * Apply label
    label values home_sit_stu home_sit_stu_lab
    di as txt "  home_sit_stu labeled with `=r(k)' categories."
}
else {
    di as txt "home_sit variable not found, skipping home situation cleaning."
}

********************************************************************************
* 4. RELABELING TRACKS & SCHOOL TRACK OVERVIEW
********************************************************************************
di as txt "----- Cleaning and standardizing track variables -----"

capture confirm variable track_1
if !_rc {
    di as txt "Processing track and canton variables..."
    
    * Decode track variables to get string versions
    capture decode track_1, gen(r_canton)
    capture decode track_2, gen(r_school_track_name)
    
    * Check if canton variable exists and update if needed
    capture confirm variable canton
    if !_rc {
        di as txt "Updating canton variable with values from track_1..."
        
        * Count mismatches for reporting
        count if !missing(canton) & (r_canton != canton & canton != "Grigioni")
        local mismatch_count = r(N)
        if `mismatch_count' > 0 {
            di as txt "  Warning: `mismatch_count' observations have canton different from track_1 decoded value."
        }
        
        replace canton = r_canton if !missing(r_canton)
    }
    else {
        di as txt "Canton variable not found, creating from track_1..."
        rename r_canton canton
    }
    drop r_canton
    
    * Check if school type exists and update
    capture confirm variable school_type
    if !_rc {
        di as txt "Updating school_type variable with values from track_2..."
        
        * Count mismatches for reporting
        count if !missing(school_type) & (r_school_track_name != school_type & school_type != "Karışik")
        local mismatch_count = r(N)
        if `mismatch_count' > 0 {
            di as txt "  Warning: `mismatch_count' observations have school_type different from track_2 decoded value."
        }
        
        rename r_school_track_name school_track_name
        replace school_type = school_track_name if !missing(school_track_name)
    }
    else {
        di as txt "school_type variable not found, creating from track_2..."
        rename r_school_track_name school_type
        gen school_track_name = school_type
    }
    
    * Create standardized track variable
    di as txt "Creating standardized track variable..."
    capture confirm variable track
    if _rc == 0 {
        di as txt "  track variable already exists, updating values."
    }
    else {
        di as txt "  Creating new track variable."
        gen track = .
    }
    
    replace track = 1 if school_type == "low"
    replace track = 2 if school_type == "middle"
    replace track = 3 if school_type == "intermediate"
    replace track = 4 if school_type == "high"
    replace track = 5 if school_type == "mixed"
    replace track = 6 if school_type == "other"
    
    * Label the track variable
    capture label define track_labels 1 "Low" 2 "Middle" 3 "Intermediate" 4 "High" 5 "Mixed" 6 "Other", replace
    label values track track_labels
    label var track "School track"
    
    di as txt "  track variable created and labeled."
}
else {
    di as txt "track_1 variable not found, skipping track standardization."
}

********************************************************************************
* 5. RELABELING MATH & LANGUAGE VARIABLES
********************************************************************************
di as txt "----- Cleaning math, language, and related variables -----"

* Rename variables with trailing underscores
foreach var in math_level_ lang_level_ math_grade_ lang_grade_ {
    capture confirm variable `var'
    if !_rc {
        local newname = substr("`var'", 1, length("`var'") - 1)
        di as txt "Renaming `var' to `newname'..."
        rename `var' `newname'
    }
}

* Rename SDQ variables
forval i = 1/6 {
    capture confirm variable sdq__`i'
    if !_rc {
        di as txt "Renaming sdq__`i' to sdq_`i'..."
        rename sdq__`i' sdq_`i'
    }
}

* Rename plan variable
capture confirm variable plan_
if !_rc {
    di as txt "Renaming plan_ to plan..."
    rename plan_ plan
}

* Recode sit variable
di as txt "Recoding sit variable..."
capture confirm variable sit_
if !_rc {
    di as txt "Creating standardized sit variable from sit_..."
    gen sit = .
    replace sit = 1 if sit_ == 1
    replace sit = 2 if sit_ == 2
    replace sit = 4 if sit_ == 3
    drop sit_
    label var sit "Situation (standardized)"
}
else {
    di as txt "sit_ variable not found, skipping sit recoding."
}

********************************************************************************
* 6. CLEANING SWISSBORN & MIGRATION BACKGROUND
********************************************************************************
di as txt "----- Cleaning migration background variables -----"

* Create standardized Swiss-born variables
di as txt "Creating standardized Swiss-born variables..."

* Child's Swiss-born status
gen swissborn_child = .
label var swissborn_child "Child born in Switzerland"

foreach var in swissborn_family_1 swissborn_mother_1 swissborn_father_1 swissborn_child_ {
    capture confirm variable `var'
    if !_rc {
        di as txt "  Using `var' to populate swissborn_child..."
        replace swissborn_child = `var' if !missing(`var')
    }
}

* Mother's Swiss-born status
gen swissborn_mother = .
label var swissborn_mother "Mother born in Switzerland"

foreach var in swissborn_family_2 swissborn_mother_2 {
    capture confirm variable `var'
    if !_rc {
        di as txt "  Using `var' to populate swissborn_mother..."
        replace swissborn_mother = `var' if !missing(`var')
    }
}

* Father's Swiss-born status
gen swissborn_father = .
label var swissborn_father "Father born in Switzerland"

foreach var in swissborn_family_3 swissborn_father_2 {
    capture confirm variable `var'
    if !_rc {
        di as txt "  Using `var' to populate swissborn_father..."
        replace swissborn_father = `var' if !missing(`var')
    }
}

* Drop original variables
foreach var in swissborn_family_* swissborn_mother_* swissborn_father_* swissborn_child_ {
    capture drop `var'
}

* Process birthplace variables
di as txt "Processing birthplace variables..."

* Handle mother's birthplace
capture confirm variable birthplace_mother
if !_rc {
    di as txt "  Processing mother's birthplace..."
    decode birthplace_mother, gen(r_birthplace_mother)
    drop birthplace_mother
    rename r_birthplace_mother birthplace_mother
    label var birthplace_mother "Mother's birthplace"
}

* Handle father's birthplace (might be in different variables)
gen birthplace_father = ""
label var birthplace_father "Father's birthplace"

foreach var in birthplace_father1_ birthplace_father2 {
    capture confirm variable `var'
    if !_rc {
        di as txt "  Processing father's birthplace from `var'..."
        decode `var', gen(r_`var')
        replace birthplace_father = r_`var' if !missing(r_`var')
        drop `var' r_`var'
    }
}

********************************************************************************
* 7. RELABELING PARENTS EDUCATION
********************************************************************************
di as txt "----- Cleaning parent education variables -----"

capture confirm variable educ_parent1
if !_rc {
    di as txt "Processing parent education variables..."
    
    * Decode education variables
    decode educ_parent1, gen(field_educ_mother)
    decode educ_parent2, gen(field_educ_father)
    
    * Handle text versions if they exist
    capture confirm variable educ_parent1_7_TEXT
    if !_rc {
        rename educ_parent1_7_TEXT field_educ_mother_text
    }
    
    capture confirm variable educ_parent2_7_TEXT
    if !_rc {
        rename educ_parent2_7_TEXT field_educ_father_text
    }
    
    * Label new variables
    label var field_educ_mother "Mother's field of education"
    label var field_educ_father "Father's field of education"
    
    * Drop original variables
    drop educ_parent1 educ_parent2
    
    di as txt "  Parent education variables processed."
}
else {
    di as txt "educ_parent1 variable not found, skipping parent education relabeling."
}

********************************************************************************
* 8. RELABELING PREFERENCES (OCCUPATIONAL)
********************************************************************************
di as txt "----- Cleaning occupational preference variables -----"

* Loop over preference variables to rename them for clarity
di as txt "Standardizing preference variables..."

* Process main preference variables
forval i = 1/44 {
    * Child preferences
    capture confirm variable prefchild_m_`i'
    if !_rc {
        rename prefchild_m_`i' app_pref_m_`i'
    }
    
    capture confirm variable prefchild_best_m_`i'
    if !_rc {
        rename prefchild_best_m_`i' app_pref_best_m_`i'
    }
    
    capture confirm variable prefchild_f__`i'
    if !_rc {
        rename prefchild_f__`i' app_pref_f_`i'
    }
    
    capture confirm variable prefchild_best_f__`i'
    if !_rc {
        rename prefchild_best_f__`i' app_pref_best_f_`i'
    }
    
    * Mother preferences
    capture confirm variable prefmother_m__`i'
    if !_rc {
        rename prefmother_m__`i' mother_m_`i'
    }
    
    capture confirm variable prefmother_f__`i'
    if !_rc {
        rename prefmother_f__`i' mother_f_`i'
    }
    
    capture confirm variable prefmother_best_m__`i'
    if !_rc {
        rename prefmother_best_m__`i' mother_best_m_`i'
    }
    
    capture confirm variable prefmother_best_f__`i'
    if !_rc {
        rename prefmother_best_f__`i' mother_best_f_`i'
    }
    
    * Father preferences
    capture confirm variable preffather_m__`i'
    if !_rc {
        rename preffather_m__`i' father_m_`i'
    }
    
    capture confirm variable preffather_f__`i'
    if !_rc {
        rename preffather_f__`i' father_f_`i'
    }
    
    capture confirm variable preffather_best_m_`i'
    if !_rc {
        rename preffather_best_m_`i' father_best_m_`i'
    }
    
    capture confirm variable preffather_best_f__`i'
    if !_rc {
        rename preffather_best_f__`i' father_best_f_`i'
    }
}

* Process text versions for preferences (42-44)
di as txt "Standardizing preference text variables..."
forval i = 42/44 {
    * Child preferences text
    capture confirm variable prefchild_m_`i'_TEXT
    if !_rc {
        rename prefchild_m_`i'_TEXT app_pref_m_`i'_TEXT
    }
    
    capture confirm variable prefchild_best_m_`i'_TEXT
    if !_rc {
        rename prefchild_best_m_`i'_TEXT app_pref_best_m_`i'_TEXT
    }
    
    capture confirm variable prefchild_f__`i'_TEXT
    if !_rc {
        rename prefchild_f__`i'_TEXT app_pref_f_`i'_TEXT
    }
    
    capture confirm variable prefchild_best_f__`i'_TEXT
    if !_rc {
        rename prefchild_best_f__`i'_TEXT app_pref_best_f_`i'_TEXT
    }
    
    * Mother preferences text
    capture confirm variable prefmother_m__`i'_TEXT
    if !_rc {
        rename prefmother_m__`i'_TEXT mother_m_`i'_TEXT
    }
    
    capture confirm variable prefmother_f__`i'_TEXT
    if !_rc {
        rename prefmother_f__`i'_TEXT mother_f_`i'_TEXT
    }
    
    capture confirm variable prefmother_best_m__`i'_TEXT
    if !_rc {
        rename prefmother_best_m__`i'_TEXT mother_best_m_`i'_TEXT
    }
    
    capture confirm variable prefmother_best_f__`i'_TEXT
    if !_rc {
        rename prefmother_best_f__`i'_TEXT mother_best_f_`i'_TEXT
    }
    
    * Father preferences text
    capture confirm variable preffather_m__`i'_TEXT
    if !_rc {
        rename preffather_m__`i'_TEXT father_m_`i'_TEXT
    }
    
    capture confirm variable preffather_f__`i'_TEXT
    if !_rc {
        rename preffather_f__`i'_TEXT father_f_`i'_TEXT
    }
    
    capture confirm variable preffather_best_m_`i'_TEXT
    if !_rc {
        rename preffather_best_m_`i'_TEXT father_best_m_`i'_TEXT
    }
    
    capture confirm variable preffather_best_f__`i'_TEXT
    if !_rc {
        rename preffather_best_f__`i'_TEXT father_best_f_`i'_TEXT
    }
}

* Rename timer-related variables
di as txt "Standardizing timer-related variables..."

* Process ta_occs, reject_ta, and offers2 variables
forval i = 1/45 {
    foreach g in "m" "f" {
        capture confirm variable ta_occs_`g'__`i'
        if !_rc {
            rename ta_occs_`g'__`i' ta_occs_`g'_`i'
        }
        
        capture confirm variable reject_ta_`g'__`i'
        if !_rc {
            rename reject_ta_`g'__`i' reject_ta_`g'_`i'
        }
        
        capture confirm variable offers2_`g'__`i'
        if !_rc {
            rename offers2_`g'__`i' offers2_`g'_`i'
        }
    }
}

* Process apply_occs variables
forval i = 1/44 {
    foreach g in "m" "f" {
        capture confirm variable apply_occs_`g'__`i'
        if !_rc {
            rename apply_occs_`g'__`i' apply_occs_`g'_`i'
        }
    }
}

* Process text versions for timer-related variables
forval i = 43/45 {
    foreach g in "m" "f" {
        capture confirm variable ta_occs_`g'__`i'_TEXT
        if !_rc {
            rename ta_occs_`g'__`i'_TEXT ta_occs_`g'_`i'_TEXT
        }
        
        capture confirm variable reject_ta_`g'__`i'_TEXT
        if !_rc {
            rename reject_ta_`g'__`i'_TEXT reject_ta_`g'_`i'_TEXT
        }
        
        capture confirm variable offers2_`g'__`i'_TEXT
        if !_rc {
            rename offers2_`g'__`i'_TEXT offers2_`g'_`i'_TEXT
        }
    }
}

forval i = 42/44 {
    foreach g in "m" "f" {
        capture confirm variable apply_occs_`g'__`i'_TEXT
        if !_rc {
            rename apply_occs_`g'__`i'_TEXT apply_occs_`g'_`i'_TEXT
        }
    }
}

********************************************************************************
* 9. SURVEY COMPLETION INDICATOR
********************************************************************************
di as txt "----- Creating survey completion indicator -----"

gen compl_end = 1 if t_ses_1_Page_Submit != .
label var compl_end "Completed final questions"

********************************************************************************
* 10. FINAL HOUSEKEEPING & SAVE
********************************************************************************
di as txt "----- Compressing and saving dataset -----"

* Clean up leftover First_Click, Last_Click, etc. variables
drop *_First_Click* *_Last_Click* *_Page_Submit* *_Click_Count* 

* Clean up Duration__in_seconds if it exists
capture drop Duration__in_seconds_

* Compress and save
compress
save "${processed_data}/PS_Students/3_ps_students.dta", replace

* Final report
di as txt "Cleaned and relabeled dataset saved to: ${processed_data}/PS_Students/3_ps_students.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Clean Relabeling"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off