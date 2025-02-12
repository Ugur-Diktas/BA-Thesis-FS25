********************************************************************************
// 4_ps_students_clean_other.do
// Purpose: Cleans "other" textboxes in the students data set.
********************************************************************************

clear all
set more off
cap log close
log using "${dodir_log}/ps_students_clean_other.log", replace

* 1. Load data from previous step
use "${processed_data}/PS_Students/temp_students_step3_beliefs.dta", clear

* 2. Clean “other” text boxes
** YOUR CODE HERE **
/*
  e.g. if occupation=42 => rename or store in a string "other_occ"
  remove linebreaks, trim spaces, etc.
*/

* 3. Save intermediate
save "${processed_data}/PS_Students/temp_students_step4_other.dta", replace

log close
