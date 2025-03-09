********************************************************************************
* 4_ps_students_clean_beliefs.do
* ------------------------------------------------------------------------------
* Data needed: ps_stu_cleaned.dta
* Data output: ps_stu_cleaned.dta
* Purpose:
*   - Load the cleaned PS Students dataset (ps_stu_cleaned.dta).
*   - Rename & reshape key belief–related variables (e.g. marriage_prob, 
*     belief_fit, mother/father approvals, etc.) into occupation–specific 
*     variables.
*   - Label the new variables.
*   - Create standardised averages for "GC" (gender–consistent) and "GIC"
*     (gender–inconsistent) occupations. (Note: the row–means are multiplied 
*     by 2 to rescale to the original Likert scale.)
*   - Save the updated dataset.
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

// Enable or disable trace based on debug flag
if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

// Start logging
cap log close
log using "${dodir_log}/4_ps_students_clean_beliefs.log", replace text

timer clear
timer on 1

* Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Students Clean Beliefs"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************
di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"

* Check if input file exists
capture confirm file "${processed_data}/PS_Students/3_ps_students.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Students/3_ps_students.dta"
    di as error "Run 3_ps_students_clean_relabeling.do first."
    exit 601
}

use "${processed_data}/PS_Students/3_ps_students.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    exit 602
}

********************************************************************************
* 2. RENAME / PREP BELIEF VARIABLES
********************************************************************************
di as txt "----- Renaming and preparing belief variables -----"

// Rename marriage probability variables
capture confirm variable marriage_prob_fit_1
if !_rc {
    di as txt "Renaming marriage probability variables..."
    rename marriage_prob_fit_1 marriage_prob_1
    rename marriage_prob_fit_2 marriage_prob_2
}
else {
    di as txt "Marriage probability variables not found, skipping."
}

// Rename the belief-fit & like-task variables from Qualtrics 
// to a simpler pattern (e.g., belief_fit__1 becomes belief_fit_1).
foreach belief_q_var in belief_fit like_task {
    capture confirm variable `belief_q_var'__1
    if !_rc {
        di as txt "Renaming `belief_q_var' variables..."
        forval i = 1/2 {
            rename `belief_q_var'__`i' `belief_q_var'_`i'
        }
    }
    else {
        di as txt "`belief_q_var' variables not found or already renamed, skipping."
    }
}

// Process mother/father approval variables:
// (If the "new" variables are missing, fill them from the originals.)
di as txt "Processing parental approval variables..."

// Check for mother approval variables
local mother_approval_exists = 0
foreach i in 1 2 {
    capture confirm variable mother_approval_1new_`i'
    if !_rc {
        local mother_approval_exists = 1
    }
}

if `mother_approval_exists' == 1 {
    di as txt "  Processing mother approval variables..."
    forval i = 1/2 {
        // Fill in new variables from original variables if missing
        capture confirm variable mother_approval_1new_`i'
        if !_rc {
            capture confirm variable mother_approval_1__`i'
            if !_rc {
                replace mother_approval_1new_`i' = mother_approval_1__`i' if missing(mother_approval_1new_`i')
            }
        }
        
        // Fill in second new variables if missing
        capture confirm variable mother_approval_2new_`i'
        if !_rc {
            capture confirm variable mother_approval_2_`i'
            if !_rc {
                replace mother_approval_2new_`i' = mother_approval_2_`i' if missing(mother_approval_2new_`i')
            }
        }
        
        // Create consolidated mother_approval variable
        gen mother_approval_`i' = .
        
        capture confirm variable mother_approval_1new_`i'
        if !_rc {
            replace mother_approval_`i' = mother_approval_1new_`i' if !missing(mother_approval_1new_`i')
        }
        
        capture confirm variable mother_approval_2new_`i'
        if !_rc {
            replace mother_approval_`i' = mother_approval_2new_`i' if !missing(mother_approval_2new_`i')
        }
    }
    
    // Drop original variables
    capture drop mother_approval_1new* mother_approval_2new* mother_approval_1__* mother_approval_2_*
}

// Check for father approval variables
local father_approval_exists = 0
foreach i in 1 2 {
    capture confirm variable father_approval_new_`i'
    if !_rc {
        local father_approval_exists = 1
    }
}

