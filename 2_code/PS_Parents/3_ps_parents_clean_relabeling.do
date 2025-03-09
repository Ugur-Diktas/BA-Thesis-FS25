********************************************************************************
* 3_ps_parents_clean_relabeling.do
* ------------------------------------------------------------------------------
* Data needed: ps_par_cleaned.dta
* Data output: ps_par_cleaned.dta
* Purpose:
*   - Convert string variables (e.g., contract, female) to numeric and recode as needed.
*   - Create new variables (e.g., el, duration_mins, and duration_* variables).
*   - Rename and label variables for home situation, tracks, social skills,
*     parent education, and occupational preferences.
*   - Standardize variable naming to facilitate parallel processing with student data.
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
log using "${dodir_log}/3_ps_parents_clean_relabeling.log", replace text

timer clear
timer on 1

* Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Parents Clean Relabeling"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************
di as txt "----- Loading dataset: ps_par_cleaned.dta -----"

* Check if input file exists
capture confirm file "${processed_data}/PS_Parents/2_ps_parents.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Parents/2_ps_parents.dta"
    di as error "Run 2_ps_parents_remove_duplicates.do first."
    exit 601
}

use "${processed_data}/PS_Parents/2_ps_parents.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_par_cleaned.dta."
    exit 602
}

********************************************************************************
* 2. CLEAN & CREATE DURATION VARIABLES
********************************************************************************
di as txt "----- Converting variables & creating duration measures -----"

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
        local varname_stripped = subinstr("`var'", "t_", "", 1)
        local varname_stripped = subinstr("`varname_stripped'", "_First_Click", "", 1)
        local varname = subinstr("`varname_stripped'", "t_", "", 1)
        
        * Check for corresponding Page_Submit variable
        capture confirm variable `varname_stripped'_Page_Submit
        if !_rc {
            di as txt "Creating duration variable for `varname'..."
            capture gen duration_`varname' = (`varname_stripped'_Page_Submit) / 60
            if _rc {
                di as error "Error creating duration_`varname': `_rc'"
            }
            else {
                di as txt "  Created duration_`varname'."
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
                       "duration_background_3_:Background page 3;duration_parent_prefs_1_:Own prefs page 1;" + ///
                       "duration_parent_prefs_2_:Own prefs page 2;duration_child_prefs_1_:Child's prefs page 1;" + ///
                       "duration_child_prefs_2_:Child's prefs page 2;duration_other_prefs_1_:Other parent's prefs page 1;" + ///
                       "duration_other_prefs_2_:Other parent's prefs page 2;duration_motivation_1_:Motivation page 1;" + ///
                       "duration_motivation_2:Motivation factors page 2;duration_beliefs_1:Beliefs page 1;" + ///
                       "duration_beliefs_2:Beliefs page 2;duration_beliefs_3:Beliefs page 3;" + ///
                       "duration_debriefing_1:Debriefing page 1;duration_debriefing_2:Debriefing page 2;" + ///
                       "duration_gender_track_:Track;duration_ses_1:SES page 1;duration_ses_2_:SES page 2;" + ///
                       "duration_end:Final page;duration_contract_occ:Contract occupation;" + ///
                       "duration_belief_el_1:Beliefs page 1 (EL);duration_belief_el_2:Beliefs page 2 (EL);" + ///
                       "duration_social_skills:Social skills;duration_gender_id_el:Gender identity (EL);" + ///
                       "duration_canton_el:Canton (EL);duration_swissborn_el:Birthplace (CH/not) (EL);" + ///
                       "duration_birthplace:Birthplace (country);duration_end_el_:Final page (EL)"

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

* Rename home_sit to home_sit_par if needed
capture confirm variable home_sit_par
if _rc > 0 {
    capture confirm variable home_sit
    if !_rc {
        di as txt "Renaming home_sit to home_sit_par..."
        rename home_sit home_sit_par
    }
}

* Define and apply home situation labels
capture label define home_sit_par_lbl ///
    1 "Both parents" ///
    2 "Sometimes mother/father" ///
    3 "Only mother, contact father" ///
    4 "Only father, contact mother" ///
    5 "Only mother, no father" ///
    6 "Only father, no mother" ///
    7 "Other", replace

capture confirm variable home_sit_par
if !_rc {
    di as txt "Applying home_sit_par labels..."
    label values home_sit_par home_sit_par_lbl
}

********************************************************************************
* 4. CLEAN SDQ VARIABLES AND SITUATION
********************************************************************************
di as txt "----- Cleaning SDQ and situation variables -----"

* Clean SDQ variables
di as txt "Creating standardized SDQ variables..."
forval i = 1/6 {
    gen sdq_`i' = .
    foreach g in "m" "f" {
        capture confirm variable social_skills_`g'_`i'
        if !_rc {
            replace sdq_`i' = social_skills_`g'_`i' if !missing(social_skills_`g'_`i')
        }
    }
    label var sdq_`i' "Social skills item `i'"
}

* Clean up original social skills variables
capture drop social_skills*

* Clean plan and sit variable
di as txt "Cleaning plan and situation variables..."
capture confirm variable plan_
if !_rc {
    rename plan_ plan
    label var plan "Planned apprenticeship"
}

gen sit = .
replace sit = 1 if Child_year_class == 1 
replace sit = 2 if Child_year_class == 2
replace sit = 1 if Child_year_class == 3
label var sit "Situation (standardized)"
capture drop Child_year_class

********************************************************************************
* 5. CLEAN MIGRATION BACKGROUND
********************************************************************************
di as txt "----- Cleaning migration background variables -----"

* Create standardized Swiss-born variables
di as txt "Creating standardized Swiss-born variables..."

* Child's Swiss-born status
gen swissborn_child = .
label var swissborn_child "Child born in Switzerland"

di as txt "Checking sources for child's Swiss-born status..."
foreach var in swissborn_1_2 swissborn_2_2 swissborn_el_2 swissborn2_el_2 {
    capture confirm variable `var'
    if !_rc {
        di as txt "  Using `var' to populate swissborn_child..."
        replace swissborn_child = `var' if !missing(`var')
    }
}

