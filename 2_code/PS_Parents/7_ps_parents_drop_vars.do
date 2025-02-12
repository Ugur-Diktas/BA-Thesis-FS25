********************************************************************************
// 7_ps_parents_drop_vars.do
// Purpose: The final pass – drop unneeded variables & produce a neat final data set
********************************************************************************

clear all
set more off
cap log close
log using "${dodir_log}/ps_parents_drop_vars.log", replace

* 1. Load last-step file
use "${processed_data}/PS_Students/temp_parents_step6_parentoccs.dta", clear

* 2. Drop unneeded variables
drop test date debug_*

* 3. Rename or label final variables
rename female student_female
label var student_female "Gender of student"

* 4. Save final
order responseid student_female contract ...
compress
save "${processed_data}/PS_Students/ps_parents_final.dta", replace

log close
