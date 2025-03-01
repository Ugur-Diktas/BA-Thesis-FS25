********************************************************************************
* 8_ps_parents_merge_chars.do
*
* Purpose:
* - Merge the PS Parents dataset with external apprenticeship/occupation
*   characteristics (e.g. skill intensity, female share).
* - For each preference variable, link to a coded variable to merge characteristics.
* - Save updated dataset.
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
log using "${dodir_log}/8_ps_parents_merge_chars.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD DATA
********************************************************************************

use "${processed_data}/PS_Parents/temp_par_clean_parent_occs.dta", clear
di as txt "Loaded temp_par_clean_parent_occs.dta: `c(N)' obs"

********************************************************************************
* 2. MERGE EXTERNAL CHARACTERISTICS
********************************************************************************

* Suppose you have skill_intensity_data_with_apprentice_characteristics.dta
* We'll do an m:1 merge using a variable like prefchild_m_code or similar
local pref_vars "prefown_m prefown_f prefchild_m prefchild_f"
foreach p of local pref_vars {
    capture confirm variable `p'_code
    if !_rc {
        di as txt "No code var found for `p', skipping..."
        continue
    }
    gen labb_code = `p'_code
    merge m:1 labb_code using "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics.dta", ///
        keep(master match) nogen
    drop labb_code
}

********************************************************************************
* 3. FINAL HOUSEKEEPING & SAVE
********************************************************************************

compress
save "${processed_data}/PS_Parents/ps_par_merge_chars.dta", replace

timer off 1
timer list
log close
