
	* replace var1, var2, ... with the actual names of your variable(s)
	* replace the global "path" with the actual name of the global you use for the path to the folder in which this do-file is saved
	
	if c(username) == "lukdie" {
		global appchardir "T:\econ\brenoe\11_yousty\5_ApprenticeshipCharacteristics"	
	}

	if c(username) == "annbre" {
		appchardir "Z:/11_yousty\5_ApprenticeshipCharacteristics"
	}
	
	global path "C:\Users\\`c(username)'\Universität Zürich UZH\Anne Ardila Brenoe2 - 5_TeamBrenøe\1_General\2_KnowledgeBase\Code\clean_apprenticeships"
	
	
	* Generate example data
	clear
	set obs 10
	gen var1 = "test1"
	gen var2 = "test2"
	gen var3 = "test3"

	
	
	foreach var of varlist var1 var2 var3  {
		
		* Remove some common typos
			* - depending on the context, there could be more ways to clean your variable to improve the number of matches with already cleaned text entries -> feel free to add to this
		replace `var' = subinstr(`var', char(10), "", .)						// remove line breaks
		replace `var' = strtrim(`var')											// remove leading and trailing blanks
		replace `var' = stritrim(`var')											// remove double spaces
	
		rename `var' Apprenticeship
		
		tempfile preserve
		save `preserve'	
		
		keep Apprenticeship
		do "${path}\clean apprenticeships.do"
		
		use `preserve', clear
		
		forvalues i = 1/4 {
			
			merge m:1 Apprenticeship using "${path}\clean apprenticeships", 	///
				nogen keep(master match) 										///
				keepusing(	labb_code_`i' app_official_`i' app_math_`i' 		///
							app_math_score_`i' app_lang_score_`i' 				///
							app_femshare_`i' app_salary30_`i')
			foreach usingvar in	labb_code app_official app_math app_math_score 	///
								app_lang_score app_femshare app_salary30 {
				rename `usingvar'_`i' `var'_`usingvar'_`i'
			}						
		}	
		
		rename Apprenticeship `var'

	}
	
	
	