* Mother's Swiss-born status
gen swissborn_mother = .
label var swissborn_mother "Mother born in Switzerland"

di as txt "Checking sources for mother's Swiss-born status..."
capture confirm variable Parent_type_
if !_rc {
    foreach var in swissborn_1_1 swissborn_2_1 swissborn_el_1 swissborn2_el_1 {
        capture confirm variable `var'
        if !_rc {
            di as txt "  Checking `var' for mother's status when parent is mother..."
            replace swissborn_mother = `var' if !missing(`var') & Parent_type_ == 1
        }
    }
    
    foreach var in swissborn_1_3 swissborn_el_3 {
        capture confirm variable `var'
        if !_rc {
            di as txt "  Checking `var' for mother's status when parent is father..."
            replace swissborn_mother = `var' if !missing(`var') & Parent_type_ == 2
        }
    }
}
else {
    di as txt "Parent_type_ variable not found, cannot determine which parent is responding."
}

* Father's Swiss-born status
gen swissborn_father = .
label var swissborn_father "Father born in Switzerland"

di as txt "Checking sources for father's Swiss-born status..."
capture confirm variable Parent_type_
if !_rc {
    foreach var in swissborn_1_1 swissborn_2_1 swissborn_el_1 swissborn2_el_1 {
        capture confirm variable `var'
        if !_rc {
            di as txt "  Checking `var' for father's status when parent is father..."
            replace swissborn_father = `var' if !missing(`var') & Parent_type_ == 2
        }
    }
    
    foreach var in swissborn_1_3 swissborn_el_3 {
        capture confirm variable `var'
        if !_rc {
            di as txt "  Checking `var' for father's status when parent is mother..."
            replace swissborn_father = `var' if !missing(`var') & Parent_type_ == 1
        }
    }
}

* Drop original Swiss-born variables
capture drop swissborn_1* swissborn_2* swissborn_el* swissborn2_el*

* Process birthplace variables
di as txt "Processing birthplace variables..."

* Check and decode birthplace variables
foreach var in birthplace_parent1_ birthplace_parent2_ birthplace_parent3_ birthplace_el birthplace2_el birthplace3_el {
    capture confirm variable `var'
    if !_rc {
        capture confirm string variable `var'
        if _rc {
            di as txt "  Decoding `var' to string..."
            decode `var', gen(r_`var')
        }
        else {
            di as txt "  `var' is already string, renaming to r_`var'..."
            rename `var' r_`var'
        }
    }
}

* Create standardized birthplace variables
di as txt "Creating standardized birthplace variables..."
gen birthplace_mother = ""
label var birthplace_mother "Mother's birthplace"

gen birthplace_father = ""
label var birthplace_father "Father's birthplace"

