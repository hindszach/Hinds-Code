clear
set more off
*set trace on

capture log close
log using "E:\Thesis\Do Files\Thesislog.log", replace

ssc install estout
eststo clear

global states "Ak Al Ar Az Ca Co Ct De Dc Fl Ga Hi Id Il In Ia Ks Ky La Me Md Ma Mi Mn Ms Mo Mt Ne Nv Nh Nj Nm Ny Nc Nd Oh Ok Or Pa Ri Sc Sd Tn Tx Ut Vt Va Wa Wv Wi Wy"

global sectors "BusServices EdHlth Finance GoodsProducing Gov LeisureHosp Manufacturing MinLogCon ServiceProviding TotalNonfarm TotalPrivate TradeTranUtil"

global allsectors "BusServices EdHlth Finance GoodsProducing Gov Information LeisureHosp Manufacturing MinLogCon ServiceProviding TotalNonfarm TotalPrivate TradeTranUtil"

/*
cd "E:\Thesis\Data\Statesxls"

ssc install xls2dta
//Install xls2dta package

xls2dta, save("E:/Thesis/Data/Statesdta") : import excel "E:/Thesis/Data/Statesxls/", sheet("BLS Data Series")  cellrange (A13:M30) firstrow
//Transform xls sheets into dta format

cd "E:\Thesis\Data\Statesdta"

foreach initials of global states {
foreach x of global sectors {
use `initials'`x'.dta
gen state_abrev = "`initials'"
encode state_abrev, gen(statecode)
gen sector = "`x'"
save, replace
clear
}
}
//gen the state_abrev  sector and statecode vars in the sector datasets except information

foreach initials in Ak Al Ar Az Ca Co Ct Dc Fl Ga Hi Id Il In Ia Ks Ky La Me Md Ma Mi Mn Ms Mo Mt Ne Nv Nh Nj Nm Ny Nc Nd Oh Or Pa Sc Sd Tn Tx Ut Vt Va Wa Wv Wi Wy {
use `initials'Information.dta
gen state_abrev = "`initials'"
encode state_abrev, gen(statecode)
gen sector = "Information"
save, replace
clear
}
//gen the state_abrev sector and statecode vars for the info datasets

foreach initials in Al Ar Az Ca Co Ct De Dc Fl Ga Hi Id Il In Ia Ks Ky La Me Md Ma Mi Mn Ms Mo Mt Ne Nv Nh Nj Nm Ny Nc Nd Oh Ok Or Pa Ri Sc Sd Tn Tx Ut Vt Va Wa Wv Wi Wy {
foreach x of global sectors {
use Ak`x'.dta
append using `initials'`x'.dta
save, replace
clear
}
}
//Append all Sector datasets into respecitve master sets except information

foreach initials in Al Ar Az Ca Co Ct Dc Fl Ga Hi Id Il In Ia Ks Ky La Me Md Ma Mi Mn Ms Mo Mt Ne Nv Nh Nj Nm Ny Nc Nd Oh Or Pa Sc Sd Tn Tx Ut Vt Va Wa Wv Wi Wy {
use AkInformation.dta
append using `initials'Information.dta
save, replace
clear
}
//Append all Information datasets into respecitve master set

foreach x of global allsectors {
use Ak`x'.dta
save `x'.dta, replace
clear
use Ak`x'.dta
keep if state_abrev=="Ak"
save, replace
clear
}
//resetting Ak`x'.dta to original and saving appended file as `x'.dta

use MinLogCon.dta
drop if mi(Year)
save, replace
clear

foreach x of global allsectors {
cd "E:\Thesis\Data\Statesdta"
use `x'.dta
reshape wide Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec, i(state_abrev) j(Year)
drop statecode
encode state_abrev, gen(statecode)
save `x'.dta, replace
clear
}
//Reshaping the CES data sets

cd "E:\Thesis\Data\Chodorow-Reich et al data"
use state_medicaid_spending_instrument.dta
sort state_abrev
merge 1:1 state_abrev using pop16plus_cleaned.dta
replace pop16plus = pop16plus*1000
tab _merge
drop _merge
rename pop16plus popestimate2008
//Merging the instrument with population data

sort state_abrev
merge 1:1 state_abrev using state_controls.dta
drop _merge
sort state_abrev
rename gdp_2008 gdp_2008_old
gen gdp_2008 = gdp_2008_old/1000000
label variable gdp_2008 "GDP divided by 1,000,000"
drop gdp_2008_old
//Merging state controls and rescaling gdp so that it is not too large compared to my other variables

forvalues i=1/9 {
gen region_`i' = cond(__region_dummies==`i',1,0)
label variable region_`i' "Region `i'"
}
save "E:/Thesis/Data/Statesdta/state_medicaid_spending_instrument.dta", replace
clear
//Making region dummies

use Arraspending.dta
keep if date==td(30,6,2010)
ren state_acronym state_abrev
drop if state_abrev==""
gen outlays_total=outlaysFMAP+outlaysOther+outlaysSFSF
ren obligationsFMAP oblig_med
label variable outlays_total "total ARRA outlays as of `spending_date'"
gen medsfsf=outlaysFMAP+outlaysSFSF
gen paidout=outlaysOther+outlaysSFSF+outlaysFMAP
gen fmap=outlaysFMAP
label variable medsfsf "total FMAP+SFSF outlays as of `spending_date'"
foreach s in FM AS MH VI MP GU PR PW N/ [Other] - 14 A UM {
drop if state_abrev=="`s'"
}
sort state_abrev
save "E:/Thesis/Data/Statesdta/Arraspending.dta", replace
clear
//Preparing the Arraspending data set for merge

foreach x of global allsectors {
cd "E:\Thesis\Data\Statesdta"
use `x'.dta
gen empchange_09 = 1000*(Jul2009-Dec2008)
gen empchange_12 = 1000*(Jul2012-Dec2008)
gen empchange_14 = 1000*(Jul2014-Dec2008)
gen empchange_16 = 1000*(Jul2016-Dec2008)
gen empchange_lag = 1000*(Dec2008-May2008)
keep state_abrev empchange_09 empchange_12 empchange_14 empchange_16 empchange_lag
save `x'_change, replace
clear
}
//Generating change outcome variables

cd E:\Thesis\Data\Statesdta
use state_medicaid_spending_instrument.dta
merge 1:1 state_abrev using Arraspending.dta
drop date _merge
save, replace
clear
//Merging instrument with Arraspending

foreach x of global allsectors {
cd "E:\Thesis\Data\Statesdta"
use `x'_change.dta
replace state_abrev = upper(state_abrev)
save, replace
clear
use state_medicaid_spending_instrument.dta
merge 1:1 state_abrev using `x'_change.dta
drop _merge
save `x'_analysis.dta, replace
clear
}
//Merging Instument and controls with outcome variables

foreach x of global allsectors {
cd "E:\Thesis\Data\Statesdta"
use `x'_analysis.dta
foreach var in instrument paidout fmap oblig_med outlaysFMAP medsfsf {
gen `var'_pc = `var'/popestimate2008
replace `var'_pc = `var'_pc/100000
}
foreach y in 09 12 14 16 lag {
gen empchange_`y'_pc = empchange_`y'/popestimate2008
gen empchange_`y'_1k = empchange_`y'_pc*1000
}
gen gdp_pc = 1000000*gdp_2008/popestimate2008 
foreach var in share_kerry union_share per_empl_manu {
gen `var'_10000 = `var'/10000
}
gen popestimate2008_mil = popestimate2008/1000000
gen popestimate2008_bil = popestimate2008/1000000000

foreach var in fmap_pc paidout_pc medsfsf_pc instrument_pc {
gen `var'_100000 = `var'*100000
}

gen gdp_pc_1000 = gdp_pc*1000

rename __region_dummies region

label variable paidout_pc "Total ARRA Payouts per capita ($100k)"
label variable fmap_pc "ARRA FMAP Payouts per capita ($100k)"
label variable oblig_med_pc "ARRA FMAP Obligations per capita ($100k)"
label variable instrument_pc "Medicaid Instument per capita ($100k)"
label variable per_empl_manu_10000 "per_empl_manu/10000"
label variable union_share_10000 "union share/10000"
label variable share_kerry_10000 "2004 Kerry vote share/10000"
label variable gdp_pc "GDP per capita divided by 10000"
label variable popestimate2008_mil "population estimate in 2008 in millions"
label variable popestimate2008_bil "population estimate in 2008 in  billions"
save, replace
clear
}
//Scaling Variables

foreach x of global allsectors {
use `x'.dta
replace state_abrev = upper(state_abrev)
keep state_abrev Dec2008 Jul2009 Jul2012 Jul2014 Jul2016
save `x'empdates.dta, replace
clear
}
//Preparing dates for merge

foreach x of global allsectors {
use `x'_analysis
merge 1:1 state_abrev using `x'empdates
drop _merge
gen Dec2008_pc = (Dec2008)/popestimate2008
gen ln_Dec2008_pc = ln(Dec2008_pc)
foreach y in 09 12 14 16 {
gen Jul20`y'_pc = (Jul20`y')/popestimate2008
gen ln_Jul20`y'_pc = ln(Jul20`y'_pc)
gen ln_empchange_`y'_pc = ln_Jul20`y'_pc-ln_Dec2008_pc
drop Jul20`y' Jul20`y'_pc ln_Jul20`y'_pc
}
drop Dec2008 Dec2008_pc ln_Dec2008_pc
gen ln_fmap_pc = ln(fmap_pc)
gen ln_instrument_pc = ln(instrument_pc)
save, replace
clear
}
//Merging logged change variables and generating logged outcome vars scaled by working pop.*/

