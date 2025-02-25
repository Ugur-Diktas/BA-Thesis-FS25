*******************************************************************************
// 9_ps_students_clean_motivations.do
// Purpose : cleans the motivational factors 
// 
// Author  : Jelke Clarysse_Ugur Diktas (BA Thesis FS25, 18.02.2025)
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 18.0

cap log close
log using "${dodir_log}/ps_students_clean_motivations.log", replace text

// Turn on Stata's trace for very detailed debugging (comment out if too verbose).
// set trace on

timer clear
timer on 1

********************************************************************************
// 1. LOAD THE CLEANED DATA
********************************************************************************

di as txt "----- Loading dataset: ps_stu_cleaned.dta -----"
quietly use "${processed_data}/PS_Students/ps_stu_cleaned.dta", clear

di as txt "Observations: `c(N)'"
di as txt "Variables:    `c(k)'"

if _N == 0 {
    di as error "ERROR: No observations found in ps_stu_cleaned.dta."
    error 602
}
********************************************************************************
// 2.CREATE MOTIVATIONAL FACTOR VARIABLES
********************************************************************************
forval i = 1/13 {
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
		replace `q'_fac_7 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>Geschlechterzusammensetzung</strong> im Beruf"
	}
	forval j = 1/12 {
		replace `q'_fac_8 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Das Ausmass an <strong>sozialem Kontakt</strong>"
	}
	forval j = 1/12 {
		replace `q'_fac_9 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Menschen zu <strong>helfen</strong> (z.B. Kunden oder Patienten)"
	}
	forval j = 1/12 {
		replace `q'_fac_10 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der <strong>Arbeitsort</strong> (z.B. Büro, Aussenbereich, Baustelle)"
	}
	forval j = 1/12 {
		replace `q'_fac_11 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen"
	}
	forval j = 1/12 {
		replace `q'_fac_12 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die Aussicht auf <strong>Beförderungen</strong>"
	}
	forval j = 1/12 {
		replace `q'_fac_13 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Ihre persönlichen <strong>Interessen</strong>"
	}
}

drop motFactor*

********************************************************************************
// 3.RELABEL MOTIVATIONAL FACTORS IN ENLGISH CORRESPONDING FACTORS
********************************************************************************
local fac_1 "salary"
local fac_2 "flexibility"
local fac_3 "further education possibilities"
local fac_4 "math requirements"
local fac_5 "language requirements"
local fac_6 "parents' recommendations"
local fac_7 "gender composition"
local fac_8 "social contact"
local fac_9 "helping people"
local fac_10 "type of workplace"
local fac_11 "ability to obtain contract"
local fac_12 "promotion prospects"
local fac_13 "interests"

forval i = 1/13 {
	label var mother_fac_`i' "Mother's motivation factor: `fac_`i''"
	label var father_fac_`i' "Father's motivation factor: `fac_`i''"
	label var child_fac_`i' "Student's motivation factor: `fac_`i''"
}


********************************************************************************
// 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************

di as txt "----- Compressing and saving dataset -----"
compress

save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list

// Turn off trace if you turned it on earlier.
// set trace off

log close

