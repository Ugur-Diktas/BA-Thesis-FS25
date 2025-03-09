********************************************************************************
* 5_ps_parents_clean_motivations.do
* --------------------------------------------------------------------------------------------
* Data needed: ps_par_clean_beliefs.dta
* Data output: ps_par_clean_motivations.dta
* Purpose:
* - Process and transform parental motivation factors (analogous to the 
*   students’ motivations processing).
* - It handles both numeric variables (motFactor variables) and string 
*   variables (motFactors_this and motFactors_other) by creating binary
*   indicator variables (fac_1 to fac_13) for each motivational factor.
* - Creates motivational factors per parent type 
*
* Author : Ugur Diktas, Jelke Clarysse, BA Thesis FS25
* Last edit: 03.03.2025
* Version: Stata 18
********************************************************************************

********************************************************************************
* 0. HOUSEKEEPING & LOGGING
********************************************************************************
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
log using "${dodir_log}/5_ps_parents_clean_motivations.log", replace text

timer clear
timer on 1

********************************************************************************
* 1. LOAD THE CLEANED DATA
********************************************************************************
di as txt "----- Loading dataset: ps_par_clean_beliefs.dta -----"
quietly use "${processed_data}/PS_Parents/ps_par_clean_beliefs.dta", clear
di as txt "Loaded ps_par_clean_beliefs.dta: `c(N)' obs, `c(k)' vars"
if _N == 0 {
    di as error "ERROR: No observations in ps_par_clean_beliefs.dta."
    error 601
}
********************************************************************************
* 2. CLEAN MOTIVATIONAL FACTORS 
*.   a. A loop through each factor, factor_this is the parent answering the survey 
*.      and factor_otehr is what they think about the other parent would think
*.   b. we loop through all factors indicating what they are and if they have been selected
********************************************************************************
forval i = 1/12 {
	gen fac_this_`i' = .
	gen fac_other_`i' = .
}

foreach q in "this" "other" {
	forval j = 1/12 {
		replace fac_`q'_1 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der zukünftige <strong>Lohn</strong>"
	}
	forval j = 1/12 {
		replace fac_`q'_2 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die zukünftige berufliche <strong>Flexibilität</strong> (z. B. die Möglichkeit, in Teilzeit zu arbeiten)"
	}
	forval j = 1/12 {
		replace fac_`q'_3 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Möglichkeiten zur <strong>Fort- oder Weiterbildung</strong>"
	}
	forval j = 1/12 {
		replace fac_`q'_4 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>mathematischen</strong> Anforderungen"
	}
	forval j = 1/12 {
		replace fac_`q'_5 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>sprachlichen</strong> Anforderungen"
	}
	forval j = 1/12 {
		replace fac_`q'_6 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>Geschlechterzusammensetzung</strong> im Beruf"
	}
	forval j = 1/12 {
		replace fac_`q'_7 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Das Ausmass an <strong>sozialem Kontakt</strong>"
	}
	forval j = 1/12 {
		replace fac_`q'_8 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Menschen zu <strong>helfen</strong> (z.B. Kunden oder Patienten)"
	}
	forval j = 1/12 {
		replace fac_`q'_9 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Der <strong>Arbeitsort</strong> (z.B. Büro, Aussenbereich, Baustelle)"
	}
	forval j = 1/12 {
		replace fac_`q'_10 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die <strong>Chance</strong>, einen Lehrvertrag zu bekommen"
	}
	forval j = 1/12 {
		replace fac_`q'_11 = 1 if motFactors_`q'_`j' == 1 & motFactor`j' == "Die Aussicht auf <strong>Beförderungen</strong>"
	}
	forval j = 1/12 {
		replace fac_`q'_12 = 1 if motFactors_`q'_`j' == 1 & trim(motFactor`j') == "Ihre persönlichen <strong>Interessen</strong>"
	}
}

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
********************************************************************************
* 3.CREATING NEW VARIABLE THAT INDICATES MOTHER AND FATHER
*.  a.if father or mother is indicated we generate a new variable for each factor 
*.    to clearly indicate which parent answered the question 
********************************************************************************
forval i = 1/12 {
	gen mother_fac_`i' = .
	replace mother_fac_`i' = fac_this_`i' if Parent_type_ == 1
	replace mother_fac_`i' = fac_other_`i' if Parent_type_ == 2
	gen father_fac_`i' = .
	replace father_fac_`i' = fac_this_`i' if Parent_type_ == 2
	replace father_fac_`i' = fac_other_`i' if Parent_type_ == 1
}
********************************************************************************
* 4. ADDING CORRECT LABELING
*.   a.in order to analyse the code more easily, labels are given to the factors
*.     this makes it easeir to read. 
*.   b.we drop the orginal factor variables as we have created new ones
********************************************************************************

forval i = 1/12 {
    local fac_label ""
    if `i' == 1 local fac_label "Salary"
    if `i' == 2 local fac_label "Flexibility"
    if `i' == 3 local fac_label "Further education possibilities"
    if `i' == 4 local fac_label "Math requirements"
    if `i' == 5 local fac_label "Language requirements"
    if `i' == 6 local fac_label "Gender composition"
    if `i' == 7 local fac_label "Social contact"
    if `i' == 8 local fac_label "Helping people"
    if `i' == 9 local fac_label "Type of workplace"
    if `i' == 10 local fac_label "Ability to obtain contract"
    if `i' == 11 local fac_label "Promotion prospects"
    if `i' == 12 local fac_label "Interests"

    label variable fac_this_`i' "`fac_label' (This)"
    label variable fac_other_`i' "`fac_label' (Other)"
    label variable mother_fac_`i' "`fac_label' (Mother)"
    label variable father_fac_`i' "`fac_label' (Father)"
}


*Drop old mot factor variables
drop motFactor* fac_this* fac_other*

********************************************************************************
* 4. FINAL HOUSEKEEPING & SAVE
********************************************************************************
compress
save "${processed_data}/PS_Parents/ps_par_clean_motivations.dta", replace

timer off 1
timer list
log close