* Populate mother's birthplace based on parent type
capture confirm variable Parent_type_
if !_rc {
    * When respondent is mother
    foreach var in r_birthplace_parent1_ r_this_parent_main r_this_parent_el {
        capture confirm variable `var'
        if !_rc {
            di as txt "  Checking `var' for mother's birthplace when parent is mother..."
            replace birthplace_mother = `var' if !missing(`var') & Parent_type_ == 1
        }
    }
    
    * When respondent is father
    foreach var in r_birthplace_parent2_ r_birthplace_parent3_ r_other_parent_main_1 r_other_parent_main_2 r_other_parent_el_1 r_other_parent_el_2 {
        capture confirm variable `var'
        if !_rc {
            di as txt "  Checking `var' for mother's birthplace when parent is father..."
            replace birthplace_mother = `var' if !missing(`var') & Parent_type_ == 2
        }
    }
    
    * When respondent is father
    foreach var in r_birthplace_parent1_ r_this_parent_main r_this_parent_el {
        capture confirm variable `var'
        if !_rc {
            di as txt "  Checking `var' for father's birthplace when parent is father..."
            replace birthplace_father = `var' if !missing(`var') & Parent_type_ == 2
        }
    }
    
    * When respondent is mother
    foreach var in r_birthplace_parent2_ r_birthplace_parent3_ r_other_parent_main_1 r_other_parent_main_2 r_other_parent_el_1 r_other_parent_el_2 {
        capture confirm variable `var'
        if !_rc {
            di as txt "  Checking `var' for father's birthplace when parent is mother..."
            replace birthplace_father = `var' if !missing(`var') & Parent_type_ == 1
        }
    }
}

* Drop temporary birthplace variables
capture drop r_birthplace* r_this_parent* r_other_parent*

********************************************************************************
* 6. CLEAN PARENT EDUCATION
********************************************************************************
di as txt "----- Cleaning parent education variables -----"

capture confirm variable educ_parent1
if !_rc {
    di as txt "Processing parent education variables..."
    
    * Decode education variables to string
    capture confirm string variable educ_parent1
    if _rc {
        decode educ_parent1, gen(field_educ_1)
    }
    else {
        rename educ_parent1 field_educ_1
    }
    
    capture confirm string variable educ_parent2
    if _rc {
        decode educ_parent2, gen(field_educ_2)
    }
    else {
        rename educ_parent2 field_educ_2
    }
    
    * Rename text fields if they exist
    capture confirm variable educ_parent1_7_TEXT
    if !_rc {
        rename educ_parent1_7_TEXT field_educ_1_text
    }
    
    capture confirm variable educ_parent2_7_TEXT
    if !_rc {
        rename educ_parent2_7_TEXT field_educ_2_text
    }
    
    * Drop original variables if still present
    capture drop educ_parent1 educ_parent2
}
else {
    di as txt "No educ_parent1 found, skipping parent education relabeling."
}

********************************************************************************
* 7. CLEAN PARENT PREFERENCES
********************************************************************************
di as txt "----- Cleaning parent preference variables -----"

* Standardize underscore patterns in preference variables
di as txt "Standardizing underscore patterns in preference variables..."
forval i = 1/44 {
    capture confirm variable prefother_m__`i'
    if !_rc {
        rename prefother_m__`i' prefother_m_`i'
    }
}

forval i = 42/44 {
    capture confirm variable prefother_m__`i'_TEXT
    if !_rc {
        rename prefother_m__`i'_TEXT prefother_m_`i'_TEXT
    }
}

