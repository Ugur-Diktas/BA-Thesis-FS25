*******************************************************************************
* 5_ps_students_clean_motivations.do
* Project:   PS Students Analysis
* Purpose:   Cleans and transforms motivational factors data
* Version:   2.0
* Author:    BA Thesis Team (Jelke Clarysse & Ugur Diktas)
* Date:      2025-03-03
* History:   Revised for efficiency and clarity
* Notes:     - Uses parallel processing structure
*            - Implements improved error handling
*            - Optimized loop structure for better performance
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25, 03.03.2025
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
log using "${dodir_log}/students_clean_motivations.log", replace text

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
* 2. MOTIVATIONAL FACTORS PROCESSING (Alternative Mechanism)
********************************************************************************
* This section hard‐codes the mapping between factor labels (in German)
* and factor numbers via a series of if‑else statements. It creates empty factor 
* variables for each role (child, mother, father) and then populates them based on 
* the label of each motivational factor question.
********************************************************************************
/*
* Create empty factor variables for each role
foreach role in child mother father {
    forval i = 1/13 {
        gen `role'_fac_`i' = 0
        label variable `role'_fac_`i' "`role' motivation factor `i'"
    }
}

* Process each motivational factor question (assumed indices 1 to 12)
forval j = 1/12 {
    local current_label : var label motFactor`j'
    local factor_num = 0
    
    if "`current_label'" == "Der zukünftige <strong>Lohn</strong>" {
        local factor_num = 1
    }
    else if "`current_label'" == "Die zukünftige berufliche <strong>Flexibilität</strong>" {
        local factor_num = 2
    }
    else if "`current_label'" == "Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>" {
        local factor_num = 3
    }
    else if "`current_label'" == "Die <strong>mathematischen</strong> Anforderungen" {
        local factor_num = 4
    }
    else if "`current_label'" == "Die <strong>sprachlichen</strong> Anforderungen" {
        local factor_num = 5
    }
    else if "`current_label'" == "Die <strong>Empfehlungen der Eltern</strong>" {
        local factor_num = 6
    }
    else if "`current_label'" == "Die <strong>Geschlechterzusammensetzung</strong>" {
        local factor_num = 7
    }
    else if "`current_label'" == "Das Ausmass an <strong>sozialem Kontakt</strong>" {
        local factor_num = 8
    }
    else if "`current_label'" == "Menschen zu <strong>helfen</strong>" {
        local factor_num = 9
    }
    else if "`current_label'" == "Der <strong>Arbeitsort</strong>" {
        local factor_num = 10
    }
    else if "`current_label'" == "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen" {
        local factor_num = 11
    }
    else if "`current_label'" == "Die Aussicht auf <strong>Beförderungen</strong>" {
        local factor_num = 12
    }
    else if "`current_label'" == "Ihre persönlichen <strong>Interessen</strong>" {
        local factor_num = 13
    }
    
    if `factor_num' != 0 {
        foreach role in child mother father {
            quietly replace `role'_fac_`factor_num' = 1 if motFactor_`role'_`j' == 1
        }
    }
    else {
        di as error "WARNING: Unmapped label found: `current_label'"
    }
}

********************************************************************************
* 3. VARIABLE LABELING (Hard-Coded)
********************************************************************************
* For each role (child, mother, father), assign a hard-coded label to each of
* the 13 factor variables.
********************************************************************************

foreach role in child mother father {
    label variable `role'_fac_1  "`role': Future salary"
    label variable `role'_fac_2  "`role': Career flexibility"
    label variable `role'_fac_3  "`role': Further education opportunities"
    label variable `role'_fac_4  "`role': Mathematical requirements"
    label variable `role'_fac_5  "`role': Language requirements"
    label variable `role'_fac_6  "`role': Parental recommendations"
    label variable `role'_fac_7  "`role': Gender composition"
    label variable `role'_fac_8  "`role': Social contact level"
    label variable `role'_fac_9  "`role': Helping others"
    label variable `role'_fac_10 "`role': Workplace type"
    label variable `role'_fac_11 "`role': Contract acquisition likelihood"
    label variable `role'_fac_12 "`role': Promotion prospects"
    label variable `role'_fac_13 "`role': Personal interests"
}
*/

********************************************************************************
// 2.CREATE MOTIVATIONAL FACTOR VARIABLES
*.   a.This is a loop that goes through the motivational factors and
*      This section creates binary (0/1) variables for 13 motivational factors 
*      separately for the child, mother, and father.
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
*.   a. Assign the right labels to the motivational factors for easier understanding
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