if `father_approval_exists' == 1 {
    di as txt "  Processing father approval variables..."
    forval i = 1/2 {
        // Fill in new variables from original variables if missing
        capture confirm variable father_approval_new_`i'
        if !_rc {
            capture confirm variable father_approval__`i'
            if !_rc {
                replace father_approval_new_`i' = father_approval__`i' if missing(father_approval_new_`i')
            }
        }
        
        // Create consolidated father_approval variable
        gen father_approval_`i' = .
        
        capture confirm variable father_approval_new_`i'
        if !_rc {
            replace father_approval_`i' = father_approval_new_`i'
        }
    }
    
    // Drop original variables
    capture drop father_approval__* father_approval_new*
}

********************************************************************************
* 3. DEFINE PROGRAMS TO EXPAND OCCUPATION–SPECIFIC VARIABLES
********************************************************************************
di as txt "----- Defining programs for occupation-specific variable expansion -----"

*--- For items with four source variables (expected: _1, _2, _3, _4)
capture program drop expand_occ_vars_foursrc
program define expand_occ_vars_foursrc, rclass
    syntax , Qvar(string) Name(string)
    local q = "`qvar'"
    capture confirm variable `q'_1
    if _rc {
         di as error "Variable `q'_1 not found. Skipping expansion for `q'."
         exit 0
    }
    forval j = 2/7 {
         gen `q'_occ`j' = .
    }
    lab var `q'_occ2 "`name' FaGe"
    lab var `q'_occ3 "`name' FaBe"
    lab var `q'_occ4 "`name' MPA"
    lab var `q'_occ5 "`name' Informatiker/-in"
    lab var `q'_occ6 "`name' Konstrukteur/-in"
    lab var `q'_occ7 "`name' Polymechaniker/-in"
    // Drop the original source variables _1 through _4.
    drop `q'_1 `q'_2 `q'_3 `q'_4
end

*--- For items with two source variables (expected: _1 and _2)
capture program drop expand_occ_vars_twosrc
program define expand_occ_vars_twosrc, rclass
    syntax , Qvar(string) Name(string)
    local q = "`qvar'"
    capture confirm variable `q'_1
    if _rc {
         di as error "Variable `q'_1 not found. Skipping expansion for `q'."
         exit 0
    }
    forval j = 2/7 {
         gen `q'_occ`j' = .
    }
    lab var `q'_occ2 "`name' FaGe"
    lab var `q'_occ3 "`name' FaBe"
    lab var `q'_occ4 "`name' MPA"
    lab var `q'_occ5 "`name' Informatiker/-in"
    lab var `q'_occ6 "`name' Konstrukteur/-in"
    lab var `q'_occ7 "`name' Polymechaniker/-in"
    
    * Check if traditional_role_* variables exist
    local role_vars_exist = 1
    forval i = 1/2 {
        capture confirm variable traditional_role_`i'
        if _rc {
            local role_vars_exist = 0
        }
    }
    
    if `role_vars_exist' {
        forval i = 1/2 {
            replace `q'_occ2 = `q'_`i' if traditional_role_`i' == "Fachfrau Gesundheit (FaGe)" | ///
                                           traditional_role_`i' == "Fachmann Gesundheit (FaGe)"
            replace `q'_occ3 = `q'_`i' if traditional_role_`i' == "Fachfrau Betreuung (FaBe)" | ///
                                           traditional_role_`i' == "Fachmann Betreuung (FaBe)"
            replace `q'_occ4 = `q'_`i' if traditional_role_`i' == "Medizinischer Praxisassistent (MPA)" | ///
                                           traditional_role_`i' == "Medizinische Praxisassistentin (MPA)"
            replace `q'_occ5 = `q'_`i' if traditional_role_`i' == "Informatiker" | ///
                                           traditional_role_`i' == "Informatikerin"
            replace `q'_occ6 = `q'_`i' if traditional_role_`i' == "Konstrukteur" | ///
                                           traditional_role_`i' == "Konstrukteurin"
            replace `q'_occ7 = `q'_`i' if traditional_role_`i' == "Polymechaniker" | ///
                                           traditional_role_`i' == "Polymechanikerin"
        }
    }
    else {
        di as error "traditional_role_* variables not found. Cannot map occ-specific values."
    }
    
    drop `q'_1 `q'_2
end

