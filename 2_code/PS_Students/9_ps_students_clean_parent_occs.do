********************************************************************************
* 9_ps_students_clean_parent_occs.do
* ------------------------------------------------------------------------------
* Data needed: 8_ps_students.dta
* Data output: 9_ps_students.dta
* Purpose:
*   - Creates standardized parent occupation variables
*   - Handles the mapping to ISCED codes with minimal processing
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 12.03.2025
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
log using "${dodir_log}/9_ps_students_clean_parent_occs.log", replace text

timer clear
timer on 1

//----------------------------------------------------------------------------
// 1. LOAD AND PREPARE DATASET
//----------------------------------------------------------------------------
di as txt "----- Loading dataset: 8_ps_students.dta -----"
use "${processed_data}/PS_Students/8_ps_students.dta", clear

// Initialize final variables
capture confirm variable mother_occ_isced6_final
if _rc {
    gen mother_occ_isced6_final = ""
    label var mother_occ_isced6_final "Mother's occupation field (cleaned)"
}

capture confirm variable father_occ_isced6_final
if _rc {
    gen father_occ_isced6_final = ""
    label var father_occ_isced6_final "Father's occupation field (cleaned)"
}

// Initialize numeric ISCED fields
capture confirm variable mother_isced_num
if _rc {
    gen mother_isced_num = .
    label var mother_isced_num "ISCED field code for mother"
}

capture confirm variable father_isced_num
if _rc {
    gen father_isced_num = .
    label var father_isced_num "ISCED field code for father"
}

//----------------------------------------------------------------------------
// 2. DIRECT ISCED CODE ASSIGNMENT
//----------------------------------------------------------------------------
di as txt "----- Assigning ISCED codes directly -----"

// Direct mapping based on standard categories
foreach parent in mother father {
    capture confirm variable `parent'_occ
    if !_rc {
        // Assign ISCED codes based on standard categories
        replace `parent'_occ_isced6_final = "Gesundheit, Pflege, Betreuung und Ausbildung" ///
             if `parent'_occ == "Gesundheit, Pflege, Betreuung und Ausbildung (z.B. Lehrer/-in, Pflegefachmann/-frau, Kinderbetreuer/-in, Arzt/Ärztin)" & missing(`parent'_occ_isced6_final)
        
        replace `parent'_occ_isced6_final = "Dienstleistungen und Detailhandel" ///
             if `parent'_occ == "Dienstleistungen und Detailhandel (z.B. Gastronomie, Reinigung, Hotellerie, Vertrieb)" & missing(`parent'_occ_isced6_final)
        
        replace `parent'_occ_isced6_final = "Wirtschaft, Verwaltung und Recht" ///
             if `parent'_occ == "Wirtschaft, Verwaltung und Recht (z.B. KV, Bank, Logistik)" & missing(`parent'_occ_isced6_final)
        
        replace `parent'_occ_isced6_final = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
             if `parent'_occ == "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" & missing(`parent'_occ_isced6_final)
        
        replace `parent'_occ_isced6_final = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
             if (`parent'_occ == "Sozialwisschenschaften, Journalismus und Geisteswissenschaften" | ///
                `parent'_occ == "Sozialwissenschaften, Journalismus und Geisteswissenschaften") & missing(`parent'_occ_isced6_final)
        
        replace `parent'_occ_isced6_final = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
             if `parent'_occ == "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" & missing(`parent'_occ_isced6_final)
        
        // Common special cases
        replace `parent'_occ_isced6_final = "Hausfrau/mann" if inlist(lower(`parent'_occ), "hausfrau", "hausmann", "hausfrau/mann") & missing(`parent'_occ_isced6_final)
        
        // Count how many were directly mapped
        count if !missing(`parent'_occ_isced6_final) & !missing(`parent'_occ)
        local n_mapped = r(N)
        count if missing(`parent'_occ_isced6_final) & !missing(`parent'_occ)
        local n_unmapped = r(N)
        
        di as txt "Direct mapping for `parent'_occ: `n_mapped' mapped, `n_unmapped' unmapped"
    }
    else {
        di as txt "Variable `parent'_occ not found."
    }
}

