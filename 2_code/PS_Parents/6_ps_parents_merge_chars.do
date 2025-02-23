********************************************************************************
// 5_ps_parents_merge_chars.do
// Purpose: Merges the parents data with your skill_intensity_data
//          or other “characteristics” datasets
********************************************************************************

clear all
set more off
cap log close
log using "${dodir_log}/ps_parents_merge_chars.log", replace

* 1. Load data from step 4
use "${processed_data}/PS_Students/temp_parents_step4_other.dta", clear

* 2. Merge with e.g. skill_intensity_data_with_apprentice_characteristics.dta
merge m:1 labb_code using "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics.dta", nogen

* 3. Possibly rename skill/female_share variables
rename female_grad female_share
rename skills_ave_math math_requirement

* 4. Save
save "${processed_data}/PS_Students/temp_parents_step5_chars.dta", replace

log close