*--- For friend–related items with three source variables (expected: _1, _2, _3)
capture program drop expand_occ_vars_threesrc
program define expand_occ_vars_threesrc, rclass
    syntax , Qvar(string) Name(string)
    local q = "`qvar'"
    capture confirm variable `q'_1
    if _rc {
         di as error "Variable `q'_1 not found. Skipping expansion for `q'."
         exit 0
    }
    forval j = 2/10 {
         gen `q'_occ`j' = .
    }
    lab var `q'_occ2 "`name' FaGe"
    lab var `q'_occ3 "`name' FaBe"
    lab var `q'_occ4 "`name' MPA"
    lab var `q'_occ5 "`name' Informatiker"
    lab var `q'_occ7 "`name' Polymechaniker"
    lab var `q'_occ8 "`name' Elektroinstallateur"
    lab var `q'_occ9 "`name' Kaufmann"
    lab var `q'_occ10 "`name' Detailhandelsfachmann"
    
    * Check if occ_friend* variables exist
    local friend_vars_exist = 1
    forval i = 1/3 {
        capture confirm variable occ_friend`i'
        if _rc {
            local friend_vars_exist = 0
        }
    }
    
    if `friend_vars_exist' {
        forvalues i = 1/3 {
            replace `q'_occ2 = `q'_`i' if occ_friend`i' == "Fachmann Gesundheit EFZ"
            replace `q'_occ3 = `q'_`i' if occ_friend`i' == "Fachmann Betreuung EFZ"
            replace `q'_occ4 = `q'_`i' if occ_friend`i' == "Medizinischer Praxisassistent EFZ"
            replace `q'_occ5 = `q'_`i' if occ_friend`i' == "Informatiker EFZ"
            replace `q'_occ7 = `q'_`i' if occ_friend`i' == "Polymechaniker EFZ"
            replace `q'_occ8 = `q'_`i' if occ_friend`i' == "Elektroinstallateur EFZ"
            replace `q'_occ9 = `q'_`i' if occ_friend`i' == "Kaufmann EFZ"
            replace `q'_occ10 = `q'_`i' if occ_friend`i' == "Detailhandelsfachmann EFZ"
        }
    }
    else {
        di as error "occ_friend* variables not found. Cannot map occ-specific values."
    }
    
    drop `q'_1 `q'_2 `q'_3
end

********************************************************************************
* 4. EXPAND BELIEF QUESTIONS INTO OCC–SPECIFIC VARIABLES
********************************************************************************
di as txt "----- Expanding belief questions into occupation-specific variables -----"

* Define local variable names
loc name_belief_fit "Belief fit"
loc name_like_task "Belief like tasks"
loc name_marriage_prob "Belief marriage probability"
loc name_future_fit "Belief future happiness"
loc name_colleague_fit "Colleague fit"
loc name_belief_demand "Belief demand"
loc name_mother_approval "Mother approval"
loc name_father_approval "Father approval"

// For items that might have either 2 or 4 sources, check if a third source exists.
// (For example, if belief_fit_3 is missing, use the two–source expansion.)
foreach q_var in belief_fit like_task colleague_fit belief_demand {
    di as txt "Processing `q_var'..."
    capture confirm variable `q_var'_3
    if _rc {
         di as txt "  Variable `q_var'_3 not found; using two-source expansion."
         expand_occ_vars_twosrc, qvar("`q_var'") name("`name_`q_var''")
    }
    else {
         di as txt "  Variable `q_var'_3 found; using four-source expansion."
         expand_occ_vars_foursrc, qvar("`q_var'") name("`name_`q_var''")
    }
}

// Process two–source items (e.g., marriage_prob, future_fit, mother_approval, father_approval)
foreach q_var in marriage_prob future_fit mother_approval father_approval {
    di as txt "Processing `q_var'..."
    capture confirm variable `q_var'_1
    if !_rc {
        expand_occ_vars_twosrc, qvar("`q_var'") name("`name_`q_var''")
    }
    else {
        di as txt "  Variable `q_var'_1 not found; skipping."
    }
}

// Process friend–related belief items (expected to have 3 source variables)
// Only call the expansion program if the source variable exists.
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit ///
                 friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    di as txt "Processing `q_var'..."
    capture confirm variable `q_var'_1
    if !_rc {
        expand_occ_vars_threesrc, qvar("`q_var'") name("`name_`q_var''")
    }
    else {
        di as txt "  Variable `q_var'_1 not found; skipping."
    }
}

********************************************************************************
* 5. LABEL DEFINITIONS FOR THE NEW OCC VARIABLES
********************************************************************************
di as txt "----- Defining labels for occupation-specific variables -----"

