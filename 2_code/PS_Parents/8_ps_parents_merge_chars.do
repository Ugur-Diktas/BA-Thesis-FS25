********************************************************************************
* 8_ps_parents_merge_chars.do
* ------------------------------------------------------------------------------
* Data needed: ps_par_clean_concerns.dta
* Data output: ps_par_merge_chars.dta
* Purpose:
*   - Merge the PS Parents dataset with external apprenticeship/occupation
*     characteristics (e.g. skill intensity, female share, math and language 
*     requirements, and ISCED2 classifications).
*   - For each parental preference variable, use the corresponding "_code"
*     variable as the merge key and rename the merged characteristics with a 
*     prefix corresponding to the original variable.
*   - Save the updated dataset.
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
*
* Copyright (C) 2025 Ugur Diktas, Jelke CLarysse. All rights reserved.
* This code is proprietary and may not be reproduced, distributed, or modified
* without prior written consent.
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
log using "${dodir_log}/8_ps_parents_merge_chars.log", replace text

timer clear
timer on 1

//----------------------------------------------------------------------------
// 1. LOAD DATA
//----------------------------------------------------------------------------
di as txt "----- Loading dataset: temp_par_clean_parent_occs.dta -----"
use "${processed_data}/PS_Parents/7_ps_parents.dta", clear
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
save "${processed_data}/PS_Parents/8_ps_parents.dta", replace

timer off 1
timer list
log close
