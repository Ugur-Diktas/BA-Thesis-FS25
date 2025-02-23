********************************************************************************
* 3_ps_students_clean_beliefs.do
* 
* Purpose : 
*   - Load the cleaned PS Students dataset (ps_stu_cleaned).
*   - Rename and reshape the belief-related variables (marriage_prob, belief_fit,
*     mother/father approvals, etc.) into occupation-specific variables.
*   - Label them, create standardized versions for “GC” (gender-consistent)
*     and “GIC” (gender-inconsistent) occupations (similar to code in 4_2).
*   - Save the updated dataset.
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

// Conditionally enable or disable trace using global debug
if "${debug}" == "yes" {
    set trace on
} 
else {
    set trace off
}

// Start logging
cap log close
log using "${dodir_log}/ps_students_clean_beliefs.log", replace text

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
* 2. RENAME / PREP BELIEF VARIABLES
********************************************************************************

// Example: rename marriage probability variables
rename marriage_prob_fit_1 marriage_prob_1
rename marriage_prob_fit_2 marriage_prob_2

// Example: rename the belief-fit & like-task variables from Qualtrics
// to a simpler pattern (similar to 4_2 approach)
foreach belief_q_var in belief_fit like_task {
    forval i = 1/2 {
        // e.g. rename belief_fit__1 -> belief_fit_1
        // if you have "belief_q_var'__`i'", confirm actual naming
        rename `belief_q_var'__`i' `belief_q_var'_`i'
    }
}

// Example: rename mother/father approval sets
// (TODO: adjust to actual existing variables)
forval i = 1/2 {
    // Use missing() check to fill mother_approval_1new_i from mother_approval_1__i, etc.
    replace mother_approval_1new_`i' = mother_approval_1__`i' if missing(mother_approval_1new_`i')
    replace mother_approval_2new_`i' = mother_approval_2_`i'     if missing(mother_approval_2new_`i')
    gen mother_approval_`i' = mother_approval_1new_`i' if !missing(mother_approval_1new_`i')
    replace mother_approval_`i' = mother_approval_2new_`i' if !missing(mother_approval_2new_`i')
    
    replace father_approval_new_`i' = father_approval__`i' if missing(father_approval_new_`i')
    gen father_approval_`i' = father_approval_new_`i'
}

// Drop leftover placeholders
drop mother_approval_1new* mother_approval_2new* mother_approval_1__* mother_approval_2_* ///
     father_approval__* father_approval_new*

********************************************************************************
* 3. EXPAND BELIEF QUESTIONS INTO OCC-SPECIFIC VARIABLES
********************************************************************************

// (A) Belief Fit, Like Task, etc. that each have 2 separate variables
foreach q_var in belief_fit like_task {
    
    // Create placeholders for the occupation-coded versions
    forval j = 2/7 {
        gen `q_var'_occ`j' = .
    }

    // Label them (FaGe, FaBe, MPA, Informatiker, Konstrukteur, Polymechaniker, etc.)
    label var `q_var'_occ2' "Belief: `q_var' for FaGe"
    label var `q_var'_occ3' "Belief: `q_var' for FaBe"
    label var `q_var'_occ4' "Belief: `q_var' for MPA"
    label var `q_var'_occ5' "Belief: `q_var' for Informatiker/-in"
    label var `q_var'_occ6' "Belief: `q_var' for Konstrukteur/-in"
    label var `q_var'_occ7' "Belief: `q_var' for Polymechaniker/-in"
    
    // For each of the 2 separate question-variables we have
    // e.g. belief_fit_1, belief_fit_2, we fill in the relevant occ
    forval i = 1/2 {
        replace `q_var'_occ2 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Gesundheit (FaGe)" | ///
                                               traditional_role_`i' == "Fachmann Gesundheit (FaGe)"
        replace `q_var'_occ3 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Betreuung (FaBe)" | ///
                                               traditional_role_`i' == "Fachmann Betreuung (FaBe)"
        replace `q_var'_occ4 = `q_var'_`i' if traditional_role_`i' == "Medizinischer Praxisassistent (MPA)" | ///
                                               traditional_role_`i' == "Medizinische Praxisassistentin (MPA)"
        replace `q_var'_occ5 = `q_var'_`i' if traditional_role_`i' == "Informatiker" | ///
                                               traditional_role_`i' == "Informatikerin"
        replace `q_var'_occ6 = `q_var'_`i' if traditional_role_`i' == "Konstrukteur" | ///
                                               traditional_role_`i' == "Konstrukteurin"
        replace `q_var'_occ7 = `q_var'_`i' if traditional_role_`i' == "Polymechaniker" | ///
                                               traditional_role_`i' == "Polymechanikerin"
    }
    
    // Finally drop the original 2 columns for `q_var`
    drop `q_var'_1 `q_var'_2
}

// (B) For marriage_prob, future_fit, mother_approval, father_approval, etc.
// that each have 2 separate variables as well:
foreach q_var in marriage_prob future_fit mother_approval father_approval {
    
    // Occupation-coded placeholders
    forval j = 2/7 {
        gen `q_var'_occ`j' = .
    }
    label var `q_var'_occ2' "`q_var' for FaGe"
    label var `q_var'_occ3' "`q_var' for FaBe"
    label var `q_var'_occ4' "`q_var' for MPA"
    label var `q_var'_occ5' "`q_var' for Informatiker/-in"
    label var `q_var'_occ6' "`q_var' for Konstrukteur/-in"
    label var `q_var'_occ7' "`q_var' for Polymechaniker/-in"

    forval i = 1/2 {
        replace `q_var'_occ2 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Gesundheit (FaGe)" | ///
                                               traditional_role_`i' == "Fachmann Gesundheit (FaGe)"
        replace `q_var'_occ3 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Betreuung (FaBe)" | ///
                                               traditional_role_`i' == "Fachmann Betreuung (FaBe)"
        replace `q_var'_occ4 = `q_var'_`i' if traditional_role_`i' == "Medizinischer Praxisassistent (MPA)" | ///
                                               traditional_role_`i' == "Medizinische Praxisassistentin (MPA)"
        replace `q_var'_occ5 = `q_var'_`i' if traditional_role_`i' == "Informatiker" | ///
                                               traditional_role_`i' == "Informatikerin"
        replace `q_var'_occ6 = `q_var'_`i' if traditional_role_`i' == "Konstrukteur" | ///
                                               traditional_role_`i' == "Konstrukteurin"
        replace `q_var'_occ7 = `q_var'_`i' if traditional_role_`i' == "Polymechaniker" | ///
                                               traditional_role_`i' == "Polymechanikerin"
    }
    
    drop `q_var'_1 `q_var'_2
}

// If you had any “traditional_role_3” or “traditional_role_4” placeholders, drop them
drop traditional_role_3 traditional_role_4

********************************************************************************
* 4. LABEL DEFINITIONS FOR THE NEW OCC VARIABLES
********************************************************************************

// For “fit” or “like_task” type beliefs
label define belief_q_labels ///
    1 "Not at all" ///
    2 "Little" ///
    3 "Moderately" ///
    4 "Well" ///
    5 "Very well", replace

foreach q_var in belief_fit like_task future_fit {
    forval i = 2/7 {
        label values `q_var'_occ`i' belief_q_labels
    }
}

// For “marriage_prob” or “demand-like” variables
label define demand_labels ///
    1 "Very unlikely" ///
    2 "Unlikely" ///
    3 "Moderately" ///
    4 "Likely" ///
    5 "Very likely", replace

foreach q_var in marriage_prob {
    forval i = 2/7 {
        label values `q_var'_occ`i' demand_labels
    }
}

// For mother/father approvals
label define approval_labels ///
    1 "Very sceptical" ///
    2 "Sceptical" ///
    3 "Moderate" ///
    4 "Supportive" ///
    5 "Very supportive", replace

foreach q_var in mother_approval father_approval {
    forval i = 2/7 {
        label values `q_var'_occ`i' approval_labels
    }
}

********************************************************************************
* 5. (OPTIONAL) CREATE STANDARDIZED VARIABLES (TODO: CHECK)
********************************************************************************

label define belief_qs_ave_lab ///
    2 "Not at all" 3 "Not at all/little" 4 "Little" 5 "Little/moderately" 6 "Moderately" ///
    7 "Moderately/well" 8 "Well" 9 "Well/very well" 10 "Very well", replace

// Example for the “belief_fit” variable
//   1) row-mean of female-coded occs => `_fem_ave`
//   2) row-mean of male-coded occs => `_mal_ave`
//   3) Then store them in `_gc_ave` or `_gic_ave` depending on whether
//      the respondent is female (==1) or not.

foreach q_var in belief_fit like_task marriage_prob future_fit mother_approval father_approval {
    
    // (a) row-mean of “female-coded” occ: 2,3,4
    egen `q_var'_fem_ave = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
    
    // (b) row-mean of “male-coded” occ: 5,6,7
    egen `q_var'_mal_ave = rowmean(`q_var'_occ5 `q_var'_occ6 `q_var'_occ7)
    
    // (c) Create two final “averages” for gender-consistent vs. gender-inconsistent
    gen `q_var'_gc_ave = .
    gen `q_var'_gic_ave = .
    
    // If female == 1, “GC” is the female-coded occ, “GIC” is male-coded
    replace `q_var'_gc_ave = 2*`q_var'_fem_ave if female == 1
    replace `q_var'_gc_ave = 2*`q_var'_mal_ave if female == 0
    
    replace `q_var'_gic_ave = 2*`q_var'_fem_ave if female == 0
    replace `q_var'_gic_ave = 2*`q_var'_mal_ave if female == 1
    
    // (d) drop intermediate
    drop `q_var'_fem_ave `q_var'_mal_ave
    
    // (e) label them
    label var `q_var'_gc_ave "Average `q_var': GC occupations"
    label var `q_var'_gic_ave "Average `q_var': GIC occupations"
    
    // (f) attach the label scale
    label values `q_var'_gc_ave belief_qs_ave_lab
    label values `q_var'_gic_ave belief_qs_ave_lab
}

********************************************************************************
* 6. FINAL HOUSEKEEPING & SAVE
********************************************************************************

di as txt "----- Compressing and saving dataset -----"
compress

save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list

log close