// Label definition for "fit" or "like_task"–type responses:
capture label define belief_q_labels ///
    1 "Not at all" ///
    2 "Little" ///
    3 "Moderately" ///
    4 "Well" ///
    5 "Very well", replace

foreach q_var in belief_fit like_task future_fit {
    di as txt "Labeling `q_var' occupation-specific variables..."
    forval i = 2/7 {
        capture confirm variable `q_var'_occ`i'
        if !_rc {
            label values `q_var'_occ`i' belief_q_labels
        }
    }
}

// Label definition for "marriage_prob" responses:
capture label define demand_labels ///
    1 "Very unlikely" ///
    2 "Unlikely" ///
    3 "Moderately" ///
    4 "Likely" ///
    5 "Very likely", replace

foreach q_var in marriage_prob {
    di as txt "Labeling `q_var' occupation-specific variables..."
    forval i = 2/7 {
        capture confirm variable `q_var'_occ`i'
        if !_rc {
            label values `q_var'_occ`i' demand_labels
        }
    }
}

// Label definitions for parent approval variables:
capture label define approval_labels ///
    1 "Very sceptical" ///
    2 "Sceptical" ///
    3 "Moderate" ///
    4 "Supportive" ///
    5 "Very supportive", replace

foreach q_var in mother_approval father_approval {
    di as txt "Labeling `q_var' occupation-specific variables..."
    forval i = 2/7 {
        capture confirm variable `q_var'_occ`i'
        if !_rc {
            label values `q_var'_occ`i' approval_labels
        }
    }
}

*--- For friend–related items, first check that the expansion created the expected variables.
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit ///
                 friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    di as txt "Labeling `q_var' occupation-specific variables..."
    capture confirm variable `q_var'_occ2
    if !_rc {
        forval i = 2/10 {
            capture confirm variable `q_var'_occ`i'
            if !_rc {
                label values `q_var'_occ`i' belief_q_labels
            }
        }
    }
    else {
        di as txt "  Variable `q_var'_occ2 not found; skipping labeling."
    }
}

********************************************************************************
* 6. CREATE STANDARDIZED AVERAGE VARIABLES
********************************************************************************
di as txt "----- Creating standardized average variables -----"

/* For each belief dimension, we compute row–means separately for the 
   "female–coded" occupations (columns 2–4) and "male–coded" occupations 
   (columns 5–7). We then multiply the row–mean by 2.
   This multiplication by 2 is performed so that the computed averages (which 
   were based on the reduced (averaged) scale) are rescaled to match the original 
   Likert–scale (e.g., 1–5) used in the survey.
*/
capture label define belief_qs_ave_lab ///
    2 "Not at all" 3 "Not at all/little" 4 "Little" 5 "Little/moderately" 6 "Moderately" ///
    7 "Moderately/well" 8 "Well" 9 "Well/very well" 10 "Very well", replace

// Check if female variable exists for gender-consistent/inconsistent calculations
capture confirm variable female
if _rc {
    di as error "WARNING: female variable not found. Cannot create gender-consistent averages."
    local skip_gc_averages = 1
}
else {
    local skip_gc_averages = 0
}