//----------------------------------------------------------------------------
// 3. CREATE NUMERIC ISCED FIELDS
//----------------------------------------------------------------------------
di as txt "----- Creating numeric ISCED fields -----"

// Create numeric ISCED fields
foreach parent in mother father {
    replace `parent'_isced_num = 1 if `parent'_occ_isced6_final == "Gesundheit, Pflege, Betreuung und Ausbildung"
    replace `parent'_isced_num = 2 if `parent'_occ_isced6_final == "Dienstleistungen und Detailhandel"
    replace `parent'_isced_num = 3 if `parent'_occ_isced6_final == "Wirtschaft, Verwaltung und Recht"
    replace `parent'_isced_num = 4 if `parent'_occ_isced6_final == "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften"
    replace `parent'_isced_num = 5 if `parent'_occ_isced6_final == "Sozialwissenschaften, Journalismus und Geisteswissenschaften"
    replace `parent'_isced_num = 6 if `parent'_occ_isced6_final == "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin"
    replace `parent'_isced_num = -14 if `parent'_occ_isced6_final == "Hausfrau/mann"
    replace `parent'_isced_num = -2 if `parent'_occ_isced6_final == "None"
    replace `parent'_isced_num = -8 if `parent'_occ_isced6_final == "Doesn't know"
}

// Define value labels for ISCED fields
label define isced_field_lbl ///
    1 "Gesundheit, Pflege, Betreuung und Ausbildung" ///
    2 "Dienstleistungen und Detailhandel" ///
    3 "Wirtschaft, Verwaltung und Recht" ///
    4 "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
    5 "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
    6 "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
    -14 "Hausfrau/mann" ///
    -2 "None" ///
    -8 "Doesn't know"

label values mother_isced_num father_isced_num isced_field_lbl

//----------------------------------------------------------------------------
// 4. EXPORT UNMAPPED OCCUPATIONS FOR REFERENCE
//----------------------------------------------------------------------------
di as txt "----- Exporting unmapped occupations for reference -----"

// Export unmapped mother occupations
capture confirm variable mother_occ
if !_rc {
    preserve
        keep if !missing(mother_occ) & missing(mother_occ_isced6_final)
        if _N > 0 {
            keep ResponseId mother_occ
            gen occ_type = "mother"
            tempfile mother_unmapped
            save `mother_unmapped'
        }
    restore
}

// Export unmapped father occupations
capture confirm variable father_occ
if !_rc {
    preserve
        keep if !missing(father_occ) & missing(father_occ_isced6_final)
        if _N > 0 {
            keep ResponseId father_occ
            gen occ_type = "father"
            rename father_occ parent_occ
            
            // Append mother occupations if any
            capture confirm file `mother_unmapped'
            if !_rc {
                rename parent_occ father_occ
                append using `mother_unmapped'
                rename mother_occ parent_occ
            }
            
            // Export to Excel
            capture export excel ResponseId occ_type parent_occ using "${processed_data}/PS_Students/unmapped_occupations.xlsx", ///
                firstrow(variables) replace
                
            if !_rc {
                di as txt "Exported unmapped occupations to ${processed_data}/PS_Students/unmapped_occupations.xlsx"
            }
        }
    restore
}

//----------------------------------------------------------------------------
// 5. SAVE FINAL DATASET
//----------------------------------------------------------------------------
di as txt "----- Saving final dataset -----"

// Final verification
count if !missing(mother_occ_isced6_final)
di as txt "Mother occupations with ISCED codes: `r(N)'"
count if !missing(father_occ_isced6_final)
di as txt "Father occupations with ISCED codes: `r(N)'"

// Save final dataset
compress
save "${processed_data}/PS_Students/9_ps_students.dta", replace

timer off 1
timer list
log close