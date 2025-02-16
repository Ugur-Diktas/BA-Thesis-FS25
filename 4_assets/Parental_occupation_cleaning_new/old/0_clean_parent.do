********************************************************************************
/* Clean parentaloccupation titles entered by students in the POF BL survey
********************************************************************************

1)  Assign isced code to occupations
	I use AI to assign the fields: I gave chatgpt a pdf with the isced classifications 
		1.1) I assigned the most common substrings to the appropriate ISCED code 
 			e.g. "Arzt" = "Gesundheit, Pflege.."
		1.2) Create a list of the yet uncategorized occupations 
				keep if missing(isced`p') 
				gduplicates drop
		1.3) Give chatgpt the list of uncategorized occupations and write
			"Please give me stata code where you assign to these entries an isced
			 field. Please return me this as stata code"
			 
2) Validation and manual check
	As soon as all possible occupations are assigned create a unique dataset of 
	parental occupations and copy paste it into an excel (clean_occ.xlxs)
		2.1 Check if there are structural problems (whole groups are inappropiately assigned)
				- if yes, change order of code in this do file 
				- if yes, change the substrings used to assign isced field
		2.2 If an occupation has been misclassified
				- create a column with a flag dummy + suggestion column 
				
3) Merge cleaned data back into stata
	- In excel manually separated occupations are imported now
	- if there is a flag we replace it now in stata
	
4) Create final output = 
	Dataset that can be merged with the survey data
	

*/
******************************************************************************** 
************************************Paths*************************************

local username = c(username)
di "`username'"

if c(username) == "annbre" {
	global root "C\Users\annbre\OneDrive - Universität Zürich UZH\9_PerceptionFit"
}

if c(username) == "hmasse" {
	global root "C:\Users\HMASSE\OneDrive - Universität Zürich UZH\9_PerceptionFit"
	global clean_data "$root\3_Analysis\Code\1_Cleaning\Parental_occupation_cleaning"
}

********************************************************************************
* 1) Assigning isced codes 
********************************************************************************

	use "$root\7_Data\2_Cleandata\bl_recent_clean_final.dta", clear

	keep mother_occ* father_occ* responseid
	keep if !missing(mother_occ) | !missing(father_occ)


	global father ///
		 father_occ father_occ1_isced4_code father_occ1_isced4_name 				///
		 father_occ2_isced4_code father_occ2_isced4_name father_occ3_isced4_code 	///
		 father_occ3_isced4_name father_occ4_isced4_code father_occ4_isced4_name

	global mother ///
		 mother_occ1_isced4_code mother_occ1_isced4_name mother_occ2_isced4_code 	///
		 mother_occ2_isced4_name mother_occ3_isced4_code mother_occ4_isced4_code	///
		 mother_occ mother_occ3_isced4_name mother_occ4_isced4_code mother_occ4_isced4_name
	 
* Clean entries
	gen mother = strlower(mother_occ)
	gen father = strlower(father_occ)


* useful to double check 
* https://uis.unesco.org/sites/default/files/documents/international-standard-classification-of-education-fields-of-education-and-training-2013-detailed-field-descriptions-2015-en.pdf

	* Keep only necessary part 
	keep mother_occ mother_occ1_isced4_code  mother_occ1_isced4_name  ///
		 father_occ father_occ1_isced4_code  father_occ1_isced4_name responseid
		 
	replace mother_occ = lower(mother_occ) 
	replace father_occ = lower(father_occ)

* Create the isced_code variable with default classification
	

foreach p in father_occ mother_occ {
	gen isced`p' = .

	* local p father_occ  // to test it 
* very generic substrings that would overrun other categories
replace isced`p' = 0611 if  strpos(`p', "it")  									// only it would overwrite many other entries but several really have just this occupation  indicated 
replace isced`p' = 1013 if  strpos(`p', "wirtin") 		
replace isced`p' = 0200 if  strpos(`p', "händler") 				

