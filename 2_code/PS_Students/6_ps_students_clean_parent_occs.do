********************************************************************************
// 6_ps_students_clean_parent_occs.do
// Purpose : Cleans parent occupation text entries (mother_occ, father_occ)
//           in the PS Students dataset. First assigns preliminary ISCED codes
//           via string matching, then exports unique uncleaned entries for
//           manual review (via an Excel file) and finally merges the cleaned
//           results back into the dataset.
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
log using "${dodir_log}/ps_students_clean_parent_occs.log", replace text

timer clear
timer on 1

set seed 123

********************************************************************************
// 1) ASSIGN PRELIMINARY ISCED CODES TO PARENT OCCUPATIONS
//    (Based on string matching of raw text in mother_occ and father_occ)
********************************************************************************

use "${processed_data}/PS_Students/ps_stu_chars_merged.dta", clear

*-- If you have any standardized field, use it; otherwise use the raw textbox:
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
    
    * Use textbox alternative if available:
    capture confirm variable `x'_occ_text
    if !_rc {
        replace `x'_occ = `x'_occ_text if missing(`x'_occ)
    }
}

* Save a copy without parent occupation variables for later merge:
preserve
drop mother_occ father_occ
tempfile data_no_parent_occ
save `data_no_parent_occ'
restore

* Keep only raw parent occupation texts and ResponseId:
keep mother_occ father_occ ResponseId
keep if !missing(mother_occ) | !missing(father_occ)

* Convert to lowercase:
replace mother_occ = lower(mother_occ)
replace father_occ = lower(father_occ)

* Preliminary ISCED coding (adapt substring checks as needed):
foreach p in mother_occ father_occ {
    gen isced`p' = .
    replace isced`p' = 0611 if strpos(`p', "it")
    replace isced`p' = 1013 if strpos(`p', "wirtin")
    replace isced`p' = 0200 if strpos(`p', "händler")
    replace isced`p' = -14 if strpos(`p', "hausfrau") | strpos(`p', "haushalt") | strpos(`p', "familie")
    replace isced`p' = -2 if strpos(`p', "arbeitet nicht") | strpos(`p', "arbeitslos")
    replace isced`p' = 0410 if strpos(`p', "management")
    replace isced`p' = 0914 if strpos(`p', "arzt") | strpos(`p', "chirurg")
    // ... (add further rules as needed)
    
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

********************************************************************************
// 2) MANUAL REVIEW OF UNCLEANED OCCUPATIONS
//    Export unique uncleaned entries to Excel (Sheet1) and import manually cleaned
//    suggestions from the corresponding dta file in the assets folder.
********************************************************************************

foreach p in mother_occ father_occ {
    // Rename the raw variable to "occupation" and temporary text result to "isced6_try"
    rename `p' occupation
    rename isced6`p' isced6_try
    
    tempfile preserve
    save `preserve'
    
    keep occupation isced6_try
    bys occupation: keep if _n == 1
    drop if missing(occupation)
    
    // Merge with the existing cleaned occupations dta from the assets folder
    merge 1:1 occupation using "${assets}/clean occupations.dta"
    gen cleaned = (_merge == 3 | _merge == 2)
    sort cleaned occupation
    keep occupation isced6_try cleaned
    order occupation isced6_try cleaned
    keep if cleaned == 0
    tempfile uncleaned
    save `uncleaned'
    
    // Append uncleaned entries to the Excel file (Sheet1) located in assets
    import excel using "${assets}/clean occupations.xlsx", ///
         sheet("Sheet1") firstrow clear
    merge 1:1 occupation using `uncleaned', nogen update replace
    merge 1:1 occupation using "${assets}/clean occupations.dta", ///
         keepusing(occupation)
    replace cleaned = 1 if _merge == 3
    drop _merge
    sort cleaned occupation
    export excel using "${assets}/clean occupations.xlsx", ///
         sheet("Sheet1") sheetmodify cell(A1) firstrow(variables) keepcellfmt
         
    // Import manually cleaned suggestions from Sheet2
    import excel "${assets}/clean occupations.xlsx", ///
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
    export excel using "${assets}/clean occupations.xlsx", ///
         sheet("Sheet3") sheetmodify cell(A1) firstrow(variables) keepcellfmt
         
    // Save the updated cleaned occupations dta file back to assets
    save "${assets}/clean occupations.dta", replace
    
    use `preserve', clear
    merge m:1 occupation using "${assets}/clean occupations.dta", nogen keep(master match)
    forval i = 1/4 {
        rename isced6_`i' `p'_isced6_`i'
    }
    rename occupation `p'
    drop isced6_try
}

********************************************************************************
// 3) FINAL HOUSEKEEPING & MERGE BACK
********************************************************************************

* Label the cleaned variables
forval i = 1/4 {
    lab var mother_occ_isced6_`i' "Mother field (occupation `i')"
    lab var father_occ_isced6_`i' "Father field (occupation `i')"
}

lab var mother_occ "Raw textbox mother occupation"
lab var father_occ "Raw textbox father occupation"

tempfile cleaned_parent_occs
save `cleaned_parent_occs'

use `data_no_parent_occ', clear
merge 1:1 ResponseId using `cleaned_parent_occs', nogen

* As an example, create a final variable from the first suggestion:
rename mother_occ_isced6_1 mother_occ_isced6_final
rename father_occ_isced6_1 father_occ_isced6_final

compress
save "${processed_data}/PS_Students/ps_stu_clean_parent_occs.dta", replace

timer off 1
timer list

log close
