********************************************************************************
 * 7_ps_parents_merge_chars.do
 * --------------------------------------------------------------------------------
 * Purpose:
 * - Merge the PS Parents dataset with external apprenticeship/occupation
 *   characteristics (e.g. skill intensity, female share, math and language 
 *   requirements, and ISCED2 classifications).
 * - For each parental preference variable, use the corresponding "_code"
 *   variable as the merge key and rename the merged characteristics with a 
 *   prefix corresponding to the original variable.
 * - Save the updated dataset.
 *
 * Data Requirements:
 *   - Apprenticeship characteristics file:
 *         ${data_to_merge}/skill_intensity_data_with_apprentice_characteristics.dta
 *   - Cleaned PS Parents file:
 *         ${processed_data}/PS_Parents/temp_par_clean_parent_occs.dta
 *
 * Globals Needed:
 *   data_to_merge, processed_data, dodir_log, debug
 *
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 01.03.2025
* Version: Stata 18
********************************************************************************

//----------------------------------------------------------------------------
// 0. HOUSEKEEPING
//----------------------------------------------------------------------------
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
log using "${dodir_log}/7_ps_parents_merge_chars.log", replace text

timer clear
timer on 1

//----------------------------------------------------------------------------
// 1. LOAD DATA
//----------------------------------------------------------------------------
di as txt "----- Loading dataset: temp_par_clean_parent_occs.dta -----"
use "${processed_data}/PS_Parents/temp_par_clean_parent_occs.dta", clear
di as txt "Loaded temp_par_clean_parent_occs.dta: `c(N)' obs"

//----------------------------------------------------------------------------
// 2. MERGE EXTERNAL CHARACTERISTICS
//    For each parental preference variable, use the corresponding "_code"
//    variable as merge key to append apprenticeship characteristics.
//----------------------------------------------------------------------------
local pref_vars "prefown_m prefown_f prefchild_m prefchild_f"

foreach p of local pref_vars {
    di as txt "----- Processing variable: `p' -----"
    
    // Prüfe, ob die entsprechende _code-Variable existiert.
    capture confirm variable `p'_code
    if _rc {
        di as error "Variable `p'_code nicht gefunden. Überspringe `p'."
        continue
    }
    
    // Erstelle einen temporären Merge-Schlüssel
    gen labb_code = `p'_code
    
    merge m:1 labb_code using "${data_to_merge}/skill_intensity_data_with_apprentice_characteristics.dta", ///
         keep(match master) nogen
         
    drop labb_code
    
    // Umbenennen der gemergten Variablen für bessere Übersicht
    rename female_grad   `p'_female_share
    rename skills_ave_math `p'_math_req
    rename skills_ave_ownlang `p'_lang_req

    // Optional: Eigene Geschlechteranteilsvariable erstellen (sofern Variable "female" vorliegt)
    local p_lab: variable label `p'
    gen `p'_og_share = `p'_female_share if female == 1
    replace `p'_og_share = 1 - `p'_female_share if female == 0
    
    // Informative Beschriftungen zuweisen
    label var `p'_female_share  "`p_lab' female share"
    label var `p'_math_req      "`p_lab' math requirements"
    label var `p'_lang_req      "`p_lab' language requirements"
    label var `p'_og_share      "`p_lab' own gender share"
    
    di as txt "Merge für `p' abgeschlossen."
}

//----------------------------------------------------------------------------
// 3. FINAL HOUSEKEEPING & SAVE
//----------------------------------------------------------------------------
compress
save "${processed_data}/PS_Parents/ps_par_merge_chars.dta", replace

timer off 1
timer list
log close
