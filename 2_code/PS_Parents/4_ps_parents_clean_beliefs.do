********************************************************************************
* 4_ps_parents_clean_beliefs.do
*
* Purpose:
*   - Load the cleaned PS Parents dataset (ps_par_cleaned.dta).
*   - Rename and reshape the belief–related variables (e.g. employer fit etc., 
*     belief_fit, mother/father approvals, etc.) into occupation–specific 
*     variables.
*   - Label the new variables.
*   - Create standardized averages for "GC" (gender–consistent) and "GIC"
*     (gender–inconsistent) occupations. (Note: the row–means are multiplied 
*     by 2 to rescale them back to the original Likert scale.)
*   - Save the updated dataset.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 26.02.2025
* Version: Stata 18
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 18.0

cap log close
log using "${dodir_log}/parents_clean_beliefs.log", replace text

// Turn on Stata's trace for very detailed debugging (comment out if too verbose).
// set trace on

timer clear
timer on 1

********************************************************************************
// 1. LOAD THE CLEANED DATA
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

// Approval
rename employer_fit_1 belief_demand_1
rename employer_fit_2 belief_demand_2
rename marriage_prob_fit_1 marriage_prob_1
rename marriage_prob_fit_2 marriage_prob_2

foreach belief_q_var in "belief_fit" "like_task" "colleague_fit" "belief_demand" "marriage_prob" "future_fit" {
	forval i = 1/2 {
		rename `belief_q_var'_`i' this_`belief_q_var'_`i'
		gen mother_`belief_q_var'_`i' = this_`belief_q_var'_`i' if Parent_type_ == 1
		gen father_`belief_q_var'_`i' = this_`belief_q_var'_`i' if Parent_type_ == 2
	}
}

forval i = 1/2 {
	replace approval_fit_new_`i' = approval_fit_`i' if missing(approval_fit_new_`i')
	rename approval_fit_new_`i' this_approval_`i'
	
	replace op_approval_fit_new_`i' = op_approval_fit_`i' if missing(op_approval_fit_new_`i')
	rename op_approval_fit_new_`i' other_approval_`i'
	
	gen mother_approval_`i' = .
	replace mother_approval_`i' = this_approval_`i' if Parent_type_ == 1
	replace mother_approval_`i' = other_approval_`i' if Parent_type_ == 2
	gen father_approval_`i' = .
	replace father_approval_`i' = this_approval_`i' if Parent_type_ == 2
	replace father_approval_`i' = other_approval_`i' if Parent_type_ == 1
}

drop approval* op_approval* this_* other_*

********************************************************************************
* 3.PROGRAMS: EXPAND OCCUPATION–SPECIFIC VARIABLES
********************************************************************************

*Parents' beliefs
loc name_mother_belief_fit "Mother's belief fit"
loc name_mother_like_task "Mother's belief like tasks"
loc name_mother_colleague_fit "Mother's belief colleague fit"
loc name_mother_belief_demand "Mother's belief employer demand"
loc name_mother_marriage_prob "Mother's belief marriage probability"
loc name_mother_future_fit "Mother's belief future happiness"
loc name_father_belief_fit "Father's belief fit"
loc name_father_like_task "Father's belief like tasks"
loc name_father_colleague_fit "Father's belief colleague fit"
loc name_father_belief_demand "Father's belief employer demand"
loc name_father_marriage_prob "Father's belief marriage probability"
loc name_father_future_fit "Father's belief future happiness"
loc name_mother_approval "Mother's approval"
loc name_father_approval "Father's approval"
gen traditional_role_3 = ""
gen traditional_role_4 = ""

*Now for vars with only 2 separate vars in dataset
foreach q_var in "mother_belief_fit" "mother_like_task" "mother_colleague_fit" "mother_belief_demand" "mother_marriage_prob" "mother_future_fit" "father_belief_fit" "father_like_task" "father_colleague_fit" "father_belief_demand" "father_marriage_prob" "father_future_fit" "mother_approval" "father_approval" {
 
	*Belief about fit to same gender occupation/opp gender occupation
 
	forval j = 2/7 {
 
		gen `q_var'_occ`j' = .
 
	}
 
	lab var `q_var'_occ2 "`name_`q_var'' FaGe"
	lab var `q_var'_occ3 "`name_`q_var'' FaBe"
	lab var `q_var'_occ4 "`name_`q_var'' MPA"
	lab var `q_var'_occ5 "`name_`q_var'' Informatiker/-in"
	lab var `q_var'_occ6 "`name_`q_var'' Konstrukteur/-in"
	lab var `q_var'_occ7 "`name_`q_var'' Polymechaniker/-in" 	
 
	forvalues i = 1/2 {
 
		replace `q_var'_occ2 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Gesundheit (FaGe)" | traditional_role_`i' == "Fachmann Gesundheit (FaGe)"
 
		replace `q_var'_occ3 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Betreuung (FaBe)" | traditional_role_`i' == "Fachmann Betreuung (FaBe)"
 
		replace `q_var'_occ4 = `q_var'_`i' if traditional_role_`i' == "Medizinischer Praxisassistent (MPA)" | traditional_role_`i' == "Medizinische Praxisassistentin (MPA)"
 
		replace `q_var'_occ5 = `q_var'_`i' if traditional_role_`i' == "Informatiker" | traditional_role_`i' == "Informatikerin"
 
		replace `q_var'_occ6 = `q_var'_`i' if traditional_role_`i' == "Konstrukteur" | traditional_role_`i' == "Konstrukteurin"
 
		replace `q_var'_occ7 = `q_var'_`i' if traditional_role_`i' == "Polymechaniker" | traditional_role_`i' == "Polymechanikerin"
 
	}
 
}
********************************************************************************
* 5.PROGRAMS: EXPAND OCCUPATION–SPECIFIC VARIABLES
********************************************************************************
**NOT SURE WHAT YOU DID HERE IN THE OTHER CODE, MAYBE YOU SHOULD LOOK AT THIS AS 
**I DONT KNOW WHY YOU DO SOEMTHING HERE IN YOUR CODE
********************************************************************************
* 6.DEFINE LABELS
********************************************************************************
lab define belief_q_labels 1 "Not at all" 2 "Little" 3 "Moderately" 4 "Well" 5 "Very well"

foreach q_var in  "mother_belief_fit" "mother_like_task" "mother_colleague_fit" "mother_future_fit" "father_belief_fit" "father_like_task" "father_colleague_fit" "father_future_fit" {
	forval i = 1/2{
		lab values `q_var'_`i' belief_q_labels
	}
}


label define demand_labels 1 "Very unlikely" 2 "Unlikely" 3 "Moderately" 4 "Likely" 5 "Very likely"
foreach q_var in  "mother_belief_demand" "mother_marriage_prob" "father_belief_demand" "father_marriage_prob" {
	forvalues i = 1/2 {
		label values `q_var'_`i' demand_labels
	}
}

lab define approval_labels 1 "Very sceptical" 2 "Sceptical" 3 "Moderate" 4 "Supportive" 5 "Very supportive"

foreach q_var in "mother_approval" "father_approval" {
	forval i = 1/2 {
		label values `q_var'_`i' approval_labels
	}
}
********************************************************************************
* 5. CREATE STANDARDIZED VARIABLES
********************************************************************************
/* For each belief dimension, we compute row–means separately for the 
   "female–coded" occupations (columns 2–4) and "male–coded" occupations 
   (columns 5–7). We then multiply the row–mean by 2.
   This multiplication by 2 is performed so that the computed averages (which 
   were based on the reduced (averaged) scale) are rescaled to match the original 
   Likert–scale (e.g., 1–5) used in the survey.
*/

/*
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
*/
********************************************************************************
* 6. FINAL HOUSEKEEPING & SAVE
********************************************************************************
di as txt "----- Compressing and saving dataset -----"
compress
save "${processed_data}/PS_Parents/ps_par_cleaned.dta", replace

timer off 1
timer list
log close

