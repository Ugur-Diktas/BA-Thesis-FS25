********************************************************************************
* 3_ps_parents_clean_relabeling.do
* ------------------------------------------------------------------------------
* Data needed: ps_par_cleaned.dta
* Data output: ps_par_cleaned.dta
* Purpose:
*   - Load cleaned PS Parents data (duplicates removed).
*   - Convert string variables to numeric (if needed).
*   - Create duration variables from Qualtrics timing data.
*   - Clean/rename background variables (e.g. home situation, track if available, 
*     parent education).
*   - Save updated dataset.
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
* 0. HOUSEKEEPING
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
log using "${dodir_log}/3_ps_parents_clean_relabeling.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD DATA 
********************************************************************************
di as txt "----- Loading dataset: ps_par_cleaned.dta -----"
use "${processed_data}/PS_Parents/2_ps_parents.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_par_cleaned.dta."
    error 602
}

********************************************************************************
*  2. CONVERT STRING VARIABLES & CREATE DURATION VARIABLES
*.    a.Deals with variable contract and correctly indicates if contract is present and not
*       has been edited in such a way that if a variable allready exists it will replace/updated
*     b. Deals with time variables and creates general timing variables per page
********************************************************************************
* Convert string variables to numeric if needed:
capture confirm variable contract
if !_rc {
    destring contract, replace
}
capture confirm variable female
if !_rc {
    destring female, replace
}
*Create indicator for EL (e.g. if contract == 1)
capture confirm variable el  // Check if "el" exists
if _rc == 0 {               // If no error (_rc == 0), "el" exists
    replace el = (contract == 1)  // Update "el"
} 
else {                      // If error (_rc > 0), "el" does not exist
    gen el = (contract == 1) // Create "el"
}
*gen el = (contract == 1)
label var el "EL (1 if contract==1, else 0)"

* Create overall duration (minutes) if available:
capture confirm variable duration_mins  // Check if  exists
if _rc == 0 {  // If no error (_rc == 0),  exists
    replace duration_mins = Duration__in_seconds_ / 60
} 
else {  // If error (_rc > 0), "duration_mins" does not exist
    gen duration_mins = Duration__in_seconds_ / 60
    label var duration_mins "Total duration (minutes)"
}

*Make duration variables
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
		local varname: subinstr local varname_stripped "t_" ""
		gen duration_`varname' = .
		replace duration_`varname' = (`varname_stripped'_Page_Submit)/60
    }
}

