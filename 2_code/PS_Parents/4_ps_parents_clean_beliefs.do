********************************************************************************
* 4_ps_parents_clean_beliefs.do
* ------------------------------------------------------------------------------
* Data needed: ps_par_cleaned.dta
* Data output: ps_par_clean_beliefs.dta
* Purpose:
*   - Load the cleaned PS Parents dataset (ps_par_cleaned.dta).
*   - Rename & reshape key belief–related variables (e.g. belief_fit, like_task,
*     colleague_fit, employer_fit → belief_demand, marriage_prob_fit, future_fit, 
*     approval_fit, etc.) into occupation–specific variables.
*   - Label the new variables.
*   - Create standardised averages for "GC" (gender–consistent) and "GIC"
*     (gender–inconsistent) occupations.
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
log using "${dodir_log}/4_ps_parents_clean_beliefs.log", replace text

timer clear
timer on 1

// Display execution start
di as txt "======================================================="
di as txt "STARTING: PS Parents Clean Beliefs"
di as txt "======================================================="
di as txt "Current time: $S_TIME $S_DATE"

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************
di as txt "----- Loading dataset: ps_par_cleaned.dta -----"

// Check if input file exists
capture confirm file "${processed_data}/PS_Parents/3_ps_parents.dta"
if _rc {
    di as error "ERROR: Input file not found: ${processed_data}/PS_Parents/3_ps_parents.dta"
    di as error "Run 3_ps_parents_clean_relabeling.do first."
    exit 601
}

use "${processed_data}/PS_Parents/3_ps_parents.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in dataset."
    exit 602
}

********************************************************************************
* 2. RENAME / PREP BELIEF VARIABLES
********************************************************************************
di as txt "----- Renaming and preparing belief variables -----"

// Rename marriage probability variables:
capture confirm variable marriage_prob_fit_1
if !_rc {
    di as txt "Renaming marriage probability variables..."
    rename marriage_prob_fit_1 marriage_prob_1
    rename marriage_prob_fit_2 marriage_prob_2
}
else {
    di as txt "Marriage probability variables not found or already renamed."
}

// Check for double underscores in belief_fit, like_task and colleague_fit variables
foreach belief_q_var in belief_fit like_task colleague_fit {
    capture confirm variable `belief_q_var'__1
    if !_rc {
        di as txt "Converting double underscores to single in `belief_q_var' variables..."
        forval i = 1/2 {
            rename `belief_q_var'__`i' `belief_q_var'_`i'
        }
    }
    else {
        di as txt "`belief_q_var' variables with double underscores not found, checking single underscores..."
        
        // Verify if variables with single underscores exist
        capture confirm variable `belief_q_var'_1
        if !_rc {
            di as txt "Found `belief_q_var' variables with single underscores."
        }
        else {
            di as txt "`belief_q_var' variables not found with either single or double underscores."
        }
    }
}

// Rename employer_fit variables to belief_demand (if they exist)
capture confirm variable employer_fit_1
if !_rc {
    di as txt "Renaming employer_fit to belief_demand..."
    rename employer_fit_1 belief_demand_1
    rename employer_fit_2 belief_demand_2
}
else {
    di as txt "employer_fit variables not found, skipping rename to belief_demand."
}

// Process approval variables:
// (If multiple versions exist, consolidate them)
di as txt "Processing approval variables..."

// Check for various approval variable patterns
foreach i in 1 2 {
    // Check for op_approval_fit variables
    capture confirm variable op_approval_fit_`i'
    if !_rc {
        di as txt "Found op_approval_fit_`i', creating par_approval_fit_`i'..."
        gen par_approval_fit_`i' = op_approval_fit_`i'
    }
    
    // Check for approval_fit variables
    capture confirm variable approval_fit_`i'
    if !_rc {
        di as txt "Found approval_fit_`i', creating par_approval_fit_`i' if not exists..."
        capture confirm variable par_approval_fit_`i'
        if _rc {
            gen par_approval_fit_`i' = approval_fit_`i'
        }
        else {
            replace par_approval_fit_`i' = approval_fit_`i' if missing(par_approval_fit_`i')
        }
    }
    
    // Check for approval_fit_new variables
    capture confirm variable approval_fit_new_`i'
    if !_rc {
        di as txt "Found approval_fit_new_`i', updating par_approval_fit_`i' if exists..."
        capture confirm variable par_approval_fit_`i'
        if !_rc {
            replace par_approval_fit_`i' = approval_fit_new_`i' if missing(par_approval_fit_`i')
        }
        else {
            gen par_approval_fit_`i' = approval_fit_new_`i'
        }
    }
    
    // Check for op_approval_fit_new variables
    capture confirm variable op_approval_fit_new_`i'
    if !_rc {
        di as txt "Found op_approval_fit_new_`i', updating par_approval_fit_`i' if exists..."
        capture confirm variable par_approval_fit_`i'
        if !_rc {
            replace par_approval_fit_`i' = op_approval_fit_new_`i' if missing(par_approval_fit_`i')
        }
        else {
            gen par_approval_fit_`i' = op_approval_fit_new_`i'
        }
    }
}

