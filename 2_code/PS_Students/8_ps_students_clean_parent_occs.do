/********************************************************************************
 * 8_ps_students_clean_parent_occs.do
 * --------------------------------------------------------------------------------
 * Purpose:
 *   This do‐file cleans parent occupation text entries (mother_occ and father_occ)
 *   in the PS Students dataset. The procedure is as follows:
 *     1. Assign preliminary ISCED codes to parent occupations via string matching.
 *     2. Export unique (uncleaned) occupation entries for manual review by writing
 *        them to an Excel file. In the Excel file you update the suggested ISCED‐F
 *        category (using the clean occupations.xlsx file located in the assets folder).
 *     3. Import the manually cleaned suggestions and merge them back into the dataset,
 *        thereby creating cleaned parent occupation variables.
 *     4. Finally, merge the cleaned parent occupation data back into the main 
 *        student dataset using ResponseId.
 *
 * Data Requirements:
 *   - Cleaned student dataset "ps_stu_chars_merged.dta" in:
 *         ${processed_data}/PS_Students
 *   - The asset folder for parent occupations: 
 *         ${parental_occupation_cleaning_new} (which contains "clean occupations.dta" and 
 *         "clean occupations.xlsx")
 *
 * Globals Needed:
 *   processed_data, dodir_log, parental_occupation_cleaning_new, debug
 *
 * Author  : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 01.03.2025
 * Version : Stata 18
 ********************************************************************************/

//----------------------------------------------------------------------------
// 0. HOUSEKEEPING
//----------------------------------------------------------------------------
clear all
set more off
version 18.0

// Enable/disable trace based on debug flag
if ("${debug}" == "yes") {
    set trace on
}
else {
    set trace off
}

cap log close
log using "${dodir_log}/8_ps_students_clean_parent_occs.log", replace text

timer clear
timer on 1

//----------------------------------------------------------------------------
// 1) ASSIGN PRELIMINARY ISCED CODES TO PARENT OCCUPATIONS
//    (Based on raw text in mother_occ and father_occ)
//----------------------------------------------------------------------------
di as txt "----- Step 1: Assign preliminary ISCED codes to parent occupations -----"

use "${processed_data}/PS_Students/ps_stu_chars_merged.dta", clear

// For each parent (mother and father), create a variable that holds a preliminary ISCED‐F field
foreach x in mother father {
    gen `x'_occ_isced6 = ""
    replace `x'_occ_isced6 = "Gesundheit, Pflege, Betreuung und Ausbildung" ///
         if `x'_occ == "Gesundheit, Pflege, Betreuung und Ausbildung (z.B. Lehrer/-in, Pflegefachmann/-frau, Kinderbetreuer/-in, Arzt/Ärztin)"
    replace `x'_occ_isced6 = "Dienstleistungen und Detailhandel" ///
         if `x'_occ == "Dienstleistungen und Detailhandel (z.B. Gastronomie, Reinigung, Hotellerie, Vertrieb)"
    replace `x'_occ_isced6 = "Wirtschaft, Verwaltung und Recht" ///
         if `x'_occ == "Wirtschaft, Verwaltung und Recht (z.B. KV, Bank, Logistik)"
    replace `x'_occ_isced6 = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
         if `x'_occ == "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften"
    replace `x'_occ_isced6 = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
         if `x'_occ == "Sozialwisschenschaften, Journalismus und Geisteswissenschaften" | ///
            `x'_occ == "Sozialwissenschaften, Journalismus und Geisteswissenschaften"
    replace `x'_occ_isced6 = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
         if `x'_occ == "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin"
    
    // If an alternative textbox exists (e.g., field_educ_x_text), use it when the main variable is missing.
    capture confirm variable `x'_occ_text
    if !_rc {
        replace `x'_occ = `x'_occ_text if missing(`x'_occ)
    }
}

// Save a copy of the dataset without the parent occupation variables for later merging.
preserve
drop mother_occ father_occ
tempfile data_no_parent_occ
save `data_no_parent_occ'
restore

// Keep only the raw parent occupation texts and ResponseId.
keep mother_occ father_occ ResponseId
keep if !missing(mother_occ) | !missing(father_occ)

// Standardize text by converting to lowercase.
replace mother_occ = lower(mother_occ)
replace father_occ = lower(father_occ)

// Preliminary ISCED coding using string matching (add or adjust rules as needed).
foreach p in mother_occ father_occ {
    gen isced`p' = .
    replace isced`p' = 0611 if strpos(`p', "it")
    replace isced`p' = 1013 if strpos(`p', "wirtin")
    replace isced`p' = 0200 if strpos(`p', "händler")
    replace isced`p' = -14 if strpos(`p', "hausfrau") | strpos(`p', "haushalt") | strpos(`p', "familie")
    replace isced`p' = -2 if strpos(`p', "arbeitet nicht") | strpos(`p', "arbeitslos")
    replace isced`p' = 0410 if strpos(`p', "management")
    replace isced`p' = 0914 if strpos(`p', "arzt") | strpos(`p', "chirurg")
    // ... add additional rules as needed

    // Map raw ISCED codes to a simplified ISCED-F field grouping.
    gen isced_field`p' = .
    replace isced_field`p' = 1 if isced`p' == 0111
    replace isced_field`p' = 2 if inlist(isced`p', 0212, 0214, 0215, 211)
    replace isced_field`p' = 3 if isced`p' == 0322
    replace isced_field`p' = 4 if inlist(isced`p', 0410, 0413, 0415, 0416, 0421)
    replace isced_field`p' = 5 if isced`p' == 51
    replace isced_field`p' = 6 if inlist(isced`p', 0611, 0613)
    replace isced_field`p' = 7 if inrange(isced_field`p', 5, 7)
    replace isced_field`p' = 8 if inlist(isced`p', 0811, 0841)
    replace isced_field`p' = 9 if inlist(isced`p', 0911, 0913, 0914, 0923)
    replace isced_field`p' = 10 if inlist(isced`p', 1011, 1013, 1014, 1041, 0200)
    
    gen isced6`p' = ""
    replace isced6`p' = "Gesundheit, Pflege, Betreuung und Ausbildung" if inlist(isced_field`p', 1, 9)
    replace isced6`p' = "Dienstleistungen und Detailhandel" if isced_field`p' == 10
    replace isced6`p' = "Wirtschaft, Verwaltung und Recht" if isced_field`p' == 4
    replace isced6`p' = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" if inrange(isced_field`p', 5, 7)
    replace isced6`p' = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" if inlist(isced_field`p', 3, 2)
    replace isced6`p' = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" if isced_field`p' == 8
    replace isced6`p' = "" if isced`p' == -14
    
    drop isced_field`p' isced`p'
}