* Handle unknown or unclear occupations with specific codes  // from federico 
replace isced`p' = -14 if strpos(`p', "hausfrau") | ///
							strpos(`p', "haufrau") | ///
                            strpos(`p', "haushalt") | ///
                            strpos(`p', "familie") | ///
							strpos(`p', "hausmutter") 


* replace isced`p' = -15 if strpos(`p', "studium") | ///
                            strpos(`p', "studierende") | ///
                            strpos(`p', "studen") | ///
                            strpos(`p', "studier")
                            
replace isced`p' = -10 if strpos(`p', "spezialisierung") | ///
                            strpos(`p', "weiterbildung")
							
							
replace isced`p' = -2 if strpos(`p', "arbeitet nicht") | ///
						strpos(`p', "arbeitet nicht mehr ") | ///
						strpos(`p', "arbeitlos") | ///
                            strpos(`p', "arbeitslos")
						

						   
* Assign ISCED-F 2013 codes to occupations
* 0322 Library, information and archival studies
replace isced`p' = 0322 if strpos(`p', "dolmet") | ///
                            strpos(`p', "über") | ///
                            strpos(`p', "kommunikat") | ///
                            strpos(`p', "Über") | ///
							strpos(`p', "bibliothek") | ///
                            strpos(`p', "mediothek") | ///
							strpos(`p', "artikel schreib") | ///
							 strpos(`p', "mesmeri")  | ///
							  strpos(`p', "mesm")  | ///
							 strpos(`p', "mesmer") | ///
                            strpos(`p', "sagrist")  | ///
                            strpos(`p', "sigrist")  | ///
							strpos(`p', "pfarre")  | ///
							strpos(`p', "diakon")  | ///
							strpos(`p', "pastor")  | ///
                            strpos(`p', "kirche")  | ///
							strpos(`p', "historiker") | ///
							strpos(`p', "influencer") | ///
                            strpos(`p', "sakristanin")           
							
							
replace isced`p' = 0410 if strpos(`p', "management")       | ///
                            strpos(`p', "managment")           | ///
                            strpos(`p', "manager")             | ///
							 strpos(`p', "maneger")             | ///
                            strpos(`p', "selbständig")         | ///
                            strpos(`p', "selbstständig")       | ///
                            strpos(`p', "eigen")               | ///
                            strpos(`p', "eingensändig")        | ///
							 strpos(`p', "eignestä")        | ///
							 strpos(`p', "firmenin")        | ///
                            strpos(`p', "chef")                | ///
                            strpos(`p', "cfo")                 | ///
							  strpos(`p', "ceo")                 | ///
                            strpos(`p', "unternehmer")       | ///
                            strpos(`p', "regionalleiter")    | ///
                            strpos(`p', "betrieb")             | ///
                            strpos(`p', "leiter")              | ///
							strpos(`p', "geschäftsführ")              | ///
						strpos(`p', "beratung") 	| ///
                         strpos(`p', "berater") 		| ///
						   strpos(`p', "betreu") 		| ///
							strpos(`p', "inhaber")              | ///
                            strpos(`p', "manager")             | ///
							strpos(`p', "director")          | ///
                            strpos(`p', "revisor")             | ///
                            strpos(`p', "finanz")              | ///
                            strpos(`p', "buchhalter")        | ///
                            strpos(`p', "makler")              | ///
                            strpos(`p', "immob")               | ///
							 strpos(`p', "imobil")               | ///
                            strpos(`p', "assistent")           | ///
                            strpos(`p', "konom")              | ///
							strpos(`p', "führt")              | ///
                            strpos(`p', "zoll")                | ///
                            strpos(`p', "vermiet")             | /// 
                            strpos(`p', "export")              | ///
                            strpos(`p', "geld")                | ///
                            strpos(`p', "leit")                | /// 
                            strpos(`p', "schaden spezial")     | /// 
                            strpos(`p', "qualitätprüf")        | /// 
                            strpos(`p', "leier")               | /// 
                            strpos(`p', "portefoiller")     		 | ///  
                            strpos(`p', "broker")              | ///  
							  strpos(`p', "brocker")          	   		| ///  
                            strpos(`p', "allianz")          			| ///  
                            strpos(`p', "unternehm")      				| ///
                            strpos(`p', "stiftungsr")     				| ///
							strpos(`p', "buchhaltung") 					| ///
							strpos(`p', "betriebswirtschafter") 		| ///
                            strpos(`p', "kaufmann") 					| ///
							 strpos(`p', "kaumänn") 					| ///
                            strpos(`p', "kauffrau") 					| ///
							 strpos(`p', "schichtfüh") 					| ///
                            strpos(`p', "versicher") 					| ///
                            strpos(`p', "treuh") 						| ///
                            strpos(`p', "kv") 							| ///
                            strpos(`p', "einkaufsladen kleider") 		| ///
							strpos(`p', "kauf")							 | ///
                            strpos(`p', "disponent") 					| ///
                            strpos(`p', "bank") 						| ///
                            strpos(`p', "versicherung") 				| ///
                            strpos(`p', "rezeption") 					| ///
                            strpos(`p', "administration") 				| ///
							strpos(`p', "buchhalter") 					| ///
                            strpos(`p', "bänker") 						| ///
                            strpos(`p', "kantonal amt") 				| ///
                             strpos(`p', "seketärin") 					| ///
                            strpos(`p', "kaiufm ang") 					| ///
                            strpos(`p', "sekritär")						 | ///
                            strpos(`p', "buchhakterin")  				| ///
                            strpos(`p', "sekret") 						| ///
							 strpos(`p', "sekrät") 						| ///
							strpos(`p', "buchhalter") 					| ///
							strpos(`p', "besizerin enes lagerhauskomplexes") | ///
                            strpos(`p', "bänkerin") 					| ///
                            strpos(`p', "kantonal amt") 				| ///
                            strpos(`p', "seketär") 						| ///
                            strpos(`p', "kaiufm ang") 					| ///
							strpos(`p', "wertpapier")          			 |   ///
							strpos(`p', "wirtschaftspr")          		 |   ///
							strpos(`p', "verwalt")           			|   ///
							strpos(`p', "consult")           			|   ///
							strpos(`p', "controller") 					| ///
                            strpos(`p', "hrfachmann") 					| ///
                            strpos(`p', "head of finance") 				| ///
                            strpos(`p', "investor") 					| ///
                            strpos(`p', "buisness platform administrator") | ///
                            strpos(`p', "geschäftsinhaber")  		| ///
							strpos(`p', "aktuar") 			| ///
                            strpos(`p', "chef")				 | ///
                            strpos(`p', "human resources ubs") | ///
							 strpos(`p', "aussendienst") | ///
                            strpos(`p', "firma") | ///
                            strpos(`p', "firma mann") | ///
                            strpos(`p', "firma inhaber") | ///
                            strpos(`p', "firmen inhaber") | ///
                            strpos(`p', "fundraiser") | ///
                            strpos(`p', "chief of staff roche") | ///
                            strpos(`p', "bussnes analist") | ///
                            strpos(`p', "entrepreneur") | ///
							strpos(`p', "betrugkämpfung")  | ///
							strpos(`p', "konsulent")  | ///
							strpos(`p', "risiko menacher")  | ///
							strpos(`p', "lehrmeister")  | ///
							strpos(`p', "business partner")  | ///
                            strpos(`p', "buchhakter")
							
* 0811 Crop and livestock production
replace isced`p' = 0811 if strpos(`p', "agronom") | ///
                            strpos(`p', "oenolog") | ///
							strpos(`p', "winz") | ///
							strpos(`p', "wein") | ///
							strpos(`p', "landwirt") | ///
                            strpos(`p', "bäuer") | ///
                            strpos(`p', "winzer") | ///
							strpos(`p', "bauer") | ///
							strpos(`p', "lantwirt") | ///
							strpos(`p', "gärtner") | ///
                            strpos(`p', "landschaftsgärtner") | ///
							strpos(`p', "förster") | ///
                            strpos(`p', "forstwart") | ///
							strpos(`p', "fischspezialist") | /// 
                            strpos(`p', "landwirtschaft") 

* 0413 Management and administration
replace isced`p' = 0413 if strpos(`p', " hr")                 |   ///
                            strpos(`p', "h r")                 |   ///
							strpos(`p', "hr specialist")                 |   ///
                            strpos(`p', "personal")            |   ///
                            strpos(`p', "marketing")           |   ///
							strpos(`p', "gemeindepräsident") | ///
                            strpos(`p', "führungsfachmann") | ///
							strpos(`p', "grupe") | ///
							strpos(`p', "lehrmeister") | ///
							strpos(`p', "parketleger") | ///
							strpos(`p', "projekt planner") | ///
                            strpos(`p', "projektmangement") | ///
							strpos(`p', "prorecktor") | ///
							strpos(`p', "projekt planner") | ///
                            strpos(`p', "projektmangement")  | ///
							strpos(`p', "prorecktor")   | ///
							strpos(`p', "immobilienbewirtschafte")   | ///
							strpos(`p', "head markom") 

* 0415 Secretarial and office work
replace isced`p' = 0415 if strpos(`p', "verwaltung") | ///
                            strpos(`p', "büro") | ///
							 strpos(`p', "buro") | ///
                            strpos(`p', "angestel") | ///
                            strpos(`p', "angesellte") | ///
                            strpos(`p', "assisten") | ///
                            strpos(`p', "asissten") | ///
                            strpos(`p', "amgestell") | ///
                            strpos(`p', "angstell")   | ///  also very generic 
                            strpos(`p', "sekretär")  | ///  
                            strpos(`p', "sachbearb")  | ///  
                            strpos(`p', "sachbera")  | ///  
                            strpos(`p', "kommunikation")  | ///  
                            strpos(`p', "mitarbeiter")  | ///
                            strpos(`p', "gemeindear") | ///
                            strpos(`p', "securit") | ///
                            strpos(`p', "sicherheit") | ///
                            strpos(`p', "stadt")  | ///
							strpos(`p', "gewerkschaftssekräter") | ///
                            strpos(`p', "er war telefonist")  | ///
							strpos(`p', "schadenexperte") | ///
							strpos(`p', "magaziner") | ///
							strpos(`p', "materialwart") | ///
							strpos(`p', "kontikteur") | ///
							strpos(`p', "lieferant") | ///
							strpos(`p', "liferant") | ///
							strpos(`p', "liferant") | ///
							strpos(`p', "lagerist") | ///
							strpos(`p', "schadenexperte")  | ///
							strpos(`p', "arbeitslosenkasse")  | ///
							strpos(`p', "kanton")  | ///
							strpos(`p', "stellvertre")  
							
							
* 01 Education Education science (positioned after 04 block as many substrings would overwrite categories from following blocks)
	replace isced`p' = 0111 if strpos(`p', "lehre") |  ///
								strpos(`p', "leher") | ///
								strpos(`p', "lehri") | ///
								strpos(`p', "lehrp") |  ///
								strpos(`p', "pädagog")| ///
								strpos(`p', "pädegog") | ///
								strpos(`p', "logop") | ///
								strpos(`p', "schul") | /// 
								strpos(`p', "Schul") | /// 
								strpos(`p', "spielgruppe") | /// 
								strpos(`p', "dozen") | ///
								strpos(`p', "hort") | ///
								strpos(`p', "klasse") | ///
								strpos(`p', "klassn") | ///
								strpos(`p', "ausbild") | ///
								strpos(`p', "bildner") | ///
								strpos(`p', "sekundar") | ///
								strpos(`p', "heilp") | ///
								strpos(`p', "katechet") | ///  
								strpos(`p', "kathechet") | /// 
								 strpos(`p', "kindergärtner") | ///
								strpos(`p', "erzieher") | ///
								strpos(`p', "kleinkinderzier") | ///  
								strpos(`p', "ektor") | ///  
								strpos(`p', "direktor")          | ///   
								strpos(`p', "lehrerassistentin im kindergarten")          | ///
								strpos(`p', "an der uzh")   					| ///
								strpos(`p', "kleinkindeeziher") 				| ///
							strpos(`p', "profes")   							| ///
							strpos(`p', "universität")   						| ///
                            strpos(`p', "issensschaft")  						// wissenschaft


* 0211 Audio-visual techniques and media production
replace isced`p' = 0211 if strpos(`p', "journalist") | ///
                            strpos(`p', "kommunikation") | ///
							strpos(`p', "schreiber") | ///
							 strpos(`p', "zeitrschrift") | ///
							 strpos(`p', "journalist") | ///
                            strpos(`p', "artikel für eine zeitschrift korrigieren") | ///
                            strpos(`p', "exterin") | ///
							strpos(`p', "redaktor") | ///
                            strpos(`p', "medien")   | ///
							strpos(`p', "unterhaltsdienst")    | ///
							strpos(`p', "graphic") | ///
							strpos(`p', "grafi") | ///
							strpos(`p', "designer") | /// 
							strpos(`p', "dessigner") | ///
                            strpos(`p', "fotograf") | ///
                            strpos(`p', "webdesigner") | ///
                            strpos(`p', "polygraf") | ///
							strpos(`p', "editor") | ///
							strpos(`p', "erbedienst")  | /// werbedienst? 
							strpos(`p', "multimediaproducer")  | ///
							strpos(`p', "kino")  | ///
							strpos(`p', "zeichner") 


* 0212 Fashion, interior and industrial design
replace isced`p' = 0212 if strpos(`p', "theater") | ///
							strpos(`p', "schauspiel") | ///
                            strpos(`p', "creative director") | ///
							strpos(`p', "maler") | ///
                            strpos(`p', "keramik") | ///
                            strpos(`p', "textil") | ///
                            strpos(`p', "näherin") | ///
                            strpos(`p', "schneider") | ///
							 strpos(`p', "inendekor") | ///
                            strpos(`p', "wohntextil") 
							

* 0214 Handicrafts
replace isced`p' = 0214 if strpos(`p', "künstler") | ///
                            strpos(`p', "restaurator") | ///
                            strpos(`p', "typograf") | ///
                            strpos(`p', "tepichdoktor") | ///
							strpos(`p', "keramik") | ///
                            strpos(`p', "malerin") | ///
							 strpos(`p', "flori") | ///
							strpos(`p', "goldschmiedemeister") | ///
							strpos(`p', "handwerklich") | ///
                            strpos(`p', "hundefriseur")  
							

* 0215 Music and performing arts
replace isced`p' = 0215 if strpos(`p', "musiker") | ///
                            strpos(`p', "tanzen") | ///
							strpos(`p', "kunst") | ///
							strpos(`p', "dj") 
                

* 0416 Wholesale and retail sales
replace isced`p' = 0200 if strpos(`p', "verkauf") | ///  0416 isced class != 6 cat
							strpos(`p', "verkeuf") | ///
							strpos(`p', "käufe") | ///
                            strpos(`p', "sale") | ///
                            strpos(`p', "merchandising") | ///
                            strpos(`p', "detailhandel") | ///
							strpos(`p', "detailh") | ///
							strpos(`p', "deteih") | ///
							strpos(`p', "deteihä") | ///
							strpos(`p', "detialhande") | ///
							 strpos(`p', "verkÄufer") | ///
							strpos(`p', "werbung austeile") | ///
							strpos(`p', "logistik") | ///
                            strpos(`p', "möbelverkäufer") | ///
                            strpos(`p', "sportartikel verkäufer")  | ///
                            strpos(`p', "zalando versandt")  | /// 
							strpos(`p', "verkäuf") | ///
                            strpos(`p', "detailhandel") | ///
							strpos(`p', "laden besitzer") | ///
                            strpos(`p', "sie hat in coop gearbeitet") | ///
                            strpos(`p', "detailfachmann") | ///
                            strpos(`p', "deteeilhandel") | ///
                            strpos(`p', "buchhändle") | ///
                            strpos(`p', "arbeitet in einem laager") | ///
							strpos(`p', "möbelverkäuver") | ///
							strpos(`p', "laden besitzer") | ///
                                 strpos(`p', "sie hat in coop gearbeitet") | ///
                                 strpos(`p', "detailfachmann") | ///
                                 strpos(`p', "deteeilhandel") | ///
                                 strpos(`p', "kassierer") | ///
                                 strpos(`p', "detaihandel") | ///
                                 strpos(`p', "detailhandek") | ///
                                 strpos(`p', "detailhändler") | ///
                                 strpos(`p', "verkäferin") | ///
                                 strpos(`p', "verkäuderin") | ///
								 strpos(`p', "spar") | ///
							strpos(`p', "migro") | ///
							strpos(`p', "coop") | ///
							strpos(`p', "fachfrau")           	| ///
                            strpos(`p', "verköuferin confiserie") | ///
							strpos(`p', "ferkeufer") | ///
                            strpos(`p', "deteilhandelfachmann") | ///
                            strpos(`p', "deteilhandelsfachmann")  | ///
							strpos(`p', "detailhandel")  | ///
							strpos(`p', "magaziner")  | ///
							strpos(`p', "materialwart")  | ///
							strpos(`p', "kontikteur")  | ///
							strpos(`p', "lieferant")  | ///
							strpos(`p', "lagerist")  | ///
							strpos(`p', "lindt sprüngli") | ///
							strpos(`p', "er war sterilisation mann im hirslanden") | ///
                            strpos(`p', "papeteristin")


* 0421 Law
replace isced`p' = 0421 if strpos(`p', "anwalt") | ///
                            strpos(`p', "anwält") | ///
                            strpos(`p', "jurist") | ///
							 strpos(`p', "jourist") | ///
							  strpos(`p', "justiz") | ///
                            strpos(`p', "steuerberater")
							
* 0914 Medical diagnostic and treatment technology  
replace isced`p' = 0914 if strpos(`p', "arzt") | ///
                            strpos(`p', "arz") | ///
                            strpos(`p', "artz") | ///
                            strpos(`p', "ärz") | ///
                            strpos(`p', "Ärt") | ///
                            strpos(`p', "neuro") | ///
							 strpos(`p', "Ärz") | ///
                            strpos(`p', "radiolog") | ///
							 strpos(`p', "chirurg") | ///
							 strpos(`p', "chirug") | ///
							 strpos(`p', "orthop") | ///
                            strpos(`p', "medizin") | ///
                            strpos(`p', "rettungssaniteter") | ///
                            strpos(`p', "radiolog") | ///
							strpos(`p', "kardiolo") | ///
							strpos(`p', "dermat") | ///
                            strpos(`p', "klinisch") | ///
                            strpos(`p', "spital") | ///
                            strpos(`p', "mtra") | ///
                            strpos(`p', "aneste") | ///
                            strpos(`p', "anästhe") | ///
                            strpos(`p', "physiolog") |  ///
                            strpos(`p', "pharma")  | ///
							 strpos(`p', "apote")  | ///
                            strpos(`p', "psych")  | ///  
                            strpos(`p', "pysich")  | ///  
							  strpos(`p', "physio")  | ///  
                            strpos(`p', "rettung")  | ///  
                            strpos(`p', "medikamente")  | ///  
                            strpos(`p', "homeo")  | ///   
                            strpos(`p', "depuy synthes")  | ///
							strpos(`p', "mpa") | ///
							strpos(`p', "mph") | ///
                            strpos(`p', "optiker") | ///
							 strpos(`p', "optikter") | ///
                            strpos(`p', "feinwerk optiker") | ///
							 strpos(`p', "optiker") | ///
                            strpos(`p', "kieferorthopäd") | ///
                            strpos(`p', "augenoptiker") | ///
                            strpos(`p', "podolog") | ///
							strpos(`p', "doctor") | ///
                            strpos(`p', "rheumatologe") | ///
							 strpos(`p', "optometrist") | ///
							 strpos(`p', "johnsen and johnsean") | ///
                            strpos(`p', "sportler") | ///
							strpos(`p', "profi fussballer")  | ///
                            strpos(`p', "fitne") | ///
                            strpos(`p', "schwimm") | ///
                            strpos(`p', "cytometry facility")  | ///
                            strpos(`p', "trainer") 

* 051 Science
replace isced`p' = 051 if  strpos(`p', "biolo")   | ///
                            strpos(`p', "geolo")   | ///
                            strpos(`p', "labor")   | ///
                            strpos(`p', "physik")   | ///
							strpos(`p', "chemikan") | ///
							strpos(`p', "chemiologe") | ///
                            strpos(`p', "hydrolog")  | ///
							strpos(`p', "mathem") 
* 0611 Computer use
replace isced`p' = 0611 if strpos(`p', "qa engineer") | ///
                            strpos(`p', "technis") | ///
							strpos(`p', "applikation") | ///
							strpos(`p', "informatik") | ///
							strpos(`p', "software") | ///
							strpos(`p', "entwickler") | ///
							strpos(`p', "programmierer") | ///
							strpos(`p', "website") | ///
                            strpos(`p', "ict") | /// 
							strpos(`p', "it projektleiter") | ///
							strpos(`p', "it logistic management") | ///  
							strpos(`p', "it ressource manager") | /// 
                            strpos(`p', "it bereich")  | ///
							strpos(`p', "informatiker") | ///
                            strpos(`p', "systemadministrator") | ///
                            strpos(`p', "systemanalytiker") | ///
							strpos(`p', "mediamatiker") | ///
                            strpos(`p', "kundenbefragung sbb")

* 0613 Software and applications development and analysis
replace isced`p' = 0613 if strpos(`p', "software") | ///
							strpos(`p', "elektriker") | ///	
                            strpos(`p', "sanitär")  | ///
							strpos(`p', "infomatiker")  | ///
							strpos(`p', "imofatiker")  | ///
							strpos(`p', "informtiker")  | ///
							strpos(`p', "bolimech") | ///
                            strpos(`p', "polimechaniker") | ///
							 strpos(`p', "polzme") | ///
							strpos(`p', "poly") | ///
                            strpos(`p', "polymechaner") | ///
							strpos(`p', "infotmatiker") | ///
                            strpos(`p', "telematiker") | ///
							strpos(`p', "produkt developer") | ///
                            strpos(`p', "telekommunikation")
							
							

* 0711 Chemical engineering and processes
replace isced`p' = 0711 if strpos(`p', "lebensmittelinginieur") | ///
                            strpos(`p', "metrohm") | ///
                            strpos(`p', "bioanalytiker")  | ///
                            strpos(`p', "lebensmitteltechnolog") | ///      
							strpos(`p', "chemike") | ///				
							strpos(`p', "milchtechnolog") | ///
                            strpos(`p', "verpacker")


* 0713 Electricity and energy
replace isced`p' = 0713 if strpos(`p', "elektro") | ///
							strpos(`p', "reperateur") | ///
							strpos(`p', "el ing htl") | ///
                            strpos(`p', "elektoingunier") | ///
                            strpos(`p', "elektoinstalateur") | ///
                            strpos(`p', "elektoistalatoer") | ///
                            strpos(`p', "gebäude automation") | ///
                            strpos(`p', "heizwerkführer") | ///
							strpos(`p', "stromer") | ///
                            strpos(`p', "energie")

* 0715 Mechanics and metal trades
replace isced`p' = 0715 if strpos(`p', "maschinen") | ///
                            strpos(`p', "monteur") | ///
                            strpos(`p', "montag") | ///
							strpos(`p', "mondag") | ///
                            strpos(`p', "produktion") | ///
                            strpos(`p', "abrik") | ///    Fabrik
							strpos(`p', "polymechaniker") | ///
                            strpos(`p', "konstrukteur") | ///
                            strpos(`p', "cnc maschine") | ///
                            strpos(`p', "kontroleur") | /// 
							strpos(`p', "polymechaniker") | ///
                            strpos(`p', "maschinen") | ///
                            strpos(`p', "konstrukteur") | ///
                            strpos(`p', "löter") | ///
							strpos(`p', "bolimech") | ///
                            strpos(`p', "polimechaniker") | ///
							strpos(`p', "mechaniker") | ///
							strpos(`p', "mechatroniker") | ///
							strpos(`p', "automobil") | ///
							strpos(`p', "schlosser") | ///
							strpos(`p', "industrie") | ///
							strpos(`p', "technologe") | ///
							strpos(`p', "cnc") | ///
							strpos(`p', "maschinist") | ///
							strpos(`p', "werkzeugmach") | ///
                            strpos(`p', "polymechaner") | ///
							strpos(`p', "bodenleger") | ///
                            strpos(`p', "kranführer") | ///
                            strpos(`p', "schweisser") | ///
                            strpos(`p', "schweissfachmann") | ///
                            strpos(`p', "steinmetz") | ///
                            strpos(`p', "spengler") | ///
							strpos(`p', "anlageführer") | ///
                            strpos(`p', "autolakierer") | ///
                            strpos(`p', "mechanisch")  | ///
							strpos(`p', "anlagenfphree") | ///
                            strpos(`p', "anlagenführer") | ///
                            strpos(`p', "anlagenwart") | ///
							  strpos(`p', "anlagewart") | ///
                            strpos(`p', "anwendungstechnuker") | ///
							strpos(`p', "auto prüfer") | ///
                            strpos(`p', "automatiker") | ///
                            strpos(`p', "automatiker/in efz") | ///
                            strpos(`p', "automechantroniker") | ///
                            strpos(`p', "fachmann operationstechnick") | ///
                            strpos(`p', "garagist") | ///
							strpos(`p', "camuinist") | ///
                            strpos(`p', "cantonier") | ///
                            strpos(`p', "maschienenbediener") | ///
							strpos(`p', "machinenführ") | ///
                            strpos(`p', "mechankär") | ///
                            strpos(`p', "scheiner") | ///
                            strpos(`p', "schweiser") | ///
                            strpos(`p', "schärfer") | ///
                            strpos(`p', "klärwerkfachmann") | ///
                            strpos(`p', "klärwärter") | ///
                             strpos(`p', "treiber") | ///
							 strpos(`p', "rohrverleger") | ///
							 strpos(`p', "klebepraktiker") | ///  
							 strpos(`p', "lüftungsanlagebauer") | ///
							 strpos(`p', "maler") | ///
                            strpos(`p', "kunstofftechnologim")
							

* Food processing
replace isced`p' = 0721 if	strpos(`p', "bäkerin") | ///
                            strpos(`p', "metzger") | ///
                            strpos(`p', "konditeur") | ///
                            strpos(`p', "bäckkonditer") | ///
							strpos(`p', "bäker") | ///
							strpos(`p', "bekerei") | ///
							strpos(`p', "bäckkonditor") | ///
							strpos(`p', "bäck") | ///
							strpos(`p', "brauer") | ///
							strpos(`p', "sie arbeitet in ein bäckerrei") | ///
							strpos(`p', "molkerei") | ///
							strpos(`p', "käser") | ///
							strpos(`p', "charcuterie") | ///
							strpos(`p', "geflügel fachman") | ///
							strpos(`p', "fleischfach mann") | ///
                            strpos(`p', "fleischfachmann") 

* 0722 Materials (glass, paper, plastic and wood)
replace isced`p' = 0722 if strpos(`p', "ingenieur") | ///
							strpos(`p', "engineer") | ///
                            strpos(`p', "ingineu") | ///
							strpos(`p', "ingén") | ///
							strpos(`p', "enginieur") | ///
							strpos(`p', "ingeneu") | ///
							strpos(`p', "ingenier") | /// 
							strpos(`p', "engine") | ///
							strpos(`p', "ingineneur") | ///
							strpos(`p', "inginéneur") | ///
                            strpos(`p', "technik") | ///
                            strpos(`p', "fabrik") | ///
                            strpos(`p', "gieser") | ///
                            strpos(`p', "alupak") | ///
							strpos(`p', "metal") | ///
                            strpos(`p', "verpackungsingeneur") | ///
							strpos(`p', "abpacker") | ///
							strpos(`p', "platten") | ///
							strpos(`p', "glasbläser") | ///
                            strpos(`p', "bernina") | ///
							strpos(`p', "qualitätssicherung") | ///
                            strpos(`p', "matrialprüfer")  | ///
							strpos(`p', "textiltechnolog") | ///
							strpos(`p', "schreiner") | ///
							strpos(`p', "uhrmacher")  | ///
                            strpos(`p', "glaser") | ///
                            strpos(`p', "gussformer")  | ///
							strpos(`p', "parketleger") | ///
							strpos(`p', "platenleger") | ///
							strpos(`p', "holzhandel") | ///
							strpos(`p', "recyceln") | ///
							strpos(`p', "verpackung")  | ///
							strpos(`p', "tablettenpackungen herstellen") | ///
							strpos(`p', "eidgenössisch diplomierter hufschmiedemeister") | ///
                            strpos(`p', "druck")

* 0731 Architecture and town planning
replace isced`p' = 0731 if strpos(`p', "archi")  | ///
							strpos(`p', "arkitekt") | ///
							strpos(`p', "zeichner") | ///
							strpos(`p', "planer") | ///
							strpos(`p', "geomatiker") | ///
                            strpos(`p', "raumplaner") | ///
                            strpos(`p', "zeichnen")

* 0732 Building and civil engineering
replace isced`p' = 0732 if strpos(`p', "bau") | ///
                            strpos(`p', "statpläner") | ///
							strpos(`p', "zimmerfrau") | ///
							strpos(`p', "zimmermann") | ///
                            strpos(`p', "plattenleger") | ///
							strpos(`p', "gipser") | ///
							strpos(`p', "maurer") | ///
							strpos(`p', "platten") | ///
							strpos(`p', "flachdach") | ///
							strpos(`p', "abdichter") | ///
							strpos(`p', "fassaden") | ///
							strpos(`p', "dachdeck") | ///
							strpos(`p', "strassen") | ///
							strpos(`p', "mauer") | ///
                            strpos(`p', "installateur") | ///
							 strpos(`p', "intolateur") | ///
                            strpos(`p', "lüftungsisolateur") | ///
                            strpos(`p', "konstruktor") | ///
							strpos(`p', "betontrennfachmann") | ///
                            strpos(`p', "zimmerman")  | ///
							strpos(`p', "beton trenn fachman") | ///
                            strpos(`p', "boden leger") | ///
                            strpos(`p', "brunnenmeister") | ///
                            strpos(`p', "fliessenleger") | ///
                            strpos(`p', "eisenleger") | ///
							 strpos(`p', "murer")  | ///
							 strpos(`p', "mühler")  | ///
							 strpos(`p', "weber")  | ///
                            strpos(`p', "landerwerber")

* 0911 Dental studies
replace isced`p' = 0911 if strpos(`p', "denta") | ///
                            strpos(`p', "zahn") 

* 0913 Nursing and midwifery
replace isced`p' = 0913 if strpos(`p', "pflege") | ///
                            strpos(`p', "pfege") | ///
                            strpos(`p', "pfleg") | ///
                            strpos(`p', "pfel") | ///
                            strpos(`p', "schwester") | ///
                            strpos(`p', "krankenschwester") | ///
                            strpos(`p', "pfleger") | ///
                            strpos(`p', "akupunktur") | ///
                            strpos(`p', "therap") | ///
                            strpos(`p', "mass") | ///
                            strpos(`p', "masie") | ///
                            strpos(`p', "spitex") | ///
                            strpos(`p', "amme") | ///
                            strpos(`p', "hebame") | ///
                            strpos(`p', "mütterberatung") | ///
							strpos(`p', "betreuung") | ///
							strpos(`p', "fage") | ///
							strpos(`p', "saniter") | ///
							strpos(`p', "sanitäter") | ///
                            strpos(`p', "saal dinst im altersheim") | ///
							strpos(`p', "gesundheit") | ///
                            strpos(`p', "apotheke") | ///
                            strpos(`p', "drogist") | ///
                            strpos(`p', "pflege") | ///
							strpos(`p', "spitegs") | ///
                            strpos(`p', "fag im altersheim") | ///
                            strpos(`p', "krank")

* 0841 Veterinary
replace isced`p' = 0841 if strpos(`p', "tier") | ///   has to be placed after arzt as tierarzt gets overruled
                            strpos(`p', "veterinär") 

* 0923 Social work and counselling
replace isced`p' = 0923 if strpos(`p', "sozial") 		| ///
							strpos(`p', "sozealar") 	| ///
                            strpos(`p', "berufsberater") | ///
                            strpos(`p', "berufsbild") 	| ///
                            strpos(`p', "kjpd") 		| ///   Kinder- und Jugendpsychiatrischer Dienst
                            strpos(`p', "föderung") 	| ///
                            strpos(`p', "sotzial") 		| ///
                            strpos(`p', "immigrat") 	| ///              
                            strpos(`p', "mental") 		| ///  
                            strpos(`p', "coach")  		| ///  
							strpos(`p', "betreu") 		| ///
                            strpos(`p', "kinder") 		| ///
                            strpos(`p', "fabe") 		| ///
							strpos(`p', "ags") 			| ///   // assistent gesundheit & soziales 
                            strpos(`p', "beutreung") 	| ///
                            strpos(`p', "sie arbeitet in alternshein") | ///
							strpos(`p', "eingliderungsfachmann") | /// // Social integration work
							strpos(`p', "dvs") | /// // Social work counselling
							strpos(`p', "bei der aoz") | /// // Social work and counselling
							strpos(`p', "pfänder") | ///
							strpos(`p', "eingliederungsspezialist") | ///
                            strpos(`p', "asyl") 
							
* 1011 Domestic services
replace isced`p' = 1011 if strpos(`p', "spielgr") | ///
							 strpos(`p', "reinigungskraft") | ///
							 strpos(`p', "reinigunskr") | ///
							 strpos(`p', "reinikungskra") | ///
							  strpos(`p', "wäsch") | ///
							  strpos(`p', "hausdienst") | ///
							 strpos(`p', "putzmann") | ///
							 strpos(`p', "reinigung") | ///
							 strpos(`p', "hauswart") | ///
							 strpos(`p', "abwart") | ///
							 strpos(`p', "reiniger") | ///
							 strpos(`p', "textilreini") | ///
                             strpos(`p', "putzfrau") | ///
							 strpos(`p', "tagesmutter") | ///
							 strpos(`p', "familienhelfer") | ///
							  strpos(`p', "haushälter") | ///
							 strpos(`p', "hausfrau bei reichen Leuten") | ///
                             strpos(`p', "hauswart")  | ///
                             strpos(`p', "nanny")  | /// 
							 strpos(`p', "putz") | ///
                             strpos(`p', "reinigung") | ///
                             strpos(`p', "zimmermädchen") | ///
							 strpos(`p', "gebäudereiniger") | ///
                             strpos(`p', "abwart") | ///
                             strpos(`p', "kaminfeger") | ///
                             strpos(`p', "reinigugskraft") | ///
                             strpos(`p', "hauswärtin") | ///
                             strpos(`p', "gebäudereinoger")  | ///
                             strpos(`p', "wäscherei") | ///
							strpos(`p', "coiffeuse") | ///
							strpos(`p', "couiff") | ///
							strpos(`p', "couf") | ///
							strpos(`p', "koiff") | ///
							strpos(`p', "coiffeuse") | ///
							strpos(`p', "make up artist") | ///
							strpos(`p', "hairstylist") | ///
							strpos(`p', "kosmetiker") | ///
							strpos(`p', "kosmetik") | ///
							strpos(`p', "hairst") | ///
							strpos(`p', "kosmetik") | ///
							strpos(`p', "coif") | ///
							strpos(`p', "housekeeper") | ///
                            strpos(`p', "putmann")  | ///
							strpos(`p', "friseu")
	
* 1013 Hotel, restaurants and catering
replace isced`p' = 1013 if strpos(`p', "koch") 									| ///
							strpos(`p', "köch") 								| ///
                            strpos(`p', "gastronomie") 							| ///
							strpos(`p', "gastro") 								| ///
							strpos(`p', "buffet") 								| ///
                            strpos(`p', "restaurant") 							| ///
                            strpos(`p', "gastfreundschaft") 					| ///
							 strpos(`p', "reiseführ") 							| ///
                            strpos(`p', "hotel")  								| ///
                            strpos(`p', "touri")  								| ///
                            strpos(`p', "guest")  								| ///  
							strpos(`p', "kellner") 								| ///
							strpos(`p', "kelner") 								| ///
                            strpos(`p', "gastronom") 							| ///
                            strpos(`p', "service") 								| ///
                            strpos(`p', "barista")  							| ///
                            strpos(`p', "barbes")  								| ///
							strpos(`p', "küche") 								| ///
                            strpos(`p', "servi") 								| ///
							strpos(`p', "mcdonald arbeiter") 					| ///
                            strpos(`p', "empfangsdame") | ///
                            strpos(`p', "dönerfrau") | ///
                            strpos(`p', "in einem restorand") | ///
                            strpos(`p', "in einem altersheim die kantine")  | ///
                            strpos(`p', "pizzaiolo") | ///
                            strpos(`p', "gastronom") | ///
							strpos(`p', "bademeister")  | ///
							strpos(`p', "grilleur") | ///
                            strpos(`p', "hottelier") | ///
							strpos(`p', "kuchenhilfe, teller waschen") | ///
                            strpos(`p', "bar")

* Security services 
replace isced`p' = 1041 if 	strpos(`p', "poliz")               |   ///
							strpos(`p', "feuerwe")             |   ///
                            strpos(`p', "militär")             |   ///
							strpos(`p', "portier")             |   ///
							  strpos(`p', "wachmann")          
							  
* 1041 Transport services
replace isced`p' = 1041 if strpos(`p', "flug") | ///
                            strpos(`p', "fluf") | ///
                            strpos(`p', "reisebegleiter") | ///
                            strpos(`p', "flight") | ///
                            strpos(`p', "chauffeuse") | ///
							 strpos(`p', "chauffeu") | ///
							 strpos(`p', "chaffe") | ///
							  strpos(`p', "cheuffe") | ///
							   strpos(`p', "chaff") | ///
								strpos(`p', "chuffe") | ///
							strpos(`p', "choffe") | ///
							  strpos(`p', "schofö") | ///
                            strpos(`p', "Schulbusschoförer") | ///
							strpos(`p', "logistiker") | ///
                            strpos(`p', "postbote") | ///
                            strpos(`p', "post verteiler") | ///
                            strpos(`p', "sky guide")   | ///
							strpos(`p', "post") | ///
                            strpos(`p', "warenverteilzentrum") | ///
							strpos(`p', "transport") | ///
							strpos(`p', "bus fahr") | ///
							strpos(`p', "busfahr") | ///
							strpos(`p', "bus sch") | ///
							strpos(`p', "tram") | ///
							strpos(`p', "taxi") | ///
							strpos(`p', "lokführer") | ///
							strpos(`p', "lockführer") | ///
							strpos(`p', "lokomot") | ///
							strpos(`p', "lkw") | ///
							strpos(`p', "pilot") | ///
							strpos(`p', "lastwagen") | ///
							strpos(`p', "sbb") | ///
							strpos(`p', "bahn") | ///
							strpos(`p', "fahrer") | ///
							strpos(`p', "busschaufeur") | ///
                            strpos(`p', "seilbahnfachmann")  | ///
							strpos(`p', "buschaufeur") | ///
                            strpos(`p', "fahrmischer") | ///
                            strpos(`p', "fachspezialist verkehrsprävention") | ///
							 strpos(`p', "kondukteur") | ///
							strpos(`p', "seilbahner") | ///
							strpos(`p', "bergbahnen") | ///
							strpos(`p', "verkehrexperte") | ///
							strpos(`p', "schofför") | ///
							strpos(`p', "parkhausdienst")  | ///
							strpos(`p', "umzug")  | ///
                            strpos(`p', "zeitungen")
							
                            

* Assign ISCED fields
replace isced`p' = 0214 if strpos(`p', "gepolstert") 
replace isced`p' = 0715 if strpos(`p', "operator")
replace isced`p' = 0421 if strpos(`p', "patentprüfer")
replace isced`p' = 0211 if strpos(`p', "poligraf") 
replace isced`p' = 0211 if strpos(`p', "pressionist") 
replace isced`p' = 0715 if strpos(`p', "werkhof") 
replace isced`p' = 0212 if strpos(`p', "autodesinger") 
replace isced`p' = 0715 if strpos(`p', "handwerker") 
replace isced`p' = 0713 if strpos(`p', "kabel") 
replace isced`p' = 0715 if strpos(`p', "kondtrukteur") | strpos(`p', "konstroktör") 
replace isced`p' = 1041 if strpos(`p', "liftoperatör") 
replace isced`p' = 0715 if strpos(`p', "mech") 
replace isced`p' = 0715 if strpos(`p', "rolladenreparieren") 
replace isced`p' = 0715 if strpos(`p', "sandstrahlen") 
replace isced`p' = 0611 if strpos(`p', "swisscom") 
replace isced`p' = 0732 if strpos(`p', "ingenieur sbb") 
replace isced`p' = 0111 if strpos(`p', "lehrer für automobilmechatronik")  
replace isced`p' = 0111 if strpos(`p', "lehrer für hard software loxone")
replace isced`p' = 0200 if strpos(`p', "getränke verkaüfer")  
replace isced`p' = 0111 if strpos(`p', "spilgrupenleiterin")


replace isced`p' = -8 if strpos(`p', "ich weiss nicht") | ///
                           strpos(`p', "weiss ich nicht") | ///
                           strpos(`p', "weis nicht") | ///
                           strpos(`p', "kein beruf") | ///
                           strpos(`p', "keine") | ///
                           strpos(`p', "nichts") | ///
						   strpos(`p', "sie hat keinen beruf ausgeübt") | ///
                           strpos(`p', "sie hat noch nie ein beruf gehabt") | ///  
                           strpos(`p', "sie hat nie richtig gearbeitet")
							

gen isced_field`p' = . 
replace isced_field`p' = 1 if isced`p' == 0111
replace isced_field`p' = 2 if isced`p' == 0212 | isced`p' == 0214 ///
							| isced`p' == 0215 | isced`p' ==  211 
replace isced_field`p' = 3 if isced`p' == 0322
replace isced_field`p' = 4 if isced`p' == 0410 | isced`p' == 0413  ///
							| isced`p' == 0415 | isced`p' == 0416 ///
							| isced`p' ==0421
replace isced_field`p' = 5 if isced`p' == 51
replace isced_field`p' = 6 if isced`p' == 0611 | isced`p' == 0613
replace isced_field`p' = 7 if isced`p' == 0711  | isced`p' ==0713 ///
							| isced`p' == 0715 | isced`p' == 0721  | isced`p' == 0722 ///
							| isced`p' ==0731 | isced`p' == 0732
replace isced_field`p' = 8 if isced`p' == 0811 | isced`p' == 0841
replace isced_field`p' = 9 if isced`p' == 0911 | isced`p' == 0913 ///
							| isced`p' == 0914 | isced`p' == 0923
replace isced_field`p' = 10 if isced`p' == 1011 | isced`p' == 1013  ///
							| isced`p' ==1041 | isced`p' == 0200
							
gen isced6`p' = 1 if isced_field`p' == 1 | isced_field`p' == 9 
replace isced6`p' = 2 if isced_field`p' == 10 
replace isced6`p' = 3 if isced_field`p' == 4 
replace isced6`p' = 4 if inrange(isced_field`p' ,5,7)
replace isced6`p' = 5 if isced_field`p' == 3  | isced_field`p' == 2
replace isced6`p' = 6 if isced_field`p' == 8 
replace isced6`p' = -14 if isced`p' == -14 


drop isced_field`p'
}		

********************************************************************************
* 2) Manual check 
********************************************************************************

* keep if missing(isced6mother_occ)
* gduplicates drop

* Copy data into excel


********************************************************************************
* 3) Merge cleaned data in
********************************************************************************
 
preserve 
	* Merge mothers in 
	import excel "$clean_data\clean_occ.xlsx", clear firstrow sheet("merge_mother")
	tempfile merge_mother
	save `merge_mother'
restore 

preserve 
	* Merge fathers in 
	import excel "$clean_data\clean_occ.xlsx", clear firstrow sheet("merge_father")
	gduplicates tag father_occ, gen(dups)
	drop if dups == 1 // there are two empty lines created by excel that causes issue when merging 
	drop dups
	tempfile merge_father
	save `merge_father'
restore 

	merge m:1 mother_occ using `merge_mother'
	gen merge_mother = _merge
	drop _merge 
	merge m:1 father_occ using `merge_father'
	sort flag* clean_isced6mother_occ clean_isced6father_occ
	
	* Replace if it was flagged manually 
	replace sugg_mother = "" if sugg_mother == "not clear"
	destring(sugg_mother),  replace
	replace sugg_father = "" if sugg_father == "not clear "
	replace sugg_father = "" if sugg_father == "not clear"
	
	destring(sugg_father),  replace
	destring flag_father, replace
	replace isced6mother_occ = sugg_mother if flag_mother == 1 & sugg_mother != .  // the suggestion include corrected values 
	replace isced6father_occ = sugg_father if flag_father == 1 & sugg_father != .
	drop  clean_isced6* sugg*

	* Those who dont have any occupations are missing currently
	replace isced6father_occ = iscedfather_occ if missing(isced6father_occ)
	replace isced6mother_occ = iscedmother_occ if missing(isced6mother_occ)
	tab  isced6mother_occ
	tab  isced6father_occ
	
		
	* Define label for categories we have in survey 
	label define isced6lbl 1 "Gesundheit, Pflege, Betreuung und Ausbildung" ///
                       2 "Dienstleistungen und Detailhandel" ///
                       3 "Wirtschaft, Verwaltung und Recht" ///
                       4 "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften" ///
                       5 "Sozialwissenschaften, Journalismus und Geisteswissenschaften" ///
                       6 "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" ///
					   -14 "Hausfrau / -mann"  ///
					   -2 "Arbeitslos" ///
					   -8 "Weiss nicht"
					   
	label values isced6* isced6lbl
	
gen field_mo =  "Gesundheit, Pflege, Betreuung und Ausbildung" if isced6mother_occ == 1
replace field_mo =  "Dienstleistungen und Detailhandel" if isced6mother_occ == 2
replace field_mo =  "Wirtschaft, Verwaltung und Recht" if isced6mother_occ == 3
replace field_mo =  "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften"  if isced6mother_occ == 4
replace field_mo = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" if isced6mother_occ == 5
replace field_mo =  "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin"  if isced6mother_occ == 6
replace field_mo =  "Hausfrau / -mann"  if isced6mother_occ == -14

gen field_fa =  "Gesundheit, Pflege, Betreuung und Ausbildung" if isced6father_occ == 1
replace field_fa =  "Dienstleistungen und Detailhandel" if isced6father_occ == 2
replace field_fa =  "Wirtschaft, Verwaltung und Recht" if isced6father_occ == 3
replace field_fa =  "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften"  if isced6father_occ == 4
replace field_fa = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" if isced6father_occ == 5
replace field_fa =  "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin"  if isced6father_occ == 6
replace field_fa =  "Hausfrau / -mann"  if isced6father_occ == -14


********************************************************************************
* 4) Produce output table to merge with dataset
********************************************************************************
* Prepare dataset to be merged with main data	
	keep responseid  clean_isced6*
	
	rename clean_isced6mother_occ   isced_motherocc1
	rename clean_isced6mother_occ2  isced_motherocc2
	rename clean_isced6father_occ isced_fatherocc1
	rename clean_isced6father_occ2 isced_fatherocc2
	rename clean_isced6father_occ3 isced_fatherocc3
	
	save "$root\3_Analysis\Code\1_Cleaning\Parental_occupation_cleaning\parents_clean_occ", replace

	
	
********************************************************************************
* Compare distribution of isced with distribution of predefined answer choices

keep field_fa field_mo

gen count = 1 
egen mother_count = count(count) , by(field_mo)
egen father_count = count(count) , by(field_fa)
gen open_occ = 1 

preserve 
keep mother_count field_mo
gduplicates drop
sort field_mo
gen merge = _n 
tempfile mother1
save `mother1'
restore

preserve 
keep father_count field_fa
gduplicates drop
sort field_fa
gen merge = _n 
tempfile father1
save `father1'
restore

preserve 
use "$root\7_Data\1_Rawdata\3_NewT\newt_all.dta", clear 
keep field_educ_mo field_educ_fa
gen count = 1
egen mother_count_new = count(count) , by(field_educ_mo)
egen father_count_new = count(count) , by(field_educ_fa)
gen new_occ = 1
tempfile predefined_field
save `predefined_field'	

keep mother_count_new field_educ_mo
gduplicates drop 
sort field_educ_mo
gen merge = _n + 3
tempfile mother2
save `mother2'

use `predefined_field', clear
keep father_count_new field_educ_fa
gduplicates drop 
sort field_educ_fa
gen merge = _n  + 3
tempfile father2
save `father2'
restore

 use `mother1', clear 
 merge 1:1 merge using `father1', nogen
 append using `mother2'
 append using `father2'
 	 
gen survey = 1 if !missing(field_mo)  // Open text field (POF BL)
replace survey = 2 if missing(field_mo)  // Predefined categories (POF NEWT and in general in more recent survey used)

* The values from the predefined bins are different - redefine field as string to avoid this shift
replace field_mo = "Gesundheit, Pflege, Betreuung und Ausbildung" if field_educ_mo == 1 & missing(field_mo)
replace field_mo = "Dienstleistungen und Detailhandel" if field_educ_mo == 2 & missing(field_mo)
replace field_mo = "Wirtschaft, Verwaltung und Recht"  if field_educ_mo == 3 & missing(field_mo)
replace field_mo = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften"  if field_educ_mo == 6 & missing(field_mo)
replace field_mo = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" if field_educ_mo ==4  & missing(field_mo)
replace field_mo = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" if field_educ_mo == 5 & missing(field_mo)
replace field_mo =  "Hausfrau / -mann"   if field_educ_mo == -14 & missing(field_mo)

replace field_fa =  "Gesundheit, Pflege, Betreuung und Ausbildung" if field_educ_fa == 1 & missing(field_fa)
replace field_fa = "Dienstleistungen und Detailhandel" if field_educ_fa == 2 & missing(field_fa)
replace field_fa = "Wirtschaft, Verwaltung und Recht"  if field_educ_fa == 3 & missing(field_fa)
replace field_fa = "Bauwesen, Informatik, Ingenieurwesen, Produktion, Naturwissenschaften"  if field_educ_fa == 6 & missing(field_fa)
replace field_fa = "Sozialwissenschaften, Journalismus und Geisteswissenschaften" if field_educ_fa ==4  & missing(field_fa)
replace field_fa = "Landwirtschaft, Forstwirtschaft, Fischerei und Tiermedizin" if field_educ_fa == 5 & missing(field_fa)
replace field_fa = "Hausfrau / -mann" if field_educ_fa == -14 & missing(field_fa)

	replace mother_count = mother_count_new if missing(mother_count)	
	replace father_count = father_count_new if missing(father_count)
	
	drop if missing(field_mo) & missing(field_fa)
	egen sum_per_survey_mo = sum(mother_count), by(survey)
	gen share_mo = mother_count / sum_per_survey_mo
	
	egen sum_per_survey_fa = sum(father_count), by(survey)
	gen share_fa = father_count / sum_per_survey_fa
	
	* Comparison between open field answers and predefined categories 
	graph bar share_mo , over(survey, label(angle(45))) over(field_mo, label(angle(45) labsize(small))) ///
    ytitle("%") name("mother", replace) title("Mother occupations")
	
	graph bar share_fa , over(survey, label(angle(45))) over(field_fa, label(angle(45) labsize(small))) ///
    ytitle("%") name("father", replace) title("Father occupations")
	
/* Supplemental graphs for prelim analysis
* Prepare data to prepare graph 
	gen count = 1 
	egen mother_count = count(count) , by(isced6mother_occ)
	egen father_count = count(count) , by(isced6father_occ)
	
	keep isced6mother_occ isced6father_occ mother_count father_count

	preserve 
	keep mother_count isced6mother_occ
	gduplicates drop
	rename isced6mother_occ isced
	tempfile mother
	save `mother'
	restore
	
	preserve 
	keep father_count isced6father_occ
	rename isced6father_occ isced
	gduplicates drop
	tempfile father
	save `father'
	restore
	
*	preserve 
	use `mother' , clear
	append  using `father'
	
	rename mother_count  count_mother
	rename father_count  count_father

	gen isced_id = _n  // Create a unique identifier for each row

	reshape long count, i(isced_id) j(parent_type) string

	// Label the `parent_type` variable for clarity
	replace parent_ =  "Mother" if parent_ == "_mother"
	replace parent_ =  "Father" if parent_ == "_father"
	sort parent_ isced
	
	graph bar (mean) count, over(parent_type, label(angle(45))) over(isced, label(angle(45))) ///
    ytitle("Anzahl") 
	

	graph bar , over(isced6mother_occ, lab(angle(45))) name("mother", replace) 
	graph bar, over(isced6father_occ, lab(angle(45))) name("father", replace)
	
	 
	
	


********************************************************************************
						   
********************************************************************************
* Check accuracy between new and old classification
/*
foreach p in mother father {
	gen isced_field_`p'_old = . 
	replace isced_field_`p'_old = 1 if `p'_occ1_isced4_code == "0111"
	replace isced_field_`p'_old = 2 if `p'_occ1_isced4_code == "0212" | `p'_occ1_isced4_code == "0214" ///
								| `p'_occ1_isced4_code == "0215" | `p'_occ1_isced4_code ==  "0211" 
	replace isced_field_`p'_old = 3 if `p'_occ1_isced4_code == "0322"
	replace isced_field_`p'_old = 4 if `p'_occ1_isced4_code == "0410" | `p'_occ1_isced4_code == "0413"  ///
								| `p'_occ1_isced4_code == "0415" | `p'_occ1_isced4_code == "0416" ///
								| `p'_occ1_isced4_code =="0421"
	* replace isced_field_`p'_old = 5 if `p'_occ1_isced4_code == 51
	replace isced_field_`p'_old = 6 if `p'_occ1_isced4_code == "0611" | `p'_occ1_isced4_code == "0613"
	replace isced_field_`p'_old = 7 if `p'_occ1_isced4_code == "0711"  | `p'_occ1_isced4_code =="0713" ///
								| `p'_occ1_isced4_code == "0715" | `p'_occ1_isced4_code == "0722" ///
								| `p'_occ1_isced4_code =="0731" | `p'_occ1_isced4_code == "0732"
	replace isced_field_`p'_old = 8 if `p'_occ1_isced4_code == "0811" | `p'_occ1_isced4_code == "0841"
	replace isced_field_`p'_old = 9 if `p'_occ1_isced4_code == "0911" | `p'_occ1_isced4_code == "0913" ///
								| `p'_occ1_isced4_code == "0914" | `p'_occ1_isced4_code == "0923"
	replace isced_field_`p'_old = 10 if `p'_occ1_isced4_code == "1011" | `p'_occ1_isced4_code == "1013"  ///
								| `p'_occ1_isced4_code =="1041"

}
	

order	isced_field*

	gen same_mother = 1 if isced_fieldmother_occ == isced_field_mother_old 
	replace same_mother = 0 if isced_fieldmother_occ !=  isced_field_mother_old
	
	gen same_father = 1 if isced_fieldfather_occ == isced_field_father_old 
	replace same_father = 0 if isced_fieldfather_occ !=  isced_field_father_old
	
	sort isced_fieldmother_occ isced_field_mother_old isced_fieldfather_occ isced_field_father_old
	
		
	binscatter isced_fieldfather_occ isced_field_father_old , n(100)
	
	
	twoway lfit   isced_fieldfather_occ isced_field_father_old || lfit isced_fieldmother_occ isced_field_mother_old , legend(label(1 "Fathers") label(2 "Mothers"))
	
	reg  isced_fieldfather_occ isced_field_father_old
	reg isced_fieldmother_occ isced_field_mother_old 
	
	
	br isced_fieldmother_occ isced_field_mother_old isced_fieldfather_occ isced_field_father_old


	
replace isced_code = -8 if strpos(lower(mother_occ), "weiß nicht") | ///
						   strpos(lower(mother_occ), "keine angaben") | ///
						   strpos(lower(mother_occ), "keine") 
						   
						   strpos(lower(mother_occ), "nichts") | ///
						   strpos(lower(mother_occ), "nix") 
						   | ///
                
								*	strpos(lower(mother_occ), "arbeitet") | ///
								
								
	