if `skip_gc_averages' == 0 {
    // Standardize items with two sources:
    foreach q_var in belief_fit like_task marriage_prob future_fit mother_approval father_approval {
        di as txt "Creating standardized averages for `q_var'..."
        
        // Check if occupation-specific variables exist
        local occ_vars_exist = 1
        forval i = 2/7 {
            capture confirm variable `q_var'_occ`i'
            if _rc {
                local occ_vars_exist = 0
            }
        }
        
        if `occ_vars_exist' {
            // Create female-coded and male-coded averages
            egen `q_var'_fem_ave = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
            egen `q_var'_mal_ave = rowmean(`q_var'_occ5 `q_var'_occ6 `q_var'_occ7)
            
            // Create gender-consistent and gender-inconsistent averages
            gen `q_var'_gc_ave = .
            gen `q_var'_gic_ave = .
            
            // For female respondents (female==1): use the female-coded average for GC; for males, use the male-coded.
            replace `q_var'_gc_ave = 2*`q_var'_fem_ave if female == 1
            replace `q_var'_gc_ave = 2*`q_var'_mal_ave if female == 0
            
            // For gender-inconsistent averages (GIC), use the opposite.
            replace `q_var'_gic_ave = 2*`q_var'_fem_ave if female == 0
            replace `q_var'_gic_ave = 2*`q_var'_mal_ave if female == 1
            
            // Drop temporary variables
            drop `q_var'_fem_ave `q_var'_mal_ave
            
            // Label the new variables
            label var `q_var'_gc_ave "Average `q_var': Gender-consistent occupations"
            label var `q_var'_gic_ave "Average `q_var': Gender-inconsistent occupations"
            label values `q_var'_gc_ave belief_qs_ave_lab
            label values `q_var'_gic_ave belief_qs_ave_lab
            
            di as txt "  Created `q_var'_gc_ave and `q_var'_gic_ave."
        }
        else {
            di as txt "  Occupation-specific variables for `q_var' not found; skipping standardized averages."
        }
    }

    // Standardize parent approval items:
    foreach q_var in mother_approval father_approval {
        di as txt "Creating parent approval averages for `q_var'..."
        
        // Check if occupation-specific variables exist
        local occ_vars_exist = 1
        forval i = 2/7 {
            capture confirm variable `q_var'_occ`i'
            if _rc {
                local occ_vars_exist = 0
            }
        }
        
        if `occ_vars_exist' {
            // Create female-coded and male-coded averages
            egen `q_var'_fem_ave = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
            egen `q_var'_mal_ave = rowmean(`q_var'_occ5 `q_var'_occ6 `q_var'_occ7)
            
            // Create gender-consistent and gender-inconsistent averages
            gen `q_var'_gc = .
            gen `q_var'_gic = .
            
            replace `q_var'_gc = `q_var'_fem_ave if female == 1
            replace `q_var'_gc = `q_var'_mal_ave if female == 0
            replace `q_var'_gic = `q_var'_fem_ave if female == 0
            replace `q_var'_gic = `q_var'_mal_ave if female == 1
            
            // Drop temporary variables
            drop `q_var'_fem_ave `q_var'_mal_ave
            
            // Label the new variables
            label var `q_var'_gc "Average `q_var': for gender-consistent occ"
            label var `q_var'_gic "Average `q_var': for gender-inconsistent occ"
            label values `q_var'_gc approval_labels
            label values `q_var'_gic approval_labels
            
            di as txt "  Created `q_var'_gc and `q_var'_gic."
        }
        else {
            di as txt "  Occupation-specific variables for `q_var' not found; skipping averages."
        }
    }

    // Standardize friend–related belief items.
    // Only process friend items if the expected expansion variables exist.
    foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit ///
                    friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
        di as txt "Creating friend-related averages for `q_var'..."
        
        capture confirm variable `q_var'_occ2
        if !_rc {
            // Check if all required variables exist
            local friend_vars_exist = 1
            foreach i in 2 3 4 5 7 8 9 10 {
                capture confirm variable `q_var'_occ`i'
                if _rc {
                    local friend_vars_exist = 0
                }
            }
            
            if `friend_vars_exist' {
                // Create averages for different occupation groups
                egen `q_var'_gic = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
                egen `q_var'_gc = rowmean(`q_var'_occ5 `q_var'_occ7 `q_var'_occ8)
                egen `q_var'_gn = rowmean(`q_var'_occ9 `q_var'_occ10)
                
                // Rescale to original scale
                replace `q_var'_gc = 2*`q_var'_gc
                replace `q_var'_gic = 2*`q_var'_gic
                replace `q_var'_gn = 2*`q_var'_gn
                
                // Label the new variables
                label var `q_var'_gc "`q_var' to gender-consistent occs"
                label var `q_var'_gic "`q_var' to gender-inconsistent occs"
                label var `q_var'_gn "`q_var' to gender-neutral occs"
                label values `q_var'_gc belief_qs_ave_lab
                label values `q_var'_gic belief_qs_ave_lab
                label values `q_var'_gn belief_qs_ave_lab
                
                di as txt "  Created `q_var'_gc, `q_var'_gic, and `q_var'_gn."
            }
            else {
                di as txt "  Not all required occupation-specific variables for `q_var' found; skipping averages."
            }
        }
        else {
            di as txt "  Variable `q_var'_occ2 not found; skipping standardized averages."
        }
    }
}

********************************************************************************
* 7. FINAL HOUSEKEEPING & SAVE
********************************************************************************
di as txt "----- Compressing and saving dataset -----"

// Compress and save
compress
save "${processed_data}/PS_Students/4_ps_students.dta", replace

// Final report
di as txt "Cleaned beliefs dataset saved to: ${processed_data}/PS_Students/4_ps_students.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Students Clean Beliefs"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off