global controls1 "share_kerry union_share gdp_pc per_empl_manu popestimate2008"
global controls2 "share_kerry union_share gdp_pc per_empl_manu popestimate2008 empchange_lag_pc"

cd "E:\Thesis\Data\Statesdta"
foreach x of global sectors {
use `x'_analysis.dta
foreach y in 09 12 14 16 lag {
sum empchange_`y'_1k
}
clear
}

use TotalNonfarm_analysis.dta
sum paidout_pc_100000 fmap_pc_100000 medsfsf_pc_100000 instrument_pc_100000
sum per_empl_manu share_kerry union_share gdp_pc_1000 popestimate2008_mil
//Summary Statistics

eststo first1: reg fmap_pc instrument_pc, robust
eststo first2: xtreg fmap_pc instrument_pc share_kerry union_share gdp_pc per_empl_manu popestimate2008, fe i(region) robust
eststo first3: xtreg fmap_pc instrument_pc share_kerry union_share gdp_pc per_empl_manu popestimate2008 empchange_lag_pc, fe i(region) robust 
//Frist stage regressions

clear

foreach x of global sectors{
use `x'_analysis.dta
foreach y in 4 5{
eststo first`y': xtreg fmap_pc instrument_pc share_kerry union_share gdp_pc per_empl_manu popestimate2008 empchange_lag_pc, fe i(region) robust 
}
clear
}
//First stage regression of other sectors with lagged employment controls

