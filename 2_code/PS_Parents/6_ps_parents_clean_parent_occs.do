********************************************************************************
// 6_ps_parents_clean_parent_occs.do
// Purpose: Cleans parent occupations reported by parents (if any).
********************************************************************************

clear all
set more off
cap log close
log using "${dodir_log}/ps_parents_clean_parent_occs.log", replace

* 1. Load data
use "${processed_data}/PS_Students/temp_parents_step5_chars.dta", clear

* 2. Attempt to assign parent’s occupation code
** YOUR CODE HERE **
/*
  e.g. using strlower() or your matching to isced. Then do the manual pass 
  with an external excel list, similarly to how you do for 4_5. 
*/

* 3. Save
save "${processed_data}/PS_Students/temp_parents_step6_parentoccs.dta", replace

log close
