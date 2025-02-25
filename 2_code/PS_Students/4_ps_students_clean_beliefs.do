********************************************************************************
* 4_ps_students_clean_beliefs.do
*
* Purpose:
*   - Load the cleaned PS Students dataset (ps_stu_cleaned.dta).
*   - Rename and reshape the belief–related variables (e.g. marriage_prob, 
*     belief_fit, mother/father approvals, etc.) into occupation–specific 
*     variables.
*   - Label the new variables.
*   - Create standardized averages for “GC” (gender–consistent) and “GIC”
*     (gender–inconsistent) occupations. (Note: the row–means are multiplied 
*     by 2 to rescale them back to the original Likert scale.)
*   - Save the updated dataset.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 25.02.2025
* Version: Stata 18
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
log using "${dodir_log}/students_clean_beliefs.log", replace text

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

// Rename marriage probability variables:
rename marriage_prob_fit_1 marriage_prob_1
rename marriage_prob_fit_2 marriage_prob_2

// Rename the belief-fit & like-task variables from Qualtrics 
// to a simpler pattern (e.g., belief_fit__1 becomes belief_fit_1).
foreach belief_q_var in belief_fit like_task {
    forval i = 1/2 {
        rename `belief_q_var'__`i' `belief_q_var'_`i'
    }
}

// Process mother/father approval variables:
// (If the "new" variables are missing, fill them from the originals.)
forval i = 1/2 {
    replace mother_approval_1new_`i' = mother_approval_1__`i' if missing(mother_approval_1new_`i')
    replace mother_approval_2new_`i' = mother_approval_2_`i'     if missing(mother_approval_2new_`i')
    gen mother_approval_`i' = mother_approval_1new_`i' if !missing(mother_approval_1new_`i')
    replace mother_approval_`i' = mother_approval_2new_`i' if !missing(mother_approval_2new_`i')
    
    replace father_approval_new_`i' = father_approval__`i' if missing(father_approval_new_`i')
    gen father_approval_`i' = father_approval_new_`i'
}
drop mother_approval_1new* mother_approval_2new* mother_approval_1__* mother_approval_2_* ///
     father_approval__* father_approval_new*

********************************************************************************
* PROGRAMS: EXPAND OCCUPATION–SPECIFIC VARIABLES
********************************************************************************

*--- For items with four source variables (expected: _1, _2, _3, _4)
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
    lab var `q'_occ2 "`name_`q'' FaGe"
    lab var `q'_occ3 "`name_`q'' FaBe"
    lab var `q'_occ4 "`name_`q'' MPA"
    lab var `q'_occ5 "`name_`q'' Informatiker/-in"
    lab var `q'_occ6 "`name_`q'' Konstrukteur/-in"
    lab var `q'_occ7 "`name_`q'' Polymechaniker/-in"
    // Drop the original source variables _1 through _4.
    drop `q'_1 `q'_2 `q'_3 `q'_4
end

*--- For items with two source variables (expected: _1 and _2)
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
    lab var `q'_occ2 "`name_`q'' FaGe"
    lab var `q'_occ3 "`name_`q'' FaBe"
    lab var `q'_occ4 "`name_`q'' MPA"
    lab var `q'_occ5 "`name_`q'' Informatiker/-in"
    lab var `q'_occ6 "`name_`q'' Konstrukteur/-in"
    lab var `q'_occ7 "`name_`q'' Polymechaniker/-in"
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
    drop `q'_1 `q'_2
end

*--- For friend–related items with three source variables (expected: _1, _2, _3)
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
    lab var `q'_occ2 "`name_`q'' FaGe"
    lab var `q'_occ3 "`name_`q'' FaBe"
    lab var `q'_occ4 "`name_`q'' MPA"
    lab var `q'_occ5 "`name_`q'' Informatiker"
    lab var `q'_occ7 "`name_`q'' Polymechaniker"
    lab var `q'_occ8 "`name_`q'' Elektroinstallateur"
    lab var `q'_occ9 "`name_`q'' Kaufmann"
    lab var `q'_occ10 "`name_`q'' Detailhandelsfachmann"
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
    drop `q'_1 `q'_2 `q'_3
end

********************************************************************************
* 3. EXPAND BELIEF QUESTIONS INTO OCC–SPECIFIC VARIABLES
********************************************************************************
*--- Student's beliefs
loc name_belief_fit "Belief fit"
loc name_like_task "Belief like tasks"
loc name_marriage_prob "Belief marriage probability"
loc name_future_fit "Belief future happiness"

// For items that might have either 2 or 4 sources, check if a third source exists.
// (For example, if belief_fit_3 is missing, use the two–source expansion.)
foreach q_var in belief_fit like_task colleague_fit belief_demand {
    capture confirm variable `q_var'_3
    if _rc {
         di as txt "Variable `q_var'_3 not found; using two–source expansion for `q_var'."
         expand_occ_vars_twosrc, qvar("`q_var'") name("`q_var'")
    }
    else {
         expand_occ_vars_foursrc, qvar("`q_var'") name("`q_var'")
    }
}

// Process two–source items (e.g., marriage_prob, future_fit, mother_approval, father_approval)
foreach q_var in marriage_prob future_fit mother_approval father_approval {
    expand_occ_vars_twosrc, qvar("`q_var'") name("`q_var'")
}

// Process friend–related belief items (expected to have 3 source variables)
// Only call the expansion program if the source variable exists.
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    capture confirm variable `q_var'_1
    if _rc {
         di as error "Variable `q_var'_1 not found. Skipping expansion for `q_var'."
    }
    else {
         expand_occ_vars_threesrc, qvar("`q_var'") name("`q_var'")
    }
}

********************************************************************************
* 4. LABEL DEFINITIONS FOR THE NEW OCC VARIABLES
********************************************************************************

// Label definition for “fit” or “like_task”–type responses:
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

// Label definition for “marriage_prob” responses:
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

// Label definitions for parent approval variables:
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

*--- For friend–related items, first check that the expansion created the expected variables.
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    capture confirm variable `q_var'_occ2
    if _rc {
         di as error "Variable `q_var'_occ2 not found. Skipping standardized averages for `q_var'."
    }
    else {
         forval i = 2/10 {
              label values `q_var'_occ`i' belief_q_labels
         }
    }
}

********************************************************************************
* 5. CREATE STANDARDIZED VARIABLES
********************************************************************************
/* For each belief dimension, we compute row–means separately for the 
   “female–coded” occupations (columns 2–4) and “male–coded” occupations 
   (columns 5–7). We then multiply the row–mean by 2.
   This multiplication by 2 is performed so that the computed averages (which 
   were based on the reduced (averaged) scale) are rescaled to match the original 
   Likert–scale (e.g., 1–5) used in the survey.
*/
label define belief_qs_ave_lab ///
    2 "Not at all" 3 "Not at all/little" 4 "Little" 5 "Little/moderately" 6 "Moderately" ///
    7 "Moderately/well" 8 "Well" 9 "Well/very well" 10 "Very well", replace

// Standardize items with two sources:
foreach q_var in belief_fit like_task marriage_prob future_fit mother_approval father_approval {
    egen `q_var'_fem_ave = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
    egen `q_var'_mal_ave = rowmean(`q_var'_occ5 `q_var'_occ6 `q_var'_occ7)
    gen `q_var'_gc_ave = .
    gen `q_var'_gic_ave = .
    // For female respondents (female==1): use the female–coded average for GC; for males, use the male–coded.
    replace `q_var'_gc_ave = 2*`q_var'_fem_ave if female == 1
    replace `q_var'_gc_ave = 2*`q_var'_mal_ave if female == 0
    // For gender–inconsistent averages (GIC), use the opposite.
    replace `q_var'_gic_ave = 2*`q_var'_fem_ave if female == 0
    replace `q_var'_gic_ave = 2*`q_var'_mal_ave if female == 1
    drop `q_var'_fem_ave `q_var'_mal_ave
    label var `q_var'_gc_ave "Average `q_var': GC occupations"
    label var `q_var'_gic_ave "Average `q_var': GIC occupations"
    label values `q_var'_gc_ave belief_qs_ave_lab
    label values `q_var'_gic_ave belief_qs_ave_lab
}

// Standardize parent approval items:
foreach q_var in mother_approval father_approval {
    egen `q_var'_fem_ave = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
    egen `q_var'_mal_ave = rowmean(`q_var'_occ5 `q_var'_occ6 `q_var'_occ7)
    gen `q_var'_gc = .
    gen `q_var'_gic = .
    replace `q_var'_gc = `q_var'_fem_ave if female == 1
    replace `q_var'_gc = `q_var'_mal_ave if female == 0
    replace `q_var'_gic = `q_var'_fem_ave if female == 0
    replace `q_var'_gic = `q_var'_mal_ave if female == 1
    drop `q_var'_fem_ave `q_var'_mal_ave
    label var `q_var'_gc "Average `q_var': for GC occ"
    label var `q_var'_gic "Average `q_var': for GIC occ"
    label values `q_var'_gc approval_labels
    label values `q_var'_gic approval_labels
}

// Standardize friend–related belief items.
// Only process friend items if the expected expansion variables exist.
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    capture confirm variable `q_var'_occ2
    if _rc {
         di as error "Variable `q_var'_occ2 not found. Skipping standardized averages for `q_var'."
    }
    else {
         egen `q_var'_gic = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
         egen `q_var'_gc = rowmean(`q_var'_occ5 `q_var'_occ7 `q_var'_occ8)
         egen `q_var'_gn = rowmean(`q_var'_occ9 `q_var'_occ10)
         replace `q_var'_gc = 2*`q_var'_gc
         replace `q_var'_gic = 2*`q_var'_gic
         replace `q_var'_gn = 2*`q_var'_gn
         label var `q_var'_gc "`name_`q_var'' to GC occs"
         label var `q_var'_gic "`name_`q_var'' to GIC occs"
         label var `q_var'_gn "`name_`q_var'' to GN occs"
         label values `q_var'_gc belief_qs_ave_lab
         label values `q_var'_gic belief_qs_ave_lab
         label values `q_var'_gn belief_qs_ave_lab
    }
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
