
/* This do-file
	- takes as input: data with text entries of apprenticeship names (see below for details)
	- checks which apprenticeship names have already been cleaned previously
	- gives you a list of those that still need to be cleaned
	- after you have manually assigned apprenticeship codes to the uncleaned text entries, merges all cleaned apprenticeships with the apprenticeship characteristics data
	- output: (updated) data set "clean apprenticeships.dta" - crosswalk from text entries to apprenticeship codes, official apprenticeship names, and corresponding apprenticeship characteristics
		- example:
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------
		Text entry     				| labb_code_1	| labb_code_2	|	app_official_1				| app_official_2				| app_math_score_1	| app_math_score_2
		-------------------------------------------------------------------------------------------------------------------------------------------------------------------
		I want to do FaGe or FaBe 	| 462800		| 463200		| Fachmann/-frau Gesundheit EFZ	| Fachmann/-frau Betreuung EFZ	| 23.8				| 27.1667					
		KV							| 384350		|				| Kaufmann/-frau EFZ E			|								| 44.8				|

	What your data needs to look like:
		- one variable named "Apprenticeship" that contains potentially uncleaned apprenticeships names
		- no other variables in the data
		
	What else you need to prepare
		- set global appchardir to your path to the apprenticeship characteristics data
			-> e.g.: global appchardir "T:\econ\brenoe\11_yousty\5_ApprenticeshipCharacteristics"
	
	What you need to do:
		- Run this do-file: Sheet 1 in "clean apprenticeships.xlsx" will be updated with your new uncleaned apprenticeships on top
		- Copy all apprenticeships with cleaned = 0 to the bottom of Sheet 2, add the corresponding LABB codes manually
		- Run this do-file again: "clean apprenticeships.dta" will be updated with your apprenticeships. It serves as a crosswalk from uncleaned apprenticeship names to LABB codes (and other apprenticeship characteristics)
		- Now you can merge your data to "clean apprenticeships.dta" to obtain LABB codes and other apprenticeship characteristics for all apprenticeship names in your variable "Apprenticeship"
		
	You can also use this do-file if you have more than one variable with potentially uncleaned apprenticeship names. 
	In example.do you can find an example of how you can include it in your code:
		-> replace var1, var2, ... with the actual names of your variable(s)
		-> replace the global "path" with the actual name of the global you use for the path to the folder in which this do-file is saved

	
*/

********************************************************************************

local path "${dodir_cleaning}/clean_apprenticeships"

