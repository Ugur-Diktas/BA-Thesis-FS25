********************************************************************************
* 5_ps_students_clean_motivations.do
* ------------------------------------------------------------------------------
* Data needed: ps_stu_cleaned.dta
* Data output: ps_stu_cleaned.dta
* Purpose:
*   - Process and transform motivational factor data for students
*   - Create binary (0/1) variables for 12 motivational factors (e.g., salary, 
*     flexibility, further education, math requirements)
*   - Process factors for child, mother, and father perspectives
*   - Label all variables for better interpretation
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 09.03.2025
* Version: Stata 18
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING
********************************************************************************

// Standard initialization
version 18.0
clear all
set more off

// Log initialization
cap log close
log using "${dodir_log}/5_ps_students_clean_motivations.log", replace text

// Performance monitoring
timer clear
timer on 1

*******************************************************************************
// 1. DATA VALIDATION
*******************************************************************************

quietly use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

// Dataset validation checks
if _N == 0 {
    di as error "ERROR: Empty dataset - ps_stu_cleaned.dta contains no observations"
    error 601
}

unab allvars: _all
if !`:list posof "motFactors_child_1" in allvars' {
    di as error "ERROR: Motivational factors variables missing"
    error 111
}
********************************************************************************
// 2.CREATE MOTIVATIONAL FACTOR VARIABLES
*.   a.This is a loop that goes through the motivational factors and
*      This section creates binary (0/1) variables for 13 motivational factors 
*      separately for the child, mother, and father.
********************************************************************************
forval i = 1/12 {
	gen child_fac_`i' = .
	gen mother_fac_`i' = .
	gen father_fac_`i' = .
}

foreach q in "child" "mother" "father" {
	forval j = 1/12 {
		replace `q'_fac_1 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der zukünftige <strong>Lohn</strong>"
	}
	forval j = 1/12 {
		replace `q'_fac_2 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die zukünftige berufliche <strong>Flexibilität</strong> (z. B. die Möglichkeit, in Teilzeit zu arbeiten)"
	}
	forval j = 1/12 {
		replace `q'_fac_3 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>"
	}
	forval j = 1/12 {
		replace `q'_fac_4 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>mathematischen</strong> Anforderungen"
	}
	forval j = 1/12 {
		replace `q'_fac_5 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>sprachlichen</strong> Anforderungen"
	}
	forval j = 1/12 {
		replace `q'_fac_6 = 1 if motFactors_`q'_`j' == 1 & trim(motFactor`j') == "Die <strong>Geschlechterzusammensetzung</strong> im Beruf"
	}
	forval j = 1/12 {
		replace `q'_fac_7 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Das Ausmass an <strong>sozialem Kontakt</strong>"
	}
	forval j = 1/12 {
		replace `q'_fac_8 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Menschen zu <strong>helfen</strong> (z.B. Kunden oder Patienten)"
	}
	forval j = 1/12 {
		replace `q'_fac_9 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der <strong>Arbeitsort</strong> (z.B. Büro, Aussenbereich, Baustelle)"
	}
	forval j = 1/12 {
		replace `q'_fac_10 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen"
	}
	forval j = 1/12 {
		replace `q'_fac_11 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die Aussicht auf <strong>Beförderungen</strong>"
	}
	forval j = 1/12 {
		replace `q'_fac_12 = 1 if motFactors_`q'_`j' == 1 & trim(motFactor`j') == "Persönlichen <strong>Interessen</strong>"
	}
}

drop motFactor*

********************************************************************************
// 3.RELABEL MOTIVATIONAL FACTORS IN ENLGISH CORRESPONDING FACTORS
*.   a. Assign the right labels to the motivational factors for easier understanding
********************************************************************************
local fac_1 "salary"
local fac_2 "flexibility"
local fac_3 "further education possibilities"
local fac_4 "math requirements"
local fac_5 "language requirements"
local fac_6 "gender composition"
local fac_7 "social contact"
local fac_8 "helping people"
local fac_9 "type of workplace"
local fac_10 "ability to obtain contract"
local fac_11 "promotion prospects"
local fac_12 "interests"

forval i = 1/12 {
	label var mother_fac_`i' "Mother's motivation factor: `fac_`i''"
	label var father_fac_`i' "Father's motivation factor: `fac_`i''"
	label var child_fac_`i' "Student's motivation factor: `fac_`i''"
}


*******************************************************************************
// 4. FINALIZATION
*******************************************************************************

// Cleanup and validation
/*capture confirm variable child_fac_1
if _rc {
    di as error "ERROR: Factor variables not created properly"
    error 459
}
*/

// Dataset preservation
compress
save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

// Performance report
timer off 1
timer list 1
log close
