********************************************************************************
* 4_ps_parents_clean_beliefs.do
*
* Purpose:
* - Load the cleaned PS Parents data (ps_par_cleaned.dta).
* - Rename & reshape key belief-related variables (fit, like_task, approvals, etc.).
* - Create standardised average variables if needed (GC vs. GIC).
* - Save the updated dataset.
*
* Author  : [Your Name / Team]
* Version : Stata 18
* Date    : [YYYY-MM-DD]
********************************************************************************

clear all
set more off
version 18.0

if "${debug}" == "yes" {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/4_ps_parents_clean_beliefs.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************

use "${processed_data}/PS_Parents/ps_par_cleaned.dta", clear
di as txt "Loaded ps_par_cleaned.dta: `c(N)' obs"

if _N == 0 {
    di as error "ERROR: No observations in ps_par_cleaned.dta."
    error 602
}

********************************************************************************
* 2. RENAME BELIEF VARIABLES
********************************************************************************

* Example: rename employer_fit_1 -> belief_demand_1, etc.
capture confirm variable employer_fit_1
if !_rc {
    rename employer_fit_1 belief_demand_1
    rename employer_fit_2 belief_demand_2
}

capture confirm variable marriage_prob_fit_1
if !_rc {
    rename marriage_prob_fit_1 marriage_prob_1
    rename marriage_prob_fit_2 marriage_prob_2
}

* Similarly for mother/father approvals if needed
capture confirm variable mother_approval_1__1
if !_rc {
    * rename mother_approval_1__1 mother_approval_1
    * etc.
}

********************************************************************************
* 3. (OPTIONAL) CREATE GC & GIC AVERAGES
********************************************************************************

* If you have "male_traditional_roles", "female_traditional_roles" or
* "traditional_role_1", "traditional_role_2", you can replicate the approach
* from the students code. E.g.:
*   - For each belief variable, generate separate columns for FaGe, FaBe, MPA,
*     Informatiker/in, Konstrukteur/in, Polymechaniker/in
*   - Then compute rowmeans for "female-coded" vs. "male-coded" occupations
*   - Multiply by 2 to keep the original 1–5 scale

* For example:
label define belief_qs_ave_lab 2 "Not at all" 3 "Not at all/little" 4 "Little" 5 "Little/moderately" ///
                              6 "Moderately" 7 "Moderately/well" 8 "Well" 9 "Well/very well" 10 "Very well", replace

* Suppose we have father_belief_fit_1, father_belief_fit_2 for male-coded occs
* (the actual code depends on your variable naming and your data).

********************************************************************************
* 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************

compress
save "${processed_data}/PS_Parents/ps_par_clean_beliefs.dta", replace

timer off 1
timer list
log close