// Label the consolidated approval variables
foreach i in 1 2 {
    capture confirm variable par_approval_fit_`i'
    if !_rc {
        label var par_approval_fit_`i' "Parent's approval (item `i')"
    }
}

********************************************************************************
* 3. DEFINE PROGRAMS TO EXPAND OCCUPATION–SPECIFIC VARIABLES
********************************************************************************
di as txt "----- Defining programs for occupation-specific variable expansion -----"

capture program drop expand_occ_vars_foursrc
program define expand_occ_vars_foursrc, rclass
    syntax , Qvar(string) Name(string)
    local q = "`qvar'"
    capture confirm variable `q'_1
    if _rc {
         di as error "Variable `q'_1 not found. Skipping expansion for `q'."
         exit 0
    }
    
    di as txt "Expanding four-source variable `q' to occupation-specific variables..."
    
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
    
    di as txt "  Created `q'_occ2 through `q'_occ7"
end

capture program drop expand_occ_vars_twosrc
program define expand_occ_vars_twosrc, rclass
    syntax , Qvar(string) Name(string)
    local q = "`qvar'"
    capture confirm variable `q'_1
    if _rc {
         di as error "Variable `q'_1 not found. Skipping expansion for `q'."
         exit 0
    }
    
    di as txt "Expanding two-source variable `q' to occupation-specific variables..."
    
    forval j = 2/7 {
         gen `q'_occ`j' = .
    }
    lab var `q'_occ2 "`name' FaGe"
    lab var `q'_occ3 "`name' FaBe"
    lab var `q'_occ4 "`name' MPA"
    lab var `q'_occ5 "`name' Informatiker/-in"
    lab var `q'_occ6 "`name' Konstrukteur/-in"
    lab var `q'_occ7 "`name' Polymechaniker/-in"
    
    // Check if traditional_role_* variables exist for mapping
    local role_vars_exist = 1
    forval i = 1/2 {
        capture confirm variable traditional_role_`i'
        if _rc {
            local role_vars_exist = 0
        }
    }
    
    if `role_vars_exist' {
        di as txt "  Mapping from traditional_role variables..."
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
        di as txt "  WARNING: traditional_role_* variables not found. Cannot map occupation-specific values."
        di as txt "  Will create empty occupation variables."
    }
    
    drop `q'_1 `q'_2
    
    di as txt "  Created `q'_occ2 through `q'_occ7"
end

capture program drop expand_occ_vars_threesrc
program define expand_occ_vars_threesrc, rclass
    syntax , Qvar(string) Name(string)
    local q = "`qvar'"
    capture confirm variable `q'_1
    if _rc {
         di as error "Variable `q'_1 not found. Skipping expansion for `q'."
         exit 0
    }
    
    di as txt "Expanding three-source variable `q' to occupation-specific variables..."
    
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
    
    // Check if occ_friend* variables exist for mapping
    local friend_vars_exist = 1
    forval i = 1/3 {
        capture confirm variable occ_friend`i'
        if _rc {
            local friend_vars_exist = 0
        }
    }
    
    if `friend_vars_exist' {
        di as txt "  Mapping from occ_friend variables..."
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
        di as txt "  WARNING: occ_friend* variables not found. Cannot map occupation-specific values."
        di as txt "  Will create empty occupation variables."
    }
    
    drop `q'_1 `q'_2 `q'_3
    
    di as txt "  Created `q'_occ2 through `q'_occ10"
end

********************************************************************************
* 4. EXPAND BELIEF QUESTIONS INTO OCC–SPECIFIC VARIABLES
********************************************************************************
di as txt "----- Expanding belief questions into occupation-specific variables -----"

// Define local variable names for labels
local name_belief_fit "Belief fit"
local name_like_task "Belief like tasks"
local name_colleague_fit "Colleague fit"
local name_belief_demand "Belief demand"
local name_marriage_prob "Belief marriage probability"
local name_future_fit "Belief future happiness"
local name_par_approval_fit "Parent approval"

