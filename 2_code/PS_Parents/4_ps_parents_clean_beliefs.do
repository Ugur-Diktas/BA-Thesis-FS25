********************************************************************************
* 4_ps_parents_clean_beliefs.do
*
* Purpose:
* - Load the cleaned PS Parents data (ps_par_cleaned.dta).
* - Rename & reshape key belief–related variables (e.g. belief_fit, like_task,
*   colleague_fit, employer_fit → belief_demand, marriage_prob_fit, future_fit, 
*   approval_fit, etc.) into occupation–specific variables.
* - Label the new variables.
* - Create standardised averages for “GC” (gender–consistent) and “GIC”
*   (gender–inconsistent) occupations. (Row–means multiplied by 2 to rescale 
*   to the original Likert scale.)
* - Save the updated dataset.
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

if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/ps_parents_clean_beliefs.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************
di as txt "----- Loading dataset: ps_par_cleaned.dta -----"
quietly use "${processed_data}/PS_Parents/ps_par_cleaned.dta", clear
di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"
if _N == 0 {
    di as error "ERROR: No observations found in ps_par_cleaned.dta."
    error 602
}

********************************************************************************
* 2. RENAME / PREP BELIEF VARIABLES
********************************************************************************

* Rename marriage probability variables:
capture confirm variable marriage_prob_fit_1
if !_rc {
    rename marriage_prob_fit_1 marriage_prob_1
    rename marriage_prob_fit_2 marriage_prob_2
}

* Rename employer_fit variables to belief_demand:
capture confirm variable employer_fit_1
if !_rc {
    rename employer_fit_1 belief_demand_1
    rename employer_fit_2 belief_demand_2
}

* (If necessary, adjust belief_fit, like_task and colleague_fit variable names)
* If double underscores exist, convert them to a single underscore:
foreach belief_q_var in belief_fit like_task colleague_fit {
    forval i = 1/2 {
         capture confirm variable `belief_q_var'__`i'
         if !_rc {
             rename `belief_q_var'__`i' `belief_q_var'_`i'
         }
    }
}

* Process approval variables.
// Process parent's approval responses from op_approval_fit variables.
// New variables will be created with the prefix "par_approval_fit_"
// NOTE: MIGHT BE FAULTY / NOT THE RIGHT APPROACH - TEMPORARY FIX
forval i = 1/2 {
    capture confirm variable op_approval_fit_`i'
    if !_rc {
         gen par_approval_fit_`i' = op_approval_fit_`i'
    }
}

********************************************************************************
* 3. DEFINE PROGRAMS TO EXPAND OCCUPATION–SPECIFIC VARIABLES
********************************************************************************

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
    drop `q'_1 `q'_2 `q'_3 `q'_4
end

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
* 4. EXPAND BELIEF QUESTIONS INTO OCC–SPECIFIC VARIABLES
********************************************************************************

* For items that may have either two or four sources, check if a third source exists.
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

* Process two–source items:
foreach q_var in marriage_prob future_fit approval_fit {
    expand_occ_vars_twosrc, qvar("`q_var'") name("`q_var'")
}

* (Optional) Process friend–related items if they exist.
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
* 5. LABEL DEFINITIONS FOR THE NEW OCC VARIABLES
********************************************************************************

* Label definition for “fit” and “like_task”–type responses:
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

* Label definition for “marriage_prob” responses:
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

* Label definitions for approval responses:
label define approval_labels ///
    1 "Very sceptical" ///
    2 "Sceptical" ///
    3 "Moderate" ///
    4 "Supportive" ///
    5 "Very supportive", replace

foreach q_var in approval_fit {
    forval i = 2/7 {
         label values `q_var'_occ`i' approval_labels
    }
}

* For friend–related items:
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    capture confirm variable `q_var'_occ2
    if _rc {
         di as error "Variable `q_var'_occ2 not found. Skipping labelling for `q_var'."
    }
    else {
         forval i = 2/10 {
              label values `q_var'_occ`i' belief_q_labels
         }
    }
}

********************************************************************************
* 6. CREATE STANDARDISED AVERAGE VARIABLES
********************************************************************************
/* For each belief dimension, compute row–means separately for the
   “female–coded” occupations (columns 2–4) and “male–coded” occupations (columns 5–7).
   Multiply the row–mean by 2 to rescale to the original Likert scale.
*/
label define belief_qs_ave_lab ///
    2 "Not at all" 3 "Not at all/little" 4 "Little" 5 "Little/moderately" 6 "Moderately" ///
    7 "Moderately/well" 8 "Well" 9 "Well/very well" 10 "Very well", replace

foreach q_var in belief_fit like_task marriage_prob future_fit approval_fit {
    egen `q_var'_fem_ave = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
    egen `q_var'_mal_ave = rowmean(`q_var'_occ5 `q_var'_occ6 `q_var'_occ7)
    gen `q_var'_gc_ave = .
    gen `q_var'_gic_ave = .
    replace `q_var'_gc_ave = 2*`q_var'_fem_ave if female == 1
    replace `q_var'_gc_ave = 2*`q_var'_mal_ave if female == 0
    replace `q_var'_gic_ave = 2*`q_var'_fem_ave if female == 0
    replace `q_var'_gic_ave = 2*`q_var'_mal_ave if female == 1
    drop `q_var'_fem_ave `q_var'_mal_ave
    label var `q_var'_gc_ave "Average `q_var': GC occupations"
    label var `q_var'_gic_ave "Average `q_var': GIC occupations"
    label values `q_var'_gc_ave belief_qs_ave_lab
    label values `q_var'_gic_ave belief_qs_ave_lab
}

* (Optional) Standardise friend–related belief items if present:
foreach q_var in friend_belief_fit friend_like_task friend_colleague_fit friend_belief_demand friend_par_support friend_masc_self friend_masc_others {
    capture confirm variable `q_var'_occ2
    if _rc {
         di as error "Variable `q_var'_occ2 not found. Skipping standardised averages for `q_var'."
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
* 7. FINAL HOUSEKEEPING & SAVE
********************************************************************************
di as txt "----- Compressing and saving dataset -----"
compress
save "${processed_data}/PS_Parents/ps_par_clean_beliefs.dta", replace

timer off 1
timer list
log close