use TotalNonfarm_analysis.dta

foreach x in 09 12 14 16 {
eststo second`x'1: reg empchange_`x'_pc fmap_pc, robust
eststo second`x'2: xtreg empchange_`x'_pc fmap_pc share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil, fe i(region) robust
eststo second`x'3: xtreg empchange_`x'_pc fmap_pc share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil empchange_lag_pc, fe i(region) robust
}
//Reduced form estimates for baseline results

foreach x in 09 12 14 16 {
eststo second`x'4: ivregress 2sls empchange_`x'_pc (fmap_pc = instrument_pc), robust
eststo second`x'5: ivregress 2sls empchange_`x'_pc (fmap_pc = instrument_pc) share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil i.region, robust
eststo second`x'6: ivregress 2sls empchange_`x'_pc (fmap_pc = instrument_pc) share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil empchange_lag_pc i.region, robust
}
//iv estimates for baseline results

clear

foreach x of global sectors {
use `x'_analysis
foreach y in 09 12 14 16 {
eststo `x'`y'1: reg empchange_`y'_pc fmap_pc, robust
eststo `x'`y'2: xtreg empchange_`y'_pc fmap_pc share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil, fe i(region) robust
eststo `x'`y'3: xtreg empchange_`y'_pc fmap_pc share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil empchange_lag_pc, fe i(region) robust
}
clear
}
//Reduced form estimates for Health & Education and Goverment

foreach x of global sectors {
use `x'_analysis
foreach y in 09 12 14 16 {
eststo `x'`y'4: ivregress 2sls empchange_`y'_pc (fmap_pc = instrument_pc), robust
eststo `x'`y'5: ivregress 2sls empchange_`y'_pc (fmap_pc = instrument_pc) share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil i.region, robust
eststo `x'`y'6: ivregress 2sls empchange_`y'_pc (fmap_pc = instrument_pc) share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil empchange_lag_pc i.region, robust
}
clear
}
//iv estimates for Health & Education and Government

esttab first* using first.csv, replace se noconstant label ti("First Stage Regressions") compress star(* 0.1 ** 0.05 *** 0.01)
//First stage output

foreach x in 09 12 14 16 {
esttab second`x'* using second`x'.csv, replace se noconstant label ti(" Total Employment Baseline Results 20`x'") compress star(* 0.1 ** 0.05 *** 0.01)
}
//Reduced form and IV outputs for baseline results

foreach x of global sectors {
foreach y in 09 12 14 16 {
esttab `x'`y'* using `x'`y'.csv, replace se noconstant label ti(" `x' Results 20`y'") compress star(* 0.1 ** 0.05 *** 0.01)
}
}
//Reduced form and IV outputs for EdHlth and Gov results

use EdHlth_analysis
gen ACA = 1
replace ACA = 0 if state_abrev== "AL" | state_abrev=="FL" | state_abrev=="GA" | state_abrev=="KA" | state_abrev=="MS" | state_abrev=="MO" | state_abrev=="NC" | state_abrev=="SC" | state_abrev=="SD" | state_abrev=="TN" | state_abrev=="TX" | state_abrev=="DC"
foreach y in 09 12 14 16 {
ivregress 2sls empchange_`y'_pc (fmap_pc = instrument_pc) share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil empchange_lag_pc  ACA i.region, robust
}
clear

foreach x of global sectors {
use `x'_analysis.dta
foreach y in 09 12 14 16 {
ivregress 2sls ln_empchange_`y'_pc (fmap_pc = instrument_pc) share_kerry_10000 union_share_10000 gdp_pc per_empl_manu_10000 popestimate2008_bil empchange_lag_pc i.region, robust
}
}

log close
set more on
set trace off

*view "E:\Thesis\Do Files\Thesislog.log"
