********************************************************************************
// 3_ps_students_clean_relabeling.do
// Purpose : Cleans & processes the belief-related questions in the PS Students 
//           dataset. Includes built-in debug steps to handle naming issues.
// 
// Author  : Ugur Diktas_Jelke Clarysse, BA Thesis FS25, 19.02.2025
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************
/*
clear all
set more off
version 17.0

cap log close
log using "${dodir_log}/ps_students_clean_relabeling.log", replace text

// Turn on Stata's trace for very detailed debugging (comment out if too verbose).
// set trace on

timer clear
timer on 1


********************************************************************************
// 1. LOAD THE CLEANED DATA
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
// 2.REMOVE TEST ANSWERS
********************************************************************************
*Drop the test answers 
drop if test != ""
drop if Status == 1

*Drop if answered before 11 November 10:00 (test responses)
format StartDate %tc
drop if StartDate < clock("2024-11-11 10:00:00", "YMDhms")

merge 1:1 ResponseId using "${sensitive_data}/ps_stu_sensitive_only", keep(master match) keepusing(ResponseId stu_first_name stu_last_name email) nogen


*Drop if email is a test email
drop if email == "daphne.rutnam@econ.uzh.ch" | email == "hannah.massenbauer@econ.uzh.ch" | email == "anne.brenoe@econ.uzh.ch" | email == "gianluca.spina@uzh.ch" | email == "Anne.brenoe@econ.uzh.ch" | email == "daphne.rutnam@gmail.com"

*Drop if feedback is "Test" or "test"
drop if feedback == "Test" | feedback == "test"

*Deal with ones where schoolid is missing but can be identified by class name and date
replace schoolid = "6002" if (name_class == "B2B" | name_class == "B2b" | name_class == "R2a" | name_class == "B1b" | name_class == "B23b" | name_class == "B2a") & sbID == "1" & StartDate < clock("2024-21-11 20:00:00", "YMDhms") & missing(schoolid)

********************************************************************************
// 3.CLEANS DURATION VARIABLES-MAKES FULL DURATION VARIABLES 
********************************************************************************

destring contract, replace
destring female, replace

*Create variable indicating whether in EL or not
gen el = contract == 1
lab var el "EL"

*Create variable of duration in minutes
gen duration_mins = Duration__in_seconds_/60
label var duration_mins "Total duration (mins)"

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
// 4.CLEAN HOME SITUATION
********************************************************************************
//RELABELING HOME SITUATION IN ENGLISH

rename home_sit home_sit_stu
label define home_sit_stu_lab 1 "Both parents" 2 "Sometimes mother, sometimes father" 3 "Only mother, contact with father" 4 "Only father, contact with mother" 5 "Only mother, no contact with father" 6 "Only father, no contact with mother" 7 "Other"
label values home_sit_stu home_sit_stu_lab

********************************************************************************
// 5.RELABELING TRACKS AND MAKING TRACKS OVERVIEW 
********************************************************************************
/*
*Clean canton and track
decode track_1, gen(r_canton) 
decode track_2, gen(r_school_track_name)

assert r_canton == canton | canton == "Grigioni"
gen track_error = 1 if r_canton != canton
replace canton = r_canton
drop r_canton

assert r_school_track_name == school_type | school_type == "Karışık"
replace track_error = 1 if r_school_track_name != school_type
rename r_school_track_name school_track_name
replace school_type = school_track_name

assert missing(school_track) if track_error == 1

*Clean the school track
gen new_school_name = school_track_name
merge m:1 canton new_school_name using "${data_to_merge}/new_drill_down_school_tracks", keep(master match) keepusing(canton new_school_name new_track_standardized) 
assert _merge == 3 | missing(school_track_name)
drop _merge
assert school_track == new_track_standardized | track_error == 1
replace school_track = new_track_standardized if track_error == 1
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
// 6.RELABELING MATH AND LANGUAGE 
********************************************************************************

*Rename math and language level and grade vars
rename math_level_ math_level
rename lang_level_ lang_level
rename math_grade_ math_grade
rename lang_grade_ lang_grade

*Clean sdq vars
forval i = 1/6 {
	rename sdq__`i' sdq_`i'
}

*Clean plan and sit variable
rename plan_ plan
gen sit = .
replace sit = 1 if sit_ == 1 
replace sit = 2 if sit_ == 2
replace sit = 4 if sit_ == 3
drop sit_

********************************************************************************
// 7.CLEANING SWISSBORN-MIGRATION BACKGROUND
********************************************************************************
*Clean swissborn and birthplace vars
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

decode birthplace_mother, gen(r_birthplace_mother)
decode birthplace_father1_, gen(r_birthplace_father1)
decode birthplace_father2, gen(r_birthplace_father2)
drop birthplace_mother birthplace_father1_ birthplace_father2
rename r_birthplace_mother birthplace_mother

gen birthplace_father = ""
replace birthplace_father = r_birthplace_father1 if !missing(r_birthplace_father1)
replace birthplace_father = r_birthplace_father2 if !missing(r_birthplace_father2)
drop r_birthplace_father1 r_birthplace_father2

********************************************************************************
// 8.RELABELING PARENTS EDUCATION
********************************************************************************

decode educ_parent1, gen(field_educ_mother)
decode educ_parent2, gen(field_educ_father)
rename educ_parent1_7_TEXT field_educ_mother_text
rename educ_parent2_7_TEXT field_educ_father_text
drop educ_parent1* educ_parent2*

********************************************************************************
// 9. CLEANING MATH AND LANGUAGE 
********************************************************************************

//STILL NEEDS TO BE EVALUATED
/*
*Create a variable math_level_name/lang_level_name which is the canton-specific name of the level
foreach x in "math_level" "lang_level" {
	
	gen `x'_name = "" // this will be the canton-specific name of the math/lang level

	decode `x', gen(`x'_string)

	gen specific_`x' = 1 if !missing(`x') // this indicates that they answered about the level

	forvalues i = 1/7 {
		replace `x'_name = school_type`i' if `x' == `i' // replace for school type 1-6 answers
	}

	replace `x'_name = `x'_string if specific_`x' == 1 & missing(`x'_name) // replace with string answer

	replace `x'_name = school_track_name if missing(`x') // replace with school track name if not asked

}


*Merge with the drill down list to find the standardized track (low, middle, high etc.)
foreach x in "math_level" "lang_level" {
	gen new_school_name = `x'_name
	merge m:1 canton new_school_name using "${data_to_merge}/new_drill_down_school_tracks", keep(master match) nogen
	gen correct_`x' = new_track_standardized
	drop new_track_standardized new_school_name
	
	replace correct_`x' = "high" if (`x'_name == "Niveau I" & canton == "Zürich")| (`x'_name == "Niveau e: erweiterte Anforderungen" & canton == "Thurgau")
	replace correct_`x' = "middle" if (`x'_name == "Niveau II" & canton == "Zürich") | (`x'_name == "Niveau m: mittlere Anforderungen" & canton == "Thurgau")
	replace correct_`x' = "low" if (`x'_name == "Niveau III" & canton == "Zürich") | (`x'_name == "Niveau g: grundlegende Anforderungen" & canton == "Thurgau")
	replace correct_`x' = school_track if `x'_name == "In meiner Schule gibt es keine Niveaus"
	
	*Encode the math and language level
	gen `x'_track = .
	replace `x'_track = 1 if correct_`x' == "low"
	replace `x'_track = 2 if correct_`x' == "middle"
	replace `x'_track = 3 if correct_`x' == "intermediate"
	replace `x'_track = 4 if correct_`x' == "high"
	replace `x'_track = 5 if correct_`x' == "mixed"
	replace `x'_track = 6 if correct_`x' == "other"
	
	*Label encoded math and language level values
	label values `x'_track track_labels
	
}

drop correct_*_level *_level_name *_level_string specific_*_level old_school* *_schools_old_new
*/