//----------------------------------------------------------------------------
// 2) MANUAL REVIEW OF UNCLEANED OCCUPATIONS
//    Export unique uncleaned occupation entries to Excel for manual cleaning.
//----------------------------------------------------------------------------
di as txt "----- Exporting uncleaned parent occupation entries for manual review -----"

foreach p in "mother_occ" "father_occ" {
    // Rename for processing
    rename `p' occupation
    rename isced6`p' isced6_try

    tempfile preserve
    save `preserve'
    
    // Keep unique occupation entries
    keep occupation isced6_try
    bys occupation: keep if _n == 1
    drop if missing(occupation)
    
    // Merge with the already cleaned occupations from the assets folder.
    merge 1:1 occupation using "${parental_occupation_cleaning_new}/clean occupations.dta"
    gen cleaned = (_merge == 3 | _merge == 2)
    sort cleaned occupation
    keep occupation isced6_try cleaned
    order occupation isced6_try cleaned
    keep if cleaned == 0
    tempfile uncleaned
    save `uncleaned'
    
    // Append these uncleaned entries to the Excel file (Sheet1)
    import excel using "${parental_occupation_cleaning_new}/clean occupations.xlsx", ///
         sheet("Sheet1") firstrow clear
    merge 1:1 occupation using `uncleaned', nogen update replace
    merge 1:1 occupation using "${parental_occupation_cleaning_new}/clean occupations.dta", ///
         keepusing(occupation)
    replace cleaned = 1 if _merge == 3
    drop _merge
    sort cleaned occupation
    export excel using "${parental_occupation_cleaning_new}/clean occupations.xlsx", ///
         sheet("Sheet1") sheetmodify cell(A1) firstrow(variables) keepcellfmt
         
    // Import manually cleaned suggestions from the Excel file (Sheet2)
    import excel "${parental_occupation_cleaning_new}/clean occupations.xlsx", ///
         sheet("Sheet2") firstrow allstring clear
    drop if missing(occupation)
    drop if missing(checked)
    drop checked
    forval i = 1/4 {
        gen isced6_`i' = ""
        replace isced6_`i' = "Gesundheit, Pflege, Betreuung und Ausbildung" if suggestion_`i' == "1"
        replace isced6_`i' = "Dienstleistungen und Detailhandel" if suggestion_`i' == "2"
        replace isced6_`i' = "Wirtschaft, Verwaltung und Recht" if suggestion_`i' == "3"
        replace isced6_`i' = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" if suggestion_`i' == "4"
        replace isced6_`i' = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" if suggestion_`i' == "5"
        replace isced6_`i' = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" if suggestion_`i' == "6"
        replace isced6_`i' = "" if inlist(suggestion_`i', "not clear", "-8", "-2", "-14")
    }
    replace isced6_1 = isced6_try if missing(flag_try_error)
    replace isced6_1 = "" if isced6_1 == "Hausmann/-frau"
    drop suggestion* isced6_try flag_try_error
    
    order occupation isced6*
    export excel using "${parental_occupation_cleaning_new}/clean occupations.xlsx", ///
         sheet("Sheet3") sheetmodify cell(A1) firstrow(variables) keepcellfmt
         
    // Save updated cleaned occupations dataset back to the assets folder.
    save "${parental_occupation_cleaning_new}/clean occupations.dta", replace
    
    // Reload preserved data and merge with cleaned occupations.
    use `preserve', clear
    merge m:1 occupation using "${parental_occupation_cleaning_new}/clean occupations.dta", nogen keep(master match)
    forval i = 1/4 {
        rename isced6_`i' `p'_isced6_`i'
    }
    rename occupation `p'
    drop isced6_try
}

* Label the cleaned variables for clarity.
forval i = 1/4 {
    lab var mother_occ_isced6_`i' "Mother field (occupation suggestion `i')"
    lab var father_occ_isced6_`i' "Father field (occupation suggestion `i')"
}

lab var mother_occ "Raw textbox mother occupation"
lab var father_occ "Raw textbox father occupation"

// Save the cleaned parent occupations in a temporary file.
tempfile cleaned_parent_occs
save `cleaned_parent_occs'

//----------------------------------------------------------------------------
// 3) FINAL HOUSEKEEPING & MERGE BACK
//    Merge the cleaned parent occupation data with the main dataset (without parent occ).
//----------------------------------------------------------------------------
use `data_no_parent_occ', clear
merge 1:1 ResponseId using `cleaned_parent_occs', nogen

// For illustration, create final variables from the first suggestion.
rename mother_occ_isced6_1 mother_occ_isced6_final
rename father_occ_isced6_1 father_occ_isced6_final

compress
save "${processed_data}/PS_Students/ps_stu_clean_parent_occs.dta", replace

timer off 1
timer list

log close
