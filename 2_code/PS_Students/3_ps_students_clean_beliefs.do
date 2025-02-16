********************************************************************************
// 3_ps_students_clean_beliefs.do
// Purpose : Cleans & processes the belief-related questions in the PS Students 
//           dataset. Includes built-in debug steps to handle naming issues.
// 
// Author  : Ugur Diktas, BA Thesis FS25, 12.02.2025
********************************************************************************

********************************************************************************
// 0. HOUSEKEEPING
********************************************************************************

clear all
set more off
version 17.0

cap log close
log using "${dodir_log}/ps_students_clean_beliefs.log", replace text

// Turn on Stata’s trace for very detailed debugging (comment out if too verbose).
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
// 2. DEBUG STEP: CHECK FOR VARIABLES CONTAINING "belief"
********************************************************************************

di as txt "----- Searching for variables containing 'belief' -----"
ds *belief*
describe *belief*

di as txt "----- Attempting potential rename operations -----"

// Sometimes the raw import might produce names like "belief_fit _1" or "belief_fit__1".
// We'll systematically try to rename any that appear in the data.
capture rename "belief_fit _1"  belief_fit_1
capture rename "belief_fit _2"  belief_fit_2
capture rename "belief_fit__1" belief_fit_1
capture rename "belief_fit__2" belief_fit_2

// If your data has further irregularities (e.g. "like_task _1"), do the same:
capture rename "like_task _1"  like_task_1
capture rename "like_task _2"  like_task_2
capture rename "like_task__1" like_task_1
capture rename "like_task__2" like_task_2

// Examples for mother_approval or father_approval with weird spaces/characters
capture rename "mother_approval_1 _1" mother_approval_1_1
capture rename "mother_approval_1 _2" mother_approval_1_2
capture rename "father_approvalÂ _1"  father_approvalA_1
capture rename "father_approvalÂ _2"  father_approvalA_2

// Example rename for "marriage_prob_fit_1" -> "marriage_prob_1", etc.
capture rename "marriage_prob_fit_1" marriage_prob_1
capture rename "marriage_prob_fit_2" marriage_prob_2
capture rename "future_fit_1"        future_fit_1x
capture rename "future_fit_2"        future_fit_2x

di as txt "----- After rename attempts, listing 'belief*' again -----"
ds *belief*
describe *belief*

********************************************************************************
// 3. DEFINE AND APPLY VALUE LABELS
//    (If any of these already exist, they will be replaced.)
********************************************************************************

capture label define belief_q_labels  1 "Not at all"    ///
                                      2 "A little"      ///
                                      3 "Somewhat"      ///
                                      4 "Well"          ///
                                      5 "Very well", replace

capture label define demand_labels    1 "Very unlikely" ///
                                      2 "Unlikely"      ///
                                      3 "Moderately"    ///
                                      4 "Likely"        ///
                                      5 "Very likely", replace

capture label define approval_labels  1 "Very sceptical" ///
                                      2 "Sceptical"      ///
                                      3 "Moderate"       ///
                                      4 "Supportive"     ///
                                      5 "Very supportive", replace

********************************************************************************
// 4. CLEAN & LABEL BELIEF VARIABLES
********************************************************************************

di as txt "----- Attempting to label 'belief_fit_1' etc. -----"

// Belief Fit
capture label values belief_fit_1 belief_q_labels
capture label var   belief_fit_1 "Belief fit (Question 1)"
capture label values belief_fit_2 belief_q_labels
capture label var   belief_fit_2 "Belief fit (Question 2)"

// Like Task
capture label values like_task_1 belief_q_labels
capture label var   like_task_1 "Belief: Likes tasks (Q1)"
capture label values like_task_2 belief_q_labels
capture label var   like_task_2 "Belief: Likes tasks (Q2)"

// Marriage Probability, Future Fit
capture label values marriage_prob_1 demand_labels
capture label var   marriage_prob_1 "Marriage probability (Version 1)"
capture label values marriage_prob_2 demand_labels
capture label var   marriage_prob_2 "Marriage probability (Version 2)"

capture label values future_fit_1x belief_q_labels
capture label var   future_fit_1x "Future fit (Question 1)"
capture label values future_fit_2x belief_q_labels
capture label var   future_fit_2x "Future fit (Question 2)"

// Mother / Father Approvals (examples)
capture label values mother_approval_1_1 approval_labels
capture label var   mother_approval_1_1 "Mother approval (Block 1, Item 1)"
capture label values mother_approval_1_2 approval_labels
capture label var   mother_approval_1_2 "Mother approval (Block 1, Item 2)"

capture label values father_approvalA_1 approval_labels
capture label var   father_approvalA_1 "Father approval (Item 1)"
capture label values father_approvalA_2 approval_labels
capture label var   father_approvalA_2 "Father approval (Item 2)"

********************************************************************************
// 5. FINAL HOUSEKEEPING & SAVE
********************************************************************************

di as txt "----- Compressing and saving dataset -----"
compress

save "${processed_data}/PS_Students/ps_stu_cleaned.dta", replace

timer off 1
timer list

// Turn off trace if you turned it on earlier.
// set trace off

log close