********************************************************************************
// 10. RELABELING PREFERENCES WITH DAPHNE CODE-CLEANING OCCUPATIONAL PREFFERENCES 
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
	rename preffather_best_m_`i' father_best_m_`i'
	rename preffather_best_f__`i' father_best_f_`i'
}

forval i = 42/44 {
	rename prefchild_m_`i'_TEXT app_pref_m_`i'_TEXT
	rename prefchild_best_m_`i'_TEXT app_pref_best_m_`i'_TEXT
	rename prefchild_f__`i' app_pref_f_`i'_TEXT
	rename prefchild_best_f__`i' app_pref_best_f_`i'_TEXT
	
	rename prefmother_m__`i'_TEXT mother_m_`i'_TEXT
	rename prefmother_f__`i'_TEXT mother_f_`i'_TEXT
	rename prefmother_best_m__`i'_TEXT mother_best_m_`i'_TEXT
	rename prefmother_best_f__`i'_TEXT mother_best_f_`i'_TEXT
	
	rename preffather_m__`i'_TEXT father_m_`i'_TEXT
	rename preffather_f__`i'_TEXT father_f_`i'_TEXT
	rename preffather_best_m_`i'_TEXT father_best_m_`i'_TEXT
	rename preffather_best_f__`i'_TEXT father_best_f_`i'_TEXT
}

forval i =1/45 {
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
		rename ta_occs_`g'__`i'_TEXT ta_occs_`g'_`i'_TEXT
		rename reject_ta_`g'__`i'_TEXT reject_ta_`g'_`i'_TEXT
		rename offers2_`g'__`i'_TEXT offers2_`g'_`i'_TEXT
	}
}

forval i = 42/44 {
	foreach g in "m" "f" {
		rename apply_occs_`g'__`i'_TEXT apply_occs_`g'_`i'_TEXT
	}
}

********************************************************************************
*****Create variables indicating how much of the survey they have completed***** 

gen compl_end = 1 if t_ses_1_Page_Submit != .
label variable compl_end "Completed final questions"

********************************************************************************
// 11. DROP UNEEDED VARIABLES
********************************************************************************
/*	*Drop variables that are missing from qualtrics
	drop recipient*

	*Drop variables that are not useful from qualtrics
	drop _v*
	
	*Drop qualtrics variables
	drop status progress finished recordeddate distributionchannel userlanguage

	*Drop timers
	drop *_first_click* *_last_click* *_page_submit* *_click_count* duration__in_seconds

	*Drop question wording variables
	drop q_*
*/
********************************************************************************
// 12. FINAL HOUSEKEEPING & SAVE
********************************************************************************

di as txt "----- Compressing and saving dataset -----"
compress

save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list

// Turn off trace if you turned it on earlier.
// set trace off

log close