* Label the variables if they exist
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
	else if "`var'" == "duration_background_3_" {
        label variable `var' "Background page 3"
    }
	else if "`var'" == "duration_parent_prefs_1_" {
        label variable `var' "Own prefs page 1"
    }
	else if "`var'" == "duration_parent_prefs_2_" {
        label variable `var' "Own prefs page 2"
    }
	else if "`var'" == "duration_child_prefs_1_" {
        label variable `var' "Child's prefs page 1"
    }
	else if "`var'" == "duration_child_prefs_2_" {
        label variable `var' "Child's prefs page 2"
    }
	else if "`var'" == "duration_other_prefs_1_" {
        label variable `var' "Other parent's prefs page 1"
    }
	else if "`var'" == "duration_other_prefs_2_" {
        label variable `var' "Other parent's prefs page 2"
    }
	else if "`var'" == "duration_motivation_1_" {
        label variable `var' "Motivation page 1"
    }
	else if "`var'" == "duration_motivation_2" {
        label variable `var' "Motivation factors page 2"
    }
	else if "`var'" == "duration_beliefs_1" {
        label variable `var' "Beliefs page 1"
    }
	else if "`var'" == "duration_beliefs_2" {
        label variable `var' "Beliefs page 2"
    }
    else if "`var'" == "duration_beliefs_3" {
        label variable `var' "Beliefs page 3"
    }
    else if "`var'" == "duration_debriefing_1" {
        label variable `var' "Debriefing page 1"
    }
    else if "`var'" == "duration_debriefing_2" {
        label variable `var' "Debriefing page 2"
    }
	else if "`var'" == "duration_gender_track_" {
        label variable `var' "Track"
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
	else if "`var'" == "duration_contract_occ" {
        label variable `var' "Contract occupation"
    }
	else if "`var'" == "duration_belief_el_1" {
        label variable `var' "Beliefs page 1 (EL)"
    }
	else if "`var'" == "duration_belief_el_2" {
        label variable `var' "Beliefs page 2 (EL)"
    }
	else if "`var'" == "duration_social_skills" {
        label variable `var' "Social skills"
    }
	else if "`var'" == "duration_gender_id_el" {
        label variable `var' "Gender identity (EL)"
    }
	else if "`var'" == "duration_canton_el" {
        label variable `var' "Canton (EL)"
    }
	else if "`var'" == "duration_swissborn_el" {
        label variable `var' "Birthplace (CH/not) (EL)"
    }
	else if "`var'" == "duration_birthplace" {
        label variable `var' "Birthplace (country)"
    }
	else if "`var'" == "duration_end_el" {
        label variable `var' "Final page (EL)"
    }
}

********************************************************************************
* 3.RELABEL HONE SITUATION
********************************************************************************
capture confirm variable home_sit_par  // Check if "home_sit_par" exists
if _rc > 0 {  // If "home_sit_par" does not exist, proceed with renaming
    capture confirm variable home_sit
    if _rc == 0 {
        rename home_sit home_sit_par
    }
}

* Define labels only if they don't already exist
capture label define home_sit_par_lbl ///
    1 "Both parents" ///
    2 "Sometimes mother/father" ///
    3 "Only mother, contact father" ///
    4 "Only father, contact mother" ///
    5 "Only mother, no father" ///
    6 "Only father, no mother" ///
    7 "Other", replace

* Apply label only if the variable exists
capture confirm variable home_sit_par
if _rc == 0 {
    label values home_sit_par home_sit_par_lbl
}

********************************************************************************
* 4. RELABELING TRACKS & SCHOOL TRACK OVERVIEW
********************************************************************************
/*list canton_el_1 if !missing(canton_el_1), sepby(canton_el_1)
decode track_1, gen(main_canton) 
decode track_2, gen(main_school_track_name)
decode canton_el_1, gen(el_canton)
decode canton_el_2, gen(el_school_track_name)
gen canton = main_canton if !missing(main_canton)
replace canton = el_canton if !missing(el_canton)
gen school_track_name = main_school_track_name if !missing(main_school_track_name)
replace school_track_name = el_school_track_name if !missing(el_school_track_name)
drop main_canton main_school_track_name el_canton el_school_track_name

*Clean the school track
gen new_school_name = school_track_name
merge m:1 canton new_school_name using "${data_to_merge}/new_drill_down_school_tracks", keep(master match) keepusing(canton new_school_name new_track_standardized)
assert _merge == 3 | (missing(canton) & missing(new_school_name))
replace school_track = new_track_standardized
drop new_track_standardized new_school_name

*Encode track
gen track = .
replace track = 1 if school_track == "low"
replace track = 2 if school_track == "middle"
replace track = 3 if school_track == "intermediate"
replace track = 4 if school_track == "high"
replace track = 5 if school_track == "mixed"
replace track = 6 if school_track == "other"

*Label track
label define track_labels 1 "Low" 2 "Middle" 3 "Intermediate" 4 "High" 5 "Mixed" 6 "Other"
label values track track_labels
label var track "School track"
*/

********************************************************************************
* 5.RELABEL SITUATION AND SOCIAL SKILLS
********************************************************************************
*Clean sdq vars
forval i = 1/6 {
	gen sdq_`i' = .
	foreach g in "m" "f" {
		replace sdq_`i' = social_skills_`g'_`i' if !missing(social_skills_`g'_`i')
	}
}
drop social_skills*

*Clean plan and sit variable
rename plan_ plan
gen sit = .
replace sit = 1 if Child_year_class == 1 
replace sit = 2 if Child_year_class == 2
replace sit = 1 if Child_year_class == 3
drop Child_year_class
********************************************************************************
* 6.RELABEL MIGRATION BACKGROUND
********************************************************************************
*Clean swissborn and birthplace vars
gen swissborn_child = .
replace swissborn_child = swissborn_1_2 if !missing(swissborn_1_2)
replace swissborn_child = swissborn_2_2 if !missing(swissborn_2_2)
replace swissborn_child = swissborn_el_2 if !missing(swissborn_el_2)
replace swissborn_child = swissborn2_el_2 if !missing(swissborn2_el_2)

gen swissborn_mother = .
replace swissborn_mother = swissborn_1_1 if !missing(swissborn_1_1) & Parent_type_ == 1
replace swissborn_mother = swissborn_2_1 if !missing(swissborn_2_1) & Parent_type_ == 1
replace swissborn_mother = swissborn_1_3 if !missing(swissborn_1_3) & Parent_type_ == 2
replace swissborn_mother = swissborn_el_1 if !missing(swissborn_el_1) & Parent_type_ == 1
replace swissborn_mother = swissborn2_el_1 if !missing(swissborn2_el_1) & Parent_type_ == 1
replace swissborn_mother = swissborn_el_3 if !missing(swissborn_el_3) & Parent_type_ == 2

gen swissborn_father = .
replace swissborn_father = swissborn_1_1 if !missing(swissborn_1_1) & Parent_type_ == 2
replace swissborn_father = swissborn_2_1 if !missing(swissborn_2_1) & Parent_type_ == 2
replace swissborn_father = swissborn_1_3 if !missing(swissborn_1_3) & Parent_type_ == 1
replace swissborn_father = swissborn_el_1 if !missing(swissborn_el_1) & Parent_type_ == 2
replace swissborn_father = swissborn2_el_1 if !missing(swissborn2_el_1) & Parent_type_ == 2
replace swissborn_father = swissborn_el_3 if !missing(swissborn_el_3) & Parent_type_ == 1

drop swissborn_1* swissborn_2* swissborn_el* swissborn2_el*

decode birthplace_parent1_, gen(r_this_parent_main)
decode birthplace_parent2_, gen(r_other_parent_main_1)
decode birthplace_parent3_, gen(r_other_parent_main_2)
decode birthplace_el, gen(r_this_parent_el)
decode birthplace2_el, gen(r_other_parent_el_1)
decode birthplace3_el, gen(r_other_parent_el_2)
drop birthplace*

gen birthplace_mother = ""
replace birthplace_mother = r_this_parent_main if !missing(r_this_parent_main) & Parent_type_ == 1
replace birthplace_mother = r_other_parent_main_1 if !missing(r_other_parent_main_1) & Parent_type_ == 2
replace birthplace_mother = r_other_parent_main_2 if !missing(r_other_parent_main_2) & Parent_type_ == 2
replace birthplace_mother = r_this_parent_el if !missing(r_this_parent_el) & Parent_type_ == 1
replace birthplace_mother = r_other_parent_el_1 if !missing(r_other_parent_el_1) & Parent_type_ == 2
replace birthplace_mother = r_other_parent_el_2 if !missing(r_other_parent_el_2) & Parent_type_ == 2

gen birthplace_father = ""
replace birthplace_mother = r_this_parent_main if !missing(r_this_parent_main) & Parent_type_ == 2
replace birthplace_mother = r_other_parent_main_1 if !missing(r_other_parent_main_1) & Parent_type_ == 1
replace birthplace_mother = r_other_parent_main_2 if !missing(r_other_parent_main_2) & Parent_type_ == 1
replace birthplace_mother = r_this_parent_el if !missing(r_this_parent_el) & Parent_type_ == 2
replace birthplace_mother = r_other_parent_el_1 if !missing(r_other_parent_el_1) & Parent_type_ == 1
replace birthplace_mother = r_other_parent_el_2 if !missing(r_other_parent_el_2) & Parent_type_ == 1
********************************************************************************
* 7. RELABEL PARENTS EDUCATION
********************************************************************************
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
********************************************************************************
* 8. RELABEL PARENTS PREFEERENCES
*.   *a.renames variables with __ instead of _ for easier coding
********************************************************************************
forval i =1/44 {
	rename prefother_m__`i' prefother_m_`i'
}

forval i =42/44 {
	rename prefother_m__`i'_TEXT prefother_m_`i'_TEXT
}

forval i = 1/44 {
	foreach g in "m" "f" {
		gen mother_`g'_`i' = .
		replace mother_`g'_`i' = prefown_`g'_`i' if Parent_type_ == 1
		replace mother_`g'_`i' = prefother_`g'_`i' if Parent_type_ == 2
		gen father_`g'_`i' = .
		replace father_`g'_`i' = prefown_`g'_`i' if Parent_type_ == 2
		replace father_`g'_`i' = prefother_`g'_`i' if Parent_type_ == 1
		
		gen mother_best_`g'_`i' = .
		replace mother_best_`g'_`i' = prefown_best_`g'_`i' if Parent_type_ == 1
		replace mother_best_`g'_`i' = prefother_best_`g'_`i' if Parent_type_ == 2
		gen father_best_`g'_`i' = .
		replace father_best_`g'_`i' = prefown_best_`g'_`i' if Parent_type_ == 2
		replace father_best_`g'_`i' = prefother_best_`g'_`i' if Parent_type_ == 1
		
		rename prefchild_`g'_`i' app_pref_`g'_`i'
		rename prefchild_best_`g'_`i' app_pref_best_`g'_`i'
	}
}

forval i = 42/43 {
	foreach g in "m" "f" {
		gen mother_`g'_`i'_TEXT = ""
		replace mother_`g'_`i'_TEXT = prefown_`g'_`i'_TEXT if Parent_type_ == 1
		replace mother_`g'_`i'_TEXT = prefother_`g'_`i'_TEXT if Parent_type_ == 2
		gen father_`g'_`i'_TEXT = ""
		replace father_`g'_`i'_TEXT = prefown_`g'_`i'_TEXT if Parent_type_ == 2
		replace father_`g'_`i'_TEXT = prefother_`g'_`i'_TEXT if Parent_type_ == 1
		
		gen mother_best_`g'_`i'_TEXT = ""
		replace mother_best_`g'_`i'_TEXT = prefown_best_`g'_`i'_TEXT if Parent_type_ == 1
		replace mother_best_`g'_`i'_TEXT = prefother_best_`g'_`i'_TEXT if Parent_type_ == 2
		gen father_best_`g'_`i'_TEXT = ""
		replace father_best_`g'_`i'_TEXT = prefown_best_`g'_`i'_TEXT if Parent_type_ == 2
		replace father_best_`g'_`i'_TEXT = prefother_best_`g'_`i'_TEXT if Parent_type_ == 1
		
		rename prefchild_`g'_`i'_TEXT app_pref_`g'_`i'_TEXT
		rename prefchild_best_`g'_`i'_TEXT app_pref_best_`g'_`i'_TEXT
	}
}

drop prefown* prefother*
********************************************************************************
* 9.  GENERATE COMPLETION VARIABLE AND DROP EDITED VARIABLES
*.    a.removes variables that are unecessary 
********************************************************************************
gen compl_end = 1 if t_swissborn_el_Page_Submit != . | t_ses_1_Page_Submit != .
label variable compl_end "Completed final questions"
drop *_First_Click* *_Last_Click* *_Page_Submit* *_Click_Count* Duration__in_seconds
********************************************************************************
* 10. FINAL HOUSEKEEPING & SAVE
********************************************************************************
di as txt "----- Compressing and saving dataset -----"
compress
save "${processed_data}/PS_Parents/3_ps_parents.dta", replace

timer off 1
timer list
log close
