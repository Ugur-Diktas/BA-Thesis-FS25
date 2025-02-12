********************************************************************************
// 3_ps_students_clean_beliefs.do
// Purpose: Cleans the randomised "belief" or "fit" questions for students
//          (like 3_3_1 or 4_2 references).
********************************************************************************

clear all
set more off
cap log close
log using "${dodir_log}/ps_students_clean_beliefs.log", replace

* 1. Load the step-2 data
use "${processed_data}/PS_Students/temp_students_step2.dta", clear

* 2. Clean or recode randomised blocks
** YOUR CODE HERE **
/*
  e.g. you might rename variables:
    rename mother_belief_fit_1 mother_belief_fit_occ1
    rename mother_belief_fit_2 mother_belief_fit_occ2
  or unify them. Also adjust labels, etc.
*/

* 3. Save
save "${processed_data}/PS_Students/temp_students_step3_beliefs.dta", replace

log close
