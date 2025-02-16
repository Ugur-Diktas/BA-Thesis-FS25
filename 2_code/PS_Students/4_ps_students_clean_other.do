********************************************************************************
// 4_ps_students_clean_other.do
// Purpose : Cleans 'other' occupation textboxes and related fields in the
//           PS Students dataset. Merges with external references if needed,
//           corrects typos, etc.
//
// Author  : Your Name (BA Thesis FS25, dd.mm.yyyy)
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 17.0

cap log close
log using "${dodir_log}/ps_students_clean_other.log", replace text

timer clear
timer on 1

// Optional: set trace on  // Very verbose debugging

********************************************************************************
// 1. LOAD THE CLEANED DATA
//    from the previous step (ps_stu_cleaned.dta)
********************************************************************************

di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"
quietly use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"

if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    error 603
}

********************************************************************************
// 2. IDENTIFY AND CLEAN 'OTHER' VARIABLES
//    E.g. contract_occ, plan, prefchild_*_42_TEXT, etc.
//    Adjust to your actual variable names.
********************************************************************************

di as txt "----- Inspecting potential 'other' variables -----"

// Example: check variables containing "occ", "pref", or "other"
ds *occ* *pref* *other*
describe *occ* *pref* *other*

// Suppose you have a variable called "plan" that sometimes has "Other" text:
* Example: cleaning line breaks, trailing spaces, typical typos
capture confirm variable plan
if !_rc {
    replace plan = subinstr(plan, char(10), "", .)    // remove line breaks
    replace plan = strtrim(plan)
    replace plan = stritrim(plan)                     // remove extra spaces
    // Add further cleaning steps or merges if needed
}

// Another example: "contract_occ" might have a "42_TEXT" or "43_TEXT" for "other"
capture confirm variable contract_occ_42_TEXT
if !_rc {
    replace contract_occ_42_TEXT = subinstr(contract_occ_42_TEXT, char(10), "", .)
    replace contract_occ_42_TEXT = strtrim(contract_occ_42_TEXT)
    replace contract_occ_42_TEXT = stritrim(contract_occ_42_TEXT)
    // Possibly rename to something simpler, if you like
    // capture rename contract_occ_42_TEXT contract_occ_other_text
}

********************************************************************************
// 3. MERGE 'OTHER' FIELDS WITH OCCUPATION REFERENCE FILES (IF APPLICABLE)
//    E.g., if you have an external .dta or .do file for standardising occupation
//    names, like "clean_apprenticeships.do" or "app_names.dta"
********************************************************************************

/*
    // Example if you have a do-file that standardises text entries:
    // 1) Temporarily rename the variable to "Apprenticeship"
    capture confirm variable contract_occ_42_TEXT
    if !_rc {
        rename contract_occ_42_TEXT Apprenticeship

        tempfile keep_original
        save `keep_original'

        // keep only the variable to be cleaned
        keep Apprenticeship
        do "${dodir_cleaning}/clean_apprenticeships.do"

        // reload original, merge in cleaned data
        use `keep_original', clear
        merge m:1 Apprenticeship using "${dodir_cleaning}/clean_apprenticeships", ///
            nogen keep(master match) keepusing(labb_code_1 app_official_1)
        rename Apprenticeship contract_occ_42_TEXT
        rename labb_code_1   contract_occ_code
        rename app_official_1 contract_occ_cleaned
    }
*/

********************************************************************************
// 4. FURTHER CLEANING, LABELS, OR RECODING
//    If merging multiple 'other' fields, you might unify them or recode them.
********************************************************************************

/*
    // For instance, unify "contract_occ_cleaned" with a main occupation variable:
    capture confirm variable contract_occ
    if !_rc & _rc != 111 {
        replace contract_occ = contract_occ_cleaned if missing(contract_occ)
        drop contract_occ_cleaned
        label var contract_occ "Cleaned Contract Occupation"
    }
*/

********************************************************************************
// 5. SAVE & WRAP UP
********************************************************************************

di as txt "----- Compressing and saving the updated dataset -----"
compress

save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list

// set trace off
log close
