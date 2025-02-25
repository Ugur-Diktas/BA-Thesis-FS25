********************************************************************************
* 3_ps_students_clean_relabeling.do
*
* Purpose:
*   - Load the cleaned PS Students dataset (duplicates removed and test answers dropped).
*   - Convert string variables (e.g., contract, female) to numeric and recode as needed.
*   - Create new variables (e.g., el, duration_mins, and duration_* variables).
*   - Standardize track/canton via merge with new_drill_down_school_tracks.dta.
*   - Rename and label variables for home situation, tracks, math/language, parent education,
*     and occupational preferences.
*   - Drop unneeded variables.
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

* Set tracing based on debug flag:
if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/students_clean_relabeling.log", replace text

timer clear
timer on 1

*---------------------------------------------------------------
* 1. LOAD THE CLEANED DATA
*---------------------------------------------------------------
di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"
quietly use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    error 602
}

*---------------------------------------------------------------
* 2. CLEAN & CREATE DURATION VARIABLES
*---------------------------------------------------------------

*--- Convert string variables to numeric if needed ---
capture confirm variable contract
if !_rc {
    destring contract, replace
}
capture confirm variable female
if !_rc {
    destring female, replace
}

*--- Create indicator for EL ---
gen el = (contract == 1)
label var el "EL"

*--- Create overall duration (minutes) if available ---
capture confirm variable Duration__in_seconds_
if !_rc {
    gen duration_mins = Duration__in_seconds_ / 60
    label var duration_mins "Total duration (mins)"
}

*--- Create duration variables from click timestamps ---
* Identify variables matching t_*_First_Click:
ds t_*_First_Click
local firstClickVars `r(varlist)'
if "`firstClickVars'" != "" {
    foreach var of local firstClickVars {
        quietly count if missing(`var')
        if r(N) == _N {
            di as txt "`var' is missing"
        }
        else {
            di as txt "`var' is not missing"
            * Remove the prefix "t_" and the suffix "_First_Click" to form a base name:
            local base : subinstr local var "t_" "", all
            local base : subinstr local base "_First_Click" "", all
            * Check for the corresponding Page_Submit variable:
            capture confirm variable `base'_Page_Submit
            if !_rc {
                gen duration_`base' = (`base'_Page_Submit) / 60
            }
            else {
                di as error "Warning: Matching variable `base'_Page_Submit not found for `var'"
            }
        }
    }
}

*--- Label the newly created duration variables ---
* We define a local macro of label pairs (format: varname:Label) separated by semicolons.
* Note: this line CANNOT be split across multiple lines. Else it will not work.
local durLabels "duration_consent1:Consent page 1;duration_sure:Sure;duration_consent2:Consent page 2;duration_background_1_:Background page 1;duration_background_2_:Background page 2;duration_child_prefs_1:Own prefs page 1;duration_child_prefs_2:Own prefs page 2;duration_mother_prefs_1:Mothers prefs page 1;duration_mother_prefs_2:Mother's prefs page 2;duration_father_prefs_1:Father's prefs page 1;duration_father_prefs_2:Father's prefs page 2;duration_motivation_child:Own motivation factors;duration_motivation_mother:Mother's motivation factors;duration_motivation_father:Father's motivation factors;duration_beliefs_1_:Beliefs page 1;duration_beliefs_2_:Beliefs page 2;duration_debriefing_1:Debriefing page 1;duration_debriefing_2:Debriefing page 2;duration_contract_occ_:Contract occupation;duration_ta_occs_:TA occupations;duration_reject_occs_:Rejection occupations;duration_apply_:Application occupations;duration_offers_:Offers occupations;duration_perc_contract_:Advantages/disadvantages of contract occ;duration_perc_disadv_hc_:Advantages/disadvantages of HC;duration_suggest_hc_:Suggestion HC (no contract or TA);duration_no_consider_hc_:Why considered or not HC"

* Tokenize the durLabels string using semicolon as delimiter.
tokenize "`durLabels'", parse(";")
while "`1'" != "" {
    local pair = "`1'"
    local delimpos = strpos("`pair'", ":")
    if `delimpos' > 0 {
        * Extract the variable name (from beginning up to the colon)
        local varname = substr("`pair'", 1, `delimpos' - 1)
        * Extract the label (everything after the colon)
        local lbl = substr("`pair'", `delimpos' + 1, .)
        capture confirm variable `varname'
        if !_rc {
            label variable `varname' "`lbl'"
        }
    }
    macro shift
}

*---------------------------------------------------------------
* 3. CLEAN HOME SITUATION
*---------------------------------------------------------------
capture confirm variable home_sit
if !_rc {
    rename home_sit home_sit_stu
    label define home_sit_stu_lab ///
        1 "Both parents" ///
        2 "Sometimes mother, sometimes father" ///
        3 "Only mother, contact with father" ///
        4 "Only father, contact with mother" ///
        5 "Only mother, no contact with father" ///
        6 "Only father, no contact with mother" ///
        7 "Other", replace
    label values home_sit_stu home_sit_stu_lab
}