// For items that might have either 2 or 4 sources, check if a third source exists.
// (For example, if belief_fit_3 is missing, use the two–source expansion.)
foreach q_var in belief_fit like_task colleague_fit belief_demand {
    capture confirm variable `q_var'_3
    if !_rc {
        di as txt "Variable `q_var'_3 found; using four-source expansion for `q_var'."
        expand_occ_vars_foursrc, qvar("`q_var'") name("`name_`q_var''")
    }
    else {
        capture confirm variable `q_var'_1
        if !_rc {
            di as txt "Variable `q_var'_1 found, but `q_var'_3 not found; using two-source expansion."
            expand_occ_vars_twosrc, qvar("`q_var'") name("`name_`q_var''")
        }
        else {
            di as txt "Variable `q_var'_1 not found; skipping expansion."
        }
    }
}

// Process two–source items (e.g., marriage_prob, future_fit, approval_fit)
foreach q_var in marriage_prob future_fit par_approval_fit {
    capture confirm variable `q_var'_1
    if !_rc {
        di as txt "Processing `q_var' with two-source expansion."
        expand_occ_vars_twosrc, qvar("`q_var'") name("`name_`q_var''")
    }
    else {
        di as txt "Variable `q_var'_1 not found; skipping expansion."
    }
}

// Process friend–related belief items (expected to have 3 source variables)
// Only call the expansion program if the source variable exists.
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit ///
                 friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    capture confirm variable `q_var'_1
    if !_rc {
        di as txt "Processing friend-related variable `q_var' with three-source expansion."
        expand_occ_vars_threesrc, qvar("`q_var'") name("`q_var'")
    }
    else {
        di as txt "Friend-related variable `q_var'_1 not found; skipping expansion."
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

foreach q_var in belief_fit like_task future_fit colleague_fit {
    di as txt "Applying labels to `q_var' occupation-specific variables..."
    forval i = 2/7 {
        capture confirm variable `q_var'_occ`i'
        if !_rc {
            label values `q_var'_occ`i' belief_q_labels
        }
    }
}

// Label definition for "demand/marriage_prob" responses:
capture label define demand_labels ///
    1 "Very unlikely" ///
    2 "Unlikely" ///
    3 "Moderately" ///
    4 "Likely" ///
    5 "Very likely", replace

foreach q_var in marriage_prob belief_demand {
    di as txt "Applying labels to `q_var' occupation-specific variables..."
    forval i = 2/7 {
        capture confirm variable `q_var'_occ`i'
        if !_rc {
            label values `q_var'_occ`i' demand_labels
        }
    }
}

// Label definitions for approval variables:
capture label define approval_labels ///
    1 "Very sceptical" ///
    2 "Sceptical" ///
    3 "Moderate" ///
    4 "Supportive" ///
    5 "Very supportive", replace

foreach q_var in par_approval_fit {
    di as txt "Applying labels to `q_var' occupation-specific variables..."
    forval i = 2/7 {
        capture confirm variable `q_var'_occ`i'
        if !_rc {
            label values `q_var'_occ`i' approval_labels
        }
    }
}

// For friend–related items, first check that the expansion created the expected variables.
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit ///
                 friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    capture confirm variable `q_var'_occ2
    if !_rc {
        di as txt "Applying labels to friend-related `q_var' occupation-specific variables..."
        forval i = 2/10 {
            capture confirm variable `q_var'_occ`i'
            if !_rc {
                label values `q_var'_occ`i' belief_q_labels
            }
        }
    }
}

********************************************************************************
* 6. CREATE STANDARDIZED AVERAGE VARIABLES
********************************************************************************
di as txt "----- Creating standardized average variables -----"

/* For each belief dimension, compute row–means separately for the
   "female–coded" occupations (columns 2–4) and "male–coded" occupations 
   (columns 5–7). Multiply the row–mean by 2 to rescale to the original 
   Likert scale.
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
    // Standardize items with occupation-specific values:
    foreach q_var in belief_fit like_task colleague_fit belief_demand marriage_prob future_fit par_approval_fit {
        di as txt "Creating standardized averages for `q_var'..."
        
        // Check if all required occupation-specific variables exist
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
            di as txt "  Not all required occupation-specific variables for `q_var' found; skipping standardized averages."
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
save "${processed_data}/PS_Parents/4_ps_parents.dta", replace

// Final report
di as txt "Cleaned beliefs dataset saved to: ${processed_data}/PS_Parents/4_ps_parents.dta"
di as txt "Observations: `=_N'"
di as txt "Variables: `=c(k)'"
di as txt "======================================================="
di as txt "COMPLETED: PS Parents Clean Beliefs"
di as txt "======================================================="

timer off 1
timer list
log close
set trace off