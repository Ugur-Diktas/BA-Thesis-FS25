********************************************************************************
* 3_ps_students_clean_relabeling.do
*
* Purpose:
*   - Load the cleaned PS Students dataset (duplicates removed).
*   - Optionally drop additional test answers or early responses based on date.
*   - Convert certain string variables (e.g., contract, female) to numeric,
*     recoding them if needed.
*   - Create new variables (e.g., `el`, `duration_mins`, various `duration_...`).
*   - Merge with `new_drill_down_school_tracks.dta` to standardise track/canton.
*   - Rename or label variables related to home situation, tracks, math/language.
*   - Label or rename parent education, preference, and belief variables.
*   - Finally, save an updated dataset for further steps.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 19.02.2025
* Version: Stata 18
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING
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
log using "${dodir_log}/ps_students_clean_relabeling.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************

di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"
quietly use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"

if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    error 602
}

********************************************************************************
* 2. REMOVE ADDITIONAL TEST ANSWERS (IF ANY)
********************************************************************************

drop if test != ""
drop if Status == 1

format StartDate %tc
drop if StartDate < clock("2024-11-11 10:00:00", "YMDhms") // TODO: drop in one place

* Re-merge sensitive data to drop by email again (TODO: remove double checking)
merge 1:1 ResponseId using "${sensitive_data}/ps_stu_sensitive_only", ///
    keep(master match) keepusing(ResponseId stu_first_name stu_last_name email) nogen

drop if inlist(email, ///
    "daphne.rutnam@econ.uzh.ch", "hannah.massenbauer@econ.uzh.ch", ///
    "anne.brenoe@econ.uzh.ch", "gianluca.spina@uzh.ch", ///
    "Anne.brenoe@econ.uzh.ch", "daphne.rutnam@gmail.com")

drop if inlist(feedback, "Test", "test")

* Example fix for missing schoolid
replace schoolid = "6002" if (name_class == "B2B" | name_class == "B2b" | ///
    name_class == "R2a" | name_class == "B1b" | name_class == "B23b" | ///
    name_class == "B2a") & sbID == "1" & ///
    StartDate < clock("2024-21-11 20:00:00", "YMDhms") & missing(schoolid)

********************************************************************************
* 3. CLEAN & CREATE DURATION VARIABLES
********************************************************************************

destring contract, replace
destring female, replace

gen el = (contract == 1)
label var el "EL"

gen duration_mins = Duration__in_seconds_/60
label var duration_mins "Total duration (mins)"

ds t_*_First_Click
ds `r(varlist)'

foreach var of varlist `r(varlist)' {
    count if missing(`var')
    if r(N) == _N {
        display "`var' is missing"
    } 
	else {
        display "`var' is not missing"
        local varname_stripped : subinstr local var "_First_Click" ""
        local varname : subinstr local varname_stripped "t_" ""
        gen duration_`varname' = .
        replace duration_`varname' = (`varname_stripped'_Page_Submit)/60
    }
}

*-- Label the newly created duration_* variables (if they exist):
ds duration_*

