1. Use the do file "0_clean_parent" to clean open field text entries containing (parental) occupation if the goal is to categorize them into isced fields. 

2. The code categorize the uncleaned occupations based on exact matching (e.g. "Lehrer" = 01 isced) or based on a substring of the occupations. 

3. Copy resulting data into excel (see clean_occ.xlxs) and check if assignment makes sense. Some occupations might became overwritten if a substring is contained also in another occupation. That is why the order of the code matters. 

3. Adopt Stata code if a misclassification is structural. For example "it" has to be placed at the beginning of the code because "it" is a ambiguous substring that occurs in several occupation titles. 

4. If only a single occupation is misassigned than create manually a flag (Column F in the excel sheet) with a suggestion containing (column G) the number of the field

5. Sometimes we have multiple occupations per field. As there is no pattern how students indicate the separate occupations, clean it manually. Therefore, new columns are created where the additional occupation is added. After separating the occupation titles, for each occupation a new column is created, where the isced field is added. 

5. Import excel with cleaned entries into stata (see do.file) and replace the erroneous entries (indicated by flag variable)

6. Prepare dataset such that it can be merged with main survey