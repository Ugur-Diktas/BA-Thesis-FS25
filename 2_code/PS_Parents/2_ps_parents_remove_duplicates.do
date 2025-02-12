********************************************************************************
// 2_ps_parents_remove_duplicates.do
// Purpose: Removes duplicates, excludes bad-quality obs, renames key vars, etc.
********************************************************************************

clear all
set more off
cap log close
log using "${dodir_log}/ps_parents_remove_duplicates.log", replace

* 1. Load anonymised data
use "${processed_data}/PS_Parents/ps_stu_all_anon.dta", clear

* 2. Remove test answers, partial info, etc.
drop if status == 1 // or your condition for test responses
format startdate %tc
drop if startdate < clock("2024-11-11 10:00:00", "YMDhms")

* 3. Remove duplicates (based on e-mail or name)
duplicates tag responseid, gen(dup_id)
drop if dup_id > 0

* 4. Exclude missing e-mail if needed
drop if missing(compl_email)

* 5. Rename or relabel key variables
rename contract has_contract
label var has_contract "Has an apprenticeship contract"

* 6. Save intermediate
save "${processed_data}/PS_Parents/temp_parents_step2.dta", replace
log close