foreach var of varlist `r(varlist)' {
    if "`var'" == "duration_consent1" {
        label variable `var' "Consent page 1"
    }
    else if "`var'" == "duration_sure" {
        label variable `var' "Sure"
    }
    else if "`var'" == "duration_consent2" {
        label variable `var' "Consent page 2"
    }
    else if "`var'" == "duration_background_1_" {
        label variable `var' "Background page 1"
    }
    else if "`var'" == "duration_background_2_" {
        label variable `var' "Background page 2"
    }
    else if "`var'" == "duration_child_prefs_1" {
        label variable `var' "Own prefs page 1"
    }
    else if "`var'" == "duration_child_prefs_2" {
        label variable `var' "Own prefs page 2"
    }
    else if "`var'" == "duration_mother_prefs_1" {
        label variable `var' "Mothers prefs page 1"
    }
    else if "`var'" == "duration_mother_prefs_2" {
        label variable `var' "Mother's prefs page 2"
    }
    else if "`var'" == "duration_father_prefs_1" {
        label variable `var' "Father's prefs page 1"
    }
    else if "`var'" == "duration_father_prefs_2" {
        label variable `var' "Father's prefs page 2"
    }
    else if "`var'" == "duration_motivation_child" {
        label variable `var' "Own motivation factors"
    }
    else if "`var'" == "duration_motivation_mother" {
        label variable `var' "Mother's motivation factors"
    }
    else if "`var'" == "duration_motivation_father" {
        label variable `var' "Father's motivation factors"
    }
    else if "`var'" == "duration_beliefs_1_" {
        label variable `var' "Beliefs page 1"
    }
    else if "`var'" == "duration_beliefs_2_" {
        label variable `var' "Beliefs page 2"
    }
    else if "`var'" == "duration_debriefing_1" {
        label variable `var' "Debriefing page 1"
    }
    else if "`var'" == "duration_debriefing_2" {
        label variable `var' "Debriefing page 2"
    }
    else if "`var'" == "duration_contract_occ_" {
        label variable `var' "Contract occupation"
    }
    else if "`var'" == "duration_ta_occs_" {
        label variable `var' "TA occupations"
    }
    else if "`var'" == "duration_reject_occs_" {
        label variable `var' "Rejection occupations"
    }
    else if "`var'" == "duration_apply_" {
        label variable `var' "Application occupations"
    }
    else if "`var'" == "duration_offers_" {
        label variable `var' "Offers occupations"
    }
    else if "`var'" == "duration_perc_contract_" {
        label variable `var' "Advantages/disadvantages of contract occ"
    }
    else if "`var'" == "duration_perc_disadv_hc_" {
        label variable `var' "Advantages/disadvantages of HC"
    }
    else if "`var'" == "duration_suggest_hc_" {
        label variable `var' "Suggestion HC (no contract or TA)"
    }
    else if "`var'" == "duration_no_consider_hc_" {
        label variable `var' "Why considered or not HC"
    }
    else if "`var'" == "duration_suggest_hc_2_" {
        label variable `var' "Suggestion HC (no contract, but TA)"
    }
    else if "`var'" == "duration_no_appr_hc_" {
        label variable `var' "Why no TA in HC"
    }
    else if "`var'" == "duration_concern_contract_" {
        label variable `var' "Others' concerns p1 (contract)"
    }
    else if "`var'" == "duration_reason_concern_" {
        label variable `var' "Others' concerns p2 (contract)"
    }
    else if "`var'" == "duration_social_skills_" {
        label variable `var' "Social skills"
    }
    else if "`var'" == "duration_gender_id" {
        label variable `var' "Gender identity"
    }
    else if "`var'" == "duration_belief_society_" {
        label variable `var' "Societal perception"
    }
    else if "`var'" == "duration_ses_1" {
        label variable `var' "SES page 1"
    }
    else if "`var'" == "duration_ses_2_" {
        label variable `var' "SES page 2"
    }
    else if "`var'" == "duration_end" {
        label variable `var' "Final page"
    }
}

********************************************************************************
* 4. CLEAN HOME SITUATION
********************************************************************************

rename home_sit home_sit_stu
label define home_sit_stu_lab ///
    1 "Both parents" ///
    2 "Sometimes mother, sometimes father" ///
    3 "Only mother, contact with father" ///
    4 "Only father, contact with mother" ///
    5 "Only mother, no contact with father" ///
    6 "Only father, no contact with mother" ///
    7 "Other"
label values home_sit_stu home_sit_stu_lab

********************************************************************************
* 5. RELABELING TRACKS & SCHOOL TRACK OVERVIEW
********************************************************************************

* 5a) Decode track_1 and track_2
decode track_1, gen(r_canton)
decode track_2, gen(r_school_track_name)

* 5b) Confirm that the “decoded” track_1 matches existing canton var
assert r_canton == canton | canton == "Grigioni"
gen track_error = 1 if r_canton != canton
replace canton = r_canton
drop r_canton

* 5c) Confirm that the “decoded” track_2 matches school_type except for "Karışık"
assert r_school_track_name == school_type | school_type == "Karışık"
replace track_error = 1 if r_school_track_name != school_type
rename r_school_track_name school_track_name
replace school_type = school_track_name

assert missing(school_track) if track_error == 1

// TODO: is this needed? Analyse it.
/* * 5d) Merge with skill_intensity_data_with_apprentice_characteristics.dta` in your to_merge/ folder
gen new_school_name = school_track_name
merge m:1 canton new_school_name using "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics", ///
    keep(master match) keepusing(canton new_school_name new_track_standardized) nogen */

// Needed?
/* assert _merge == 3 | missing(school_track_name)
drop _merge */

/* assert school_track == new_track_standardized | track_error == 1
replace school_track = new_track_standardized if track_error == 1
drop new_track_standardized new_school_name */

* 5e) Encode final track variable
gen track = .
replace track = 1 if school_track == "low"
replace track = 2 if school_track == "middle"
replace track = 3 if school_track == "intermediate"
replace track = 4 if school_track == "high"
replace track = 5 if school_track == "mixed"
replace track = 6 if school_track == "other"

label define track_labels 1 "Low" 2 "Middle" 3 "Intermediate" 4 "High" 5 "Mixed" 6 "Other"
label values track track_labels
label var track "School track"

********************************************************************************
* 6. RELABELING MATH & LANGUAGE
********************************************************************************

rename math_level_ math_level
rename lang_level_ lang_level
rename math_grade_ math_grade
rename lang_grade_ lang_grade

forval i = 1/6 {
    rename sdq__`i' sdq_`i'
}

rename plan_ plan
gen sit = .
replace sit = 1 if sit_ == 1
replace sit = 2 if sit_ == 2
replace sit = 4 if sit_ == 3
drop sit_

********************************************************************************
* 7. CLEANING SWISSBORN & MIGRATION BACKGROUND
********************************************************************************

gen swissborn_child = .
replace swissborn_child = swissborn_family_1 if !missing(swissborn_family_1)
replace swissborn_child = swissborn_mother_1 if !missing(swissborn_mother_1)
replace swissborn_child = swissborn_father_1 if !missing(swissborn_father_1)
replace swissborn_child = swissborn_child_   if !missing(swissborn_child_)

gen swissborn_mother = .
replace swissborn_mother = swissborn_family_2 if !missing(swissborn_family_2)
replace swissborn_mother = swissborn_mother_2 if !missing(swissborn_mother_2)

gen swissborn_father = .
replace swissborn_father = swissborn_family_3 if !missing(swissborn_family_3)
replace swissborn_father = swissborn_father_2 if !missing(swissborn_father_2)

drop swissborn_family* swissborn_mother_* swissborn_father_* swissborn_child_

decode birthplace_mother,    gen(r_birthplace_mother)
decode birthplace_father1_, gen(r_birthplace_father1)
decode birthplace_father2,  gen(r_birthplace_father2)

drop birthplace_mother birthplace_father1_ birthplace_father2
rename r_birthplace_mother birthplace_mother

gen birthplace_father = ""
replace birthplace_father = r_birthplace_father1 if !missing(r_birthplace_father1)
replace birthplace_father = r_birthplace_father2 if !missing(r_birthplace_father2)
drop r_birthplace_father1 r_birthplace_father2

********************************************************************************
* 8. RELABELING PARENTS EDUCATION
********************************************************************************

decode educ_parent1, gen(field_educ_mother)
decode educ_parent2, gen(field_educ_father)
rename educ_parent1_7_TEXT field_educ_mother_text
rename educ_parent2_7_TEXT field_educ_father_text
drop educ_parent1* educ_parent2*

********************************************************************************
* 9. CLEANING MATH & LANGUAGE
********************************************************************************
/*
   Additional standardization steps or merges with
   new_drill_down_school_tracks if needed ...
*/

********************************************************************************
* 10. RELABELING PREFERENCES (OCCUPATIONAL)
********************************************************************************

forval i = 1/44 {
    rename prefchild_m_`i' app_pref_m_`i'
    rename prefchild_best_m_`i' app_pref_best_m_`i'
    rename prefchild_f__`i' app_pref_f_`i'
    rename prefchild_best_f__`i' app_pref_best_f_`i'
    
    rename prefmother_m__`i' mother_m_`i'
    rename prefmother_f__`i' mother_f_`i'
    rename prefmother_best_m__`i' mother_best_m_`i'
    rename prefmother_best_f__`i' mother_best_f_`i'
    
    rename preffather_m__`i' father_m_`i'
    rename preffather_f__`i' father_f_`i'
    capture rename preffather_best_m_`i' father_best_m_`i' // TODO: Check this out and fix
    capture rename preffather_best_f_`i' father_best_f_`i'
}

forval i = 42/44 {
    rename prefchild_m_`i'_TEXT       app_pref_m_`i'_TEXT
    rename prefchild_best_m_`i'_TEXT app_pref_best_m_`i'_TEXT
    rename prefchild_f__`i'          app_pref_f_`i'_TEXT
    rename prefchild_best_f__`i'     app_pref_best_f_`i'_TEXT
    
    rename prefmother_m__`i'_TEXT       mother_m_`i'_TEXT
    rename prefmother_f__`i'_TEXT       mother_f_`i'_TEXT
    rename prefmother_best_m__`i'_TEXT  mother_best_m_`i'_TEXT
    rename prefmother_best_f__`i'_TEXT  mother_best_f_`i'_TEXT
    
    rename preffather_m__`i'_TEXT       father_m_`i'_TEXT
    rename preffather_f__`i'_TEXT       father_f_`i'_TEXT
    capture rename preffather_best_m_`i'_TEXT   father_best_m_`i'_TEXT
    capture rename preffather_best_f_`i'_TEXT   father_best_f_`i'_TEXT
}

forval i = 1/45 {
    foreach g in "m" "f" {
        rename ta_occs_`g'__`i' ta_occs_`g'_`i'
        rename reject_ta_`g'__`i' reject_ta_`g'_`i'
        rename offers2_`g'__`i' offers2_`g'_`i'
    }
}

forval i = 1/44 {
    foreach g in "m" "f" {
        rename apply_occs_`g'__`i' apply_occs_`g'_`i'
    }
}

forval i = 43/45 {
    foreach g in "m" "f" {
        rename ta_occs_`g'__`i'_TEXT     ta_occs_`g'_`i'_TEXT
        rename reject_ta_`g'__`i'_TEXT   reject_ta_`g'_`i'_TEXT
        rename offers2_`g'__`i'_TEXT     offers2_`g'_`i'_TEXT
    }
}

forval i = 42/44 {
    foreach g in "m" "f" {
        rename apply_occs_`g'__`i'_TEXT apply_occs_`g'_`i'_TEXT
    }
}

********************************************************************************
* 11. SURVEY COMPLETION INDICATOR
********************************************************************************

gen compl_end = 1 if t_ses_1_Page_Submit != .
label variable compl_end "Completed final questions"

********************************************************************************
* 12. FINAL HOUSEKEEPING & SAVE
********************************************************************************

di as txt "----- Compressing and saving dataset -----"
compress

save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list

log close