********************************************************************************
	
	* Prepare data with skills and female shares (this data is skill data from anforderungsprofile.ch merged with data on female shares from LABB)
	preserve
		use "${appchardir}/skill_intensity_data_with_apprentice_characteristics", clear
		
		replace labb_code = 1000004 if occname_skill == "Solarinstallateur/in EFZ"
		replace labb_code = 1000005 if occname_skill == "Solarmonteur/-in EBA"

		
		drop if missing(labb_code)
		
		drop if labb_code == 384450												// drop old version of KV EBA (Profil B)
		
		* Collapse to LABB code level (replace name with name from skill data if missing)
			* Some occupations are reported not as one occupation but with several entries for each specialization
			* Usually all specialization of the same occupation then have the same LABB code - exception: "Gebäudetechnikplaner"
			* Create new code and assign it to all specializations of "Gebäudetechnikplaner", then collapse by LABB code to have only one observation per occupation
		replace labb_code = 1000002 											///
			if strpos(occname_labb, "Gebäudetechnikplaner/in ")
		replace occname_labb = "Gebäudetechnikplaner/in EFZ" 					///
			if strpos(occname_labb, "Gebäudetechnikplaner/in ")
		egen tag = tag(labb_code)
		bys labb_code: egen nofspecs = total(labb_first)
		bys labb_code: egen total_grad_allspecs = total(total_grad) 			/// sum over numbers of total graduates of all specializations
			if nofspecs > 1
		replace total_grad_allspecs = total_grad if nofspecs == 1
		drop total_grad
		rename total_grad_allspecs total_grad
		bys labb_code: egen flag_total_grad_miss = total(missing(total_grad))	// avoid missing weights
		bys labb_code: replace flag_total_grad_miss = flag_total_grad_miss == _N
		replace total_grad = 1 if flag_total_grad_miss == 1
		collapse 	(mean) skills_ave_math skills_ave_ownlang 					///
					skills_ave_forlang skills_ave_science 						///
					female_grad total_grad expearn								///
					(first) occname_skill occname_labb flag_total_grad_miss		///
			[w=total_grad], by(labb_code)	
		replace total_grad = . if flag_total_grad_miss == 1						// set missing weights to missing again
		drop flag_total_grad_miss
			
		* Compute (weighted) median of language requirements
		su skills_ave_ownlang [w=total_grad], d
		scalar median_lang = r(p50)
		di median_lang
		
		
		* For some occupations name from LABB data is missing -> use name from skill data
		replace occname_labb = occname_skill if missing(occname_labb)
		drop occname_skill
				
		*Add observation for "Entwickler Digitales Business"
			* This is a new apprenticeship that we don't have in our data yet but many students state that they are interested in it
			* We approximate its math requirements and female share by those of "Informatiker" (which is similar)
			* Update: We now have it in our data but all values are missing -> drop it and add new obs with values from Informatiker
		drop if labb_code == 381400
		local nplusone = _N + 1
		set obs `nplusone'
		replace occname_labb = "Entwickler/in Digitales Business EFZ" 			///
			in `nplusone'
		replace labb_code = 1000001 in `nplusone'
		su skills_ave_math if occname_labb == "Informatiker/in EFZ"
		replace skills_ave_math = r(mean) in `nplusone'
		su female_grad if occname_labb == "Informatiker/in EFZ"
		replace female_grad = r(mean) in `nplusone'
		
		* Add additional observations for none / Gymnasium / has contract / unknown apprenticeships from text entries
			* Some students state "None" in the text entry or they say that they are going to go to Gymnasium or already have a contract
			* Others write apprenticeships that we simply don't have in our data (usually very rare ones or it is unclear what they mean)
			* We add observations for this in the apprenticeship characteristics data to facilitate cleaning these entries
		* 1) None / Gymnasium / has contract
		set obs `=_N+3'
		forvalues i = 1/3 {
			replace labb_code = -`i' in `=_N-3+`i''
		}
		replace occname_labb = "None" 			in `=_N-2'
		replace occname_labb = "Gymnasium" 		in `=_N-1'
		replace occname_labb = "Has contract" 	in `=_N'		
		* 2) Unknown apprenticeships
			* They state up to 4 distinct apprenticeships in the text entry -> create 4 different codes such that we can still see that they looked for several different apprenticeships
			* Code is -4 if the first apprenticeship they state is unknown, -5 for the second one, and so on
		set obs `=_N+4'
		forvalues i = 1/4 {
			replace occname_labb = "Unknown(`i')" 	in `=_N-4+`i''
			replace labb_code = -3 - `i' 			in `=_N-4+`i''
		}
		* 3) Unknown non-apprenticeships
		set obs `=_N+1'
		replace occname_labb = "Unknown (no apprenticeship)"	in `=_N'
		replace labb_code = -8 									in `=_N'

		tempfile appchardata
		save `appchardata'
	restore
	
********************************************************************************

	* Keep only first appearance of each name
	bys Apprenticeship: keep if _n == 1
	drop if missing(Apprenticeship)

	* Sort such that names that haven't been cleaned yet are on top
		* For this to work, we need to run code twice and make sure that using file already exists
		* Note that this code creates this using file only later, so before the first time running this code, an empty file needs to be created that is then updated with each time running the code)
	merge 1:1 Apprenticeship using "`path'/clean apprenticeships.dta" 			// merge with list of already cleaned occupation names
	gen cleaned = _merge==3 | _merge==2
	sort cleaned Apprenticeship
	keep Apprenticeship cleaned
	order Apprenticeship cleaned
	keep if cleaned == 0
	tempfile uncleaned
	save `uncleaned'
	
	* Add uncleaned apprenticeship names to sheet 1 of clean apprenticeship excel
	import excel using "`path'/clean apprenticeships.xlsx", 					///
		sheet("Sheet1") firstrow clear
	merge 1:1 Apprenticeship using `uncleaned', nogen update replace
	merge 1:1 Apprenticeship using "`path'/clean apprenticeships.dta", 			/// set cleaned to 1 if they have already been cleaned
		keepusing(Apprenticeship)
	replace cleaned = 1 if _merge == 3
	drop _merge
	sort cleaned Apprenticeship
	export excel using "`path'/clean apprenticeships.xlsx", 					///
		sheet("Sheet1") sheetmodify cell(A1) firstrow(variables) keepcellfmt
			
	* Import cleaned excel file
	import excel "`path'/clean apprenticeships.xlsx", 							///
		sheet("Sheet2") firstrow clear
	keep Apprenticeship labb_code_*
	drop if missing(Apprenticeship)
	
	* Merge with data on skill requirements and female shares
		* They write up to 4 distinct apprenticeships in the text entries
		* File with cleaned apprenticeships contains 4 variables each for LABB code, math requirements, etc.
		* -> merge for each of these 4 variables
	forvalues i = 1/4 {
		rename labb_code_`i' labb_code
		merge m:1 labb_code using `appchardata', 								///
			keep(master match) 													///
			keepusing	(occname_labb skills_ave_math skills_ave_ownlang 		///
						skills_ave_forlang skills_ave_science female_grad		///
						expearn)
		list Apprenticeship labb_code if _merge != 3 & !missing(labb_code) & labb_code > 0
		count if _merge != 3 & !missing(labb_code) & labb_code > 0
		if r(N) > 0 {
		    di "Please check the entries/codes above in the Excel sheet again. There is probably a typo somewhere such that these codes do not match with the apprenticeship characteristics data."
		}
		assert _merge == 3 if !missing(labb_code) & labb_code > 0
		drop _merge
		rename skills_ave_math app_math_score_`i'
		rename skills_ave_ownlang app_lang_score_`i'
		rename skills_ave_forlang app_foreign_score_`i'
		rename skills_ave_science app_science_score_`i'
		rename female_grad app_femshare_`i'
		rename occname_labb app_official_`i'
		rename labb_code labb_code_`i'
		rename expearn app_salary30_`i'
	}
	
	* Categorize math requirements score into high/middle/low
	forvalues i = 1/4 {
		recode app_math_score_`i' 	(0/37.49999 = 1 "low") 						///
									(37.5/58.49999 = 2 "medium") 				///
									(58.5/100 = 3 "high"),						///
			gen(app_math_`i')
		replace app_math_`i' = 1 if labb_code_`i' == 500400						// Fachmann/-frau Betriebsunterhalt EFZ
		replace app_math_`i' = 3 if labb_code_`i' == 287210						// ICT-Fachmann/-frau EFZ
		replace app_math_`i' = 3 if labb_code_`i' == 294560						// Multimediaelektroniker/in EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 373800						// Veranstaltungsfachmann/-frau EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 330800						// Bauwerktrenner/in EFZ
		replace app_math_`i' = 1 if labb_code_`i' == 461700						// Fachmann/-frau Bewegungs- und Gesundheitsförderung EFZ
		replace app_math_`i' = 1 if labb_code_`i' == 442600						// Kosmetiker/in EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 173100						// Textiltechnologe/-technologin EFZ
		replace app_math_`i' = 3 if labb_code_`i' == 482600						// Grafiker/in EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 482100						// Gestalter/in Werbetechnik EFZ
		replace app_math_`i' = 1 if labb_code_`i' == 430400						// Gebäudereiniger/in EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 331200						// Boden-Parkettleger/in EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 321600						// Goldschmied/in EFZ
		replace app_math_`i' = 3 if labb_code_`i' == 350510						// Architekturmodellbauer/in EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 467700						// Medizinproduktetechnolog/in EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 342600						// Theatermaler/in EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 204100						// Verpackungstechnologe/-technologin EFZ
		replace app_math_`i' = 2 if labb_code_`i' == 166600						// Müller/in EFZ
	}
	
	
	* Export data to excel
	order 	Apprenticeship app_official_* labb_code_* app_math_score_* 			///
			app_math_* app_lang_score_* app_foreign_score_*						///
			app_science_score_* app_femshare_* app_salary30_*
	export excel using "`path'/clean apprenticeships.xlsx", 					///
		sheet("Sheet3") sheetmodify cell(A1) firstrow(variables) keepcellfmt
	
	* Save as dta
	save "`path'/clean apprenticeships.dta", replace
	
	
		