* Create standardized mother/father preference variables
di as txt "Creating standardized mother/father preference variables..."
forval i = 1/44 {
    foreach g in "m" "f" {
        * Check if source variables exist
        local source_vars_exist = 0
        foreach var in prefown_`g'_`i' prefother_`g'_`i' {
            capture confirm variable `var'
            if !_rc {
                local source_vars_exist = 1
            }
        }
        
        if `source_vars_exist' {
            di as txt "  Creating mother_`g'_`i' and father_`g'_`i'..."
            gen mother_`g'_`i' = .
            gen father_`g'_`i' = .
            
            capture confirm variable Parent_type_
            if !_rc {
                capture confirm variable prefown_`g'_`i'
                if !_rc {
                    replace mother_`g'_`i' = prefown_`g'_`i' if Parent_type_ == 1
                    replace father_`g'_`i' = prefown_`g'_`i' if Parent_type_ == 2
                }
                
                capture confirm variable prefother_`g'_`i'
                if !_rc {
                    replace mother_`g'_`i' = prefother_`g'_`i' if Parent_type_ == 2
                    replace father_`g'_`i' = prefother_`g'_`i' if Parent_type_ == 1
                }
            }
            
            * Create standardized best preference variables
            gen mother_best_`g'_`i' = .
            gen father_best_`g'_`i' = .
            
            capture confirm variable Parent_type_
            if !_rc {
                capture confirm variable prefown_best_`g'_`i'
                if !_rc {
                    replace mother_best_`g'_`i' = prefown_best_`g'_`i' if Parent_type_ == 1
                    replace father_best_`g'_`i' = prefown_best_`g'_`i' if Parent_type_ == 2
                }
                
                capture confirm variable prefother_best_`g'_`i'
                if !_rc {
                    replace mother_best_`g'_`i' = prefother_best_`g'_`i' if Parent_type_ == 2
                    replace father_best_`g'_`i' = prefother_best_`g'_`i' if Parent_type_ == 1
                }
            }
        }
        
        * Rename child preference variables
        capture confirm variable prefchild_`g'_`i'
        if !_rc {
            rename prefchild_`g'_`i' app_pref_`g'_`i'
        }
        
        capture confirm variable prefchild_best_`g'_`i'
        if !_rc {
            rename prefchild_best_`g'_`i' app_pref_best_`g'_`i'
        }
    }
}

* Process text versions of preference variables
di as txt "Processing text versions of preference variables..."
forval i = 42/43 {
    foreach g in "m" "f" {
        * Check if source text variables exist
        local source_vars_exist = 0
        foreach var in prefown_`g'_`i'_TEXT prefother_`g'_`i'_TEXT {
            capture confirm variable `var'
            if !_rc {
                local source_vars_exist = 1
            }
        }
        
        if `source_vars_exist' {
            di as txt "  Creating mother_`g'_`i'_TEXT and father_`g'_`i'_TEXT..."
            gen mother_`g'_`i'_TEXT = ""
            gen father_`g'_`i'_TEXT = ""
            
            capture confirm variable Parent_type_
            if !_rc {
                capture confirm variable prefown_`g'_`i'_TEXT
                if !_rc {
                    replace mother_`g'_`i'_TEXT = prefown_`g'_`i'_TEXT if Parent_type_ == 1
                    replace father_`g'_`i'_TEXT = prefown_`g'_`i'_TEXT if Parent_type_ == 2
                }
                
                capture confirm variable prefother_`g'_`i'_TEXT
                if !_rc {
                    replace mother_`g'_`i'_TEXT = prefother_`g'_`i'_TEXT if Parent_type_ == 2
                    replace father_`g'_`i'_TEXT = prefother_`g'_`i'_TEXT if Parent_type_ == 1
                }
            }
            
            * Create standardized best preference text variables
            gen mother_best_`g'_`i'_TEXT = ""
            gen father_best_`g'_`i'_TEXT = ""
            
            capture confirm variable Parent_type_
            if !_rc {
                capture confirm variable prefown_best_`g'_`i'_TEXT
                if !_rc {
                    replace mother_best_`g'_`i'_TEXT = prefown_best_`g'_`i'_TEXT if Parent_type_ == 1
                    replace father_best_`g'_`i'_TEXT = prefown_best_`g'_`i'_TEXT if Parent_type_ == 2
                }
                
                capture confirm variable prefother_best_`g'_`i'_TEXT
                if !_rc {
                    replace mother_best_`g'_`i'_TEXT = prefother_best_`g'_`i'_TEXT if Parent_type_ == 2
                    replace father_best_`g'_`i'_TEXT = prefother_best_`g'_`i'_TEXT if Parent_type_ == 1
                }
            }
        }
        
        * Rename child preference text variables
        capture confirm variable prefchild_`g'_`i'_TEXT
        if !_rc {
            rename prefchild_`g'_`i'_TEXT app_pref_`g'_`i'_TEXT
        }
        
        capture confirm variable prefchild_best_`g'_`i'_TEXT
        if !_rc {
            rename prefchild_best_`g'_`i'_TEXT app_pref_best_`g'_`i'_TEXT
        }
    }
}

* Drop original preference variables
capture drop prefown* prefother*

********************************************************************************
* 8. CREATE COMPLETION INDICATOR
********************************************************************************
di as txt "----- Creating completion indicator -----"

gen compl_end = 0
capture confirm variable t_swissborn_el_Page_Submit
if !_rc {
    replace compl_end = 1 if !missing(t_swissborn_el_Page_Submit)
}

capture confirm variable t_ses_1_Page_Submit
if !_rc {
    replace compl_end = 1 if !missing(t_ses_1_Page_Submit)
}

label variable compl_end "Completed final questions"

********************************************************************************
* 9. FINAL CLEANUP
********************************************************************************
di as txt "----- Final cleanup -----"

* Remove timing variables
capture drop *_First_Click* *_Last_Click* *_Page_Submit* *_Click_Count* Duration__in_seconds_

********************************************************************************
* 10. FINAL HOUSEKEEPING & SAVE
********************************************************************************
di as txt "----- Compressing and saving dataset -----"

* Compress and save
compress
save "${processed_data}/PS_Parents/3_ps_parents.dta", replace

* Final report
di as txt "Cleaned and relabeled dataset saved to: ${processed_data}/PS_Parents/3_ps_parents.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Parents Clean Relabeling"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off