*---------------------------------------------------------------
* 4. RELABELING TRACKS & SCHOOL TRACK OVERVIEW
*---------------------------------------------------------------
capture confirm variable track_1
if !_rc {
    decode track_1, gen(r_canton)
    decode track_2, gen(r_school_track_name)
    
    * Ensure decoded canton matches existing "canton" (or is "Grigioni")
    assert r_canton == canton | canton == "Grigioni"
    gen track_error = 1 if r_canton != canton
    replace canton = r_canton
    drop r_canton

    * Similarly, check that decoded school track name matches school_type, except for "Karışık"
    assert r_school_track_name == school_type | school_type == "Karışık"
    replace track_error = 1 if r_school_track_name != school_type
    rename r_school_track_name school_track_name
    replace school_type = school_track_name

    assert missing(school_track) if track_error == 1

    * Encode final track variable based on standardized values:
    gen track = .
    replace track = 1 if school_track == "low"
    replace track = 2 if school_track == "middle"
    replace track = 3 if school_track == "intermediate"
    replace track = 4 if school_track == "high"
    replace track = 5 if school_track == "mixed"
    replace track = 6 if school_track == "other"
    
    label define track_labels 1 "Low" 2 "Middle" 3 "Intermediate" 4 "High" 5 "Mixed" 6 "Other", replace
    label values track track_labels
    label var track "School track"
}

*---------------------------------------------------------------
* 5. RELABELING MATH & LANGUAGE VARIABLES
*---------------------------------------------------------------
* Rename trailing-underscore variables if they exist:
capture confirm variable math_level_
if !_rc {
    rename math_level_ math_level
}
capture confirm variable lang_level_
if !_rc {
    rename lang_level_ lang_level
}
capture confirm variable math_grade_
if !_rc {
    rename math_grade_ math_grade
}
capture confirm variable lang_grade_
if !_rc {
    rename lang_grade_ lang_grade
}

* Rename sdq variables for i = 1 to 6:
forval i = 1/6 {
    capture confirm variable sdq__`i'
    if !_rc {
        rename sdq__`i' sdq_`i'
    }
}

* Rename plan variable and recode sit variable:
capture confirm variable plan_
if !_rc {
    rename plan_ plan
}
gen sit = .
replace sit = 1 if sit_ == 1
replace sit = 2 if sit_ == 2
replace sit = 4 if sit_ == 3
drop sit_

*---------------------------------------------------------------
* 6. CLEANING SWISSBORN & MIGRATION BACKGROUND
*---------------------------------------------------------------
gen swissborn_child = .
replace swissborn_child = swissborn_family_1 if !missing(swissborn_family_1)
replace swissborn_child = swissborn_mother_1 if !missing(swissborn_mother_1)
replace swissborn_child = swissborn_father_1 if !missing(swissborn_father_1)
replace swissborn_child = swissborn_child_ if !missing(swissborn_child_)

gen swissborn_mother = .
replace swissborn_mother = swissborn_family_2 if !missing(swissborn_family_2)
replace swissborn_mother = swissborn_mother_2 if !missing(swissborn_mother_2)

gen swissborn_father = .
replace swissborn_father = swissborn_family_3 if !missing(swissborn_family_3)
replace swissborn_father = swissborn_father_2 if !missing(swissborn_father_2)

drop swissborn_family* swissborn_mother_* swissborn_father_* swissborn_child_

* Decode birthplace variables and rename appropriately:
decode birthplace_mother, gen(r_birthplace_mother)
decode birthplace_father1_, gen(r_birthplace_father1)
decode birthplace_father2, gen(r_birthplace_father2)
drop birthplace_mother birthplace_father1_ birthplace_father2
rename r_birthplace_mother birthplace_mother

gen birthplace_father = ""
replace birthplace_father = r_birthplace_father1 if !missing(r_birthplace_father1)
replace birthplace_father = r_birthplace_father2 if !missing(r_birthplace_father2)
drop r_birthplace_father1 r_birthplace_father2

*---------------------------------------------------------------
* 7. RELABELING PARENTS EDUCATION
*---------------------------------------------------------------
decode educ_parent1, gen(field_educ_mother)
decode educ_parent2, gen(field_educ_father)
rename educ_parent1_7_TEXT field_educ_mother_text
rename educ_parent2_7_TEXT field_educ_father_text
drop educ_parent1* educ_parent2*

*---------------------------------------------------------------
* 8. RELABELING PREFERENCES (OCCUPATIONAL)
*---------------------------------------------------------------
* Loop over a series of variables to rename them for clarity.
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
    capture rename preffather_best_m_`i' father_best_m_`i'
    capture rename preffather_best_f__`i' father_best_f_`i'
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
    capture rename preffather_best_f__`i'_TEXT   father_best_f_`i'_TEXT
}

* Rename timer-related variables (if applicable)
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

*---------------------------------------------------------------
* 9. SURVEY COMPLETION INDICATOR
*---------------------------------------------------------------
gen compl_end = 1 if t_ses_1_Page_Submit != .
label var compl_end "Completed final questions"

*---------------------------------------------------------------
* 10. FINAL HOUSEKEEPING & SAVE
*---------------------------------------------------------------
di as txt "----- Compressing and saving dataset -----"
compress
save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list
log close
