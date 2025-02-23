********************************************************************************
// 3_ps_students_clean_beliefs.do
// Purpose : Cleans & processes the belief-related questions in the PS Students 
//           dataset. Includes built-in debug steps to handle naming issues.
// 
// Author  : Ugur Diktas_Jelke Clarysse, BA Thesis FS25, 18.02.2025
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 17.0

cap log close
log using "${dodir_log}/ps_students_clean_beliefs.log", replace text

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
// 2. DEBUG STEP 1: RENAMING ESSENTIAL VARIABLES 
********************************************************************************

// RENAME MARRIAGE//

rename marriage_prob_fit_1 marriage_prob_1
rename marriage_prob_fit_2 marriage_prob_2

//RENAME BELIEF//

foreach belief_q_var in "belief_fit" "like_task" {
	forval i = 1/2 {
		rename `belief_q_var'__`i' `belief_q_var'_`i'
	}
}
// RENAME MOTHER AND FATHER APPROVAL// 

//** Here I took the code from Daphne-as mother approval and father approval is not clear 
forval i = 1/2 {
	
	replace mother_approval_1new_`i' = mother_approval_1__`i' if missing(mother_approval_1new_`i')
	replace mother_approval_2new_`i' = mother_approval_2_`i' if missing(mother_approval_2new_`i')
	gen mother_approval_`i' = mother_approval_1new_`i' if !missing(mother_approval_1new_`i')
	replace mother_approval_`i' = mother_approval_2new_`i' if !missing(mother_approval_2new_`i')
	
	replace father_approval_new_`i' = father_approval__`i' if missing(father_approval_new_`i')
	gen father_approval_`i' = father_approval_new_`i'
}

drop mother_approval_1new* mother_approval_2new* mother_approval_1__* mother_approval_2_* father_approval__* father_approval_new*


********************************************************************************
// 4. CLEAN BELIEF VARIABLES
********************************************************************************

*Student's beliefs
loc name_belief_fit "Belief fit"
loc name_like_task "Belief like tasks"
loc name_marriage_prob "Belief marriage probability"
loc name_future_fit "Belief future happiness"

//LOOP THROUGH BELIEF VARIABLE AND ALLOCATES TO CORRECT JOB//

gen traditional_role_3 = ""
gen traditional_role_4 = ""

foreach q_var in belief_fit like_task {
	
	* Belief about fit to same gender occupation/opp gender occupation
	forval j = 2/7 {
		gen `q_var'_occ`j' = .
	}

	lab var `q_var'_occ2 "`name_`q_var'' FaGe"
	lab var `q_var'_occ3 "`name_`q_var'' FaBe"
	lab var `q_var'_occ4 "`name_`q_var'' MPA"
	lab var `q_var'_occ5 "`name_`q_var'' Informatiker/-in"
	lab var `q_var'_occ6 "`name_`q_var'' Konstrukteur/-in"
	lab var `q_var'_occ7 "`name_`q_var'' Polymechaniker/-in" 	
	
	forvalues i = 1/2 {
   
		replace `q_var'_occ2 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Gesundheit (FaGe)" | traditional_role_`i' == "Fachmann Gesundheit (FaGe)"
   
		replace `q_var'_occ3 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Betreuung (FaBe)" | traditional_role_`i' == "Fachmann Betreuung (FaBe)"
   
		replace `q_var'_occ4 = `q_var'_`i' if traditional_role_`i' == "Medizinischer Praxisassistent (MPA)" | traditional_role_`i' == "Medizinische Praxisassistentin (MPA)"
   
		replace `q_var'_occ5 = `q_var'_`i' if traditional_role_`i' == "Informatiker" | traditional_role_`i' == "Informatikerin"
   
		replace `q_var'_occ6 = `q_var'_`i' if traditional_role_`i' == "Konstrukteur" | traditional_role_`i' == "Konstrukteurin"
   
		replace `q_var'_occ7 = `q_var'_`i' if traditional_role_`i' == "Polymechaniker" | traditional_role_`i' == "Polymechanikerin"
	}
	
	drop `q_var'_1 `q_var'_2 
	
}


drop traditional_role_3 traditional_role_4

*Now for vars with only 2 separate vars in dataset
foreach q_var in "marriage_prob" "future_fit" "mother_approval" "father_approval" {
	
	*Belief about fit to same gender occupation/opp gender occupation
	forval j = 2/7 {
		gen `q_var'_occ`j' = .
	}

	lab var `q_var'_occ2 "`name_`q_var'' FaGe"
	lab var `q_var'_occ3 "`name_`q_var'' FaBe"
	lab var `q_var'_occ4 "`name_`q_var'' MPA"
	lab var `q_var'_occ5 "`name_`q_var'' Informatiker/-in"
	lab var `q_var'_occ6 "`name_`q_var'' Konstrukteur/-in"
	lab var `q_var'_occ7 "`name_`q_var'' Polymechaniker/-in" 	
	
	forvalues i = 1/2 {
   
		replace `q_var'_occ2 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Gesundheit (FaGe)" | traditional_role_`i' == "Fachmann Gesundheit (FaGe)"
   
		replace `q_var'_occ3 = `q_var'_`i' if traditional_role_`i' == "Fachfrau Betreuung (FaBe)" | traditional_role_`i' == "Fachmann Betreuung (FaBe)"
   
		replace `q_var'_occ4 = `q_var'_`i' if traditional_role_`i' == "Medizinischer Praxisassistent (MPA)" | traditional_role_`i' == "Medizinische Praxisassistentin (MPA)"
   
		replace `q_var'_occ5 = `q_var'_`i' if traditional_role_`i' == "Informatiker" | traditional_role_`i' == "Informatikerin"
   
		replace `q_var'_occ6 = `q_var'_`i' if traditional_role_`i' == "Konstrukteur" | traditional_role_`i' == "Konstrukteurin"
   
		replace `q_var'_occ7 = `q_var'_`i' if traditional_role_`i' == "Polymechaniker" | traditional_role_`i' == "Polymechanikerin"
	}
	
	
}

********************************************************************************
// 5. LABEL BELIEF VARIABLES
********************************************************************************
// FOR BELIEF FIT, LIKE TASK AND FUTURE FIT//
lab define belief_q_labels 1 "Not at all" 2 "Little" 3 "Moderately" 4 "Well" 5 "Very well"

foreach q_var in "belief_fit" "like_task" "future_fit"{
	forval i = 2/7 {
		lab values `q_var'_occ`i' belief_q_labels
	}
}
//FOR MARRIAGE PROBABILITY//
label define demand_labels 1 "Very unlikely" 2 "Unlikely" 3 "Moderately" 4 "Likely" 5 "Very likely"

foreach q_var in "marriage_prob" {
	forvalues i = 2/7 {
		label values `q_var'_occ`i' demand_labels
	}
}
//APPROVAL PARENTS//
lab define approval_labels 1 "Very sceptical" 2 "Sceptical" 3 "Moderate" 4 "Supportive" 5 "Very supportive"

foreach q_var in "mother_approval" "father_approval" {
	forval i = 2/7 {
		label values `q_var'_occ`i' approval_labels
	}
}

********************************************************************************
// 6.CREATE STANDARADIZED VARIABLES 
*cuurently all Daphne her code, I have no clue why it doesnt work
********************************************************************************
/*
loc name_belief_fit "Average belief fit"
loc name_like_task "Average belief like tasks"
loc name_marriage_prob "Average belief marriage prob"
loc name_future_fit "Average belief future happiness"

lab define belief_qs_ave_lab 2 "Not at all" 3 "Not at all/little" 4 "Little" 5 "Little/moderately" 6 "Moderately" 7 "Moderately/well" 8 "Well" 9 "Well/very well" 10 "Very well"

foreach q_var in "belief_fit" "like_task" "marriage_prob" "future_fit" {
	
	egen `q_var'_fem_ave = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
	egen `q_var'_mal_ave = rowmean(`q_var'_occ5 `q_var'_occ6 `q_var'_occ7)
	
	gen `q_var'_gc_ave = .
	gen `q_var'_gic_ave = .
	
	replace `q_var'_gc_ave = 2*`q_var'_fem_ave if female == 1
	replace `q_var'_gc_ave = 2*`q_var'_mal_ave if female == 0
	
	replace `q_var'_gic_ave = 2*`q_var'_fem_ave if female == 0
	replace `q_var'_gic_ave = 2*`q_var'_mal_ave if female == 1
	
	drop `q_var'_fem_ave `q_var'_mal_ave
	
	lab var `q_var'_gc_ave "`name_`q_var'' to GC occs"
	lab var `q_var'_gic_ave "`name_`q_var'' to GIC occs"
	
	lab values `q_var'_gc_ave belief_qs_ave_lab
	lab values `q_var'_gic_ave belief_qs_ave_lab
	
}

foreach q_var in "mother_approval" "father_approval" {
	
	egen `q_var'_fem_ave = rowmean(`q_var'_occ2 `q_var'_occ3 `q_var'_occ4)
	egen `q_var'_mal_ave = rowmean(`q_var'_occ5 `q_var'_occ6 `q_var'_occ7)
	
	gen `q_var'_gc = .
	gen `q_var'_gic = .
	
	replace `q_var'_gc = `q_var'_fem_ave if female == 1
	replace `q_var'_gc = `q_var'_mal_ave if female == 0
	
	replace `q_var'_gic = `q_var'_fem_ave if female == 0
	replace `q_var'_gic = `q_var'_mal_ave if female == 1
	
	drop `q_var'_fem_ave `q_var'_mal_ave

	lab var `q_var'_gc "`name_`q_var'' for GC occ"
	lab var `q_var'_gic "`name_`q_var'' for GIC occ"
	
	lab values `q_var'_gc approval_labels
	lab values `q_var'_gic approval_labels

}
*/

********************************************************************************
// 7. FINAL HOUSEKEEPING & SAVE
********************************************************************************

di as txt "----- Compressing and saving dataset -----"
compress

save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list

// Turn off trace if you turned it on earlier.
// set trace off

log close

