/*SDTM*/
/*sorting DM data*/;
proc sort data= data_s.DM out=sort_dm;
by USUBJID;
run;
/*sorting EC data*/
proc sort data=data_s.EC out=sort_ec;
by USUBJID ECSTDTC;
run;
/*Creating RF dates*/
data Datesnew ;
set sort_ec;
by usubjid;
retain rfstdtc rfxstdtc;
if first.usubjid then do;
rfstdtc=ecstdtc;
rfxstdtc=ecstdtc;
end;
if last.usubjid then do;
RFENDTC=ECSTDTC;
RFXENDTC=ECSTDTC;
output;
end;
keep usubjid rfstdtc rfxstdtc rfendtc rfxendtc;
run;
/*DS sorting*/
proc sort data= data_s.DS out=sort_ds;
by USUBJID dsstdtc;
run;
/*Deriving RFICDTC*/
data dm_rficdtc;
 set sort_ds;
 where ifccat="STUDY INFORMED CONSENT";
 RFICDTC=DSSTDTC;
 keep usubjid rficdtc;
run;
/*Deriving RFPENDTC*/
DM SDTM
Thursday, February 23, 2023 9:36 AM
 DM Page 1 
/*Deriving RFPENDTC*/
data dm_rfpendtc;
 set sort_ds;
 by usubjid;
 if last.usubjid;
 RFPENDTC=DSSTDTC;
 keep usubjid RFPENDTC;
run;
/*Merging sort_dm dm_rficdtc dm_rfpendtc to get DM_FINAL*/
data DM_FINAL;
 merge sort_dm(in = a) dm_rficdtc dm_rfpendtc;
 by USUBJID;
 if a;
keep usubjid rficdtc RFPENDTC;
run;
/*Sorting Y1 data*/
PROC sort data=data_s.Y1 out=sort_y1(keep=RNDNUM TRT TRTCD);
by RNDNUM;
run;
/*Sorting DS data*/
PROC sort data=data_s.DS out=sort_ds;
by RNDNUM;
run;
/*Merging y1 and ds*/
data dm_ARM;
merge sort_y1(in=a)sort_ds;
by rndnum;
if a;
run;
/*Deriving */
data dm_finalarm;
set dm_arm;
armcd=trtcd;
arm=trt;
actarmcd= armcd;
actarm= arm;
if usubjid ne " " and RNDNUM ne .; 
keep usubjid arm armcd actarmcd actarm;
run;
/*Final dataset merge */
data DM_SDTM;
merge sort_dm Datesnew DM_FINAL dm_finalarm;
By usubjid;
keep STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC 
RFXENDTC RFICDTC RFPENDTC SITEID AGE AGEU SEX RACE ETHNIC ARMCD 
ARM ACTARMCD ACTARM COUNTRY;
run;
/*Arranging variables in order*/
data derived.dm_jadhaas4;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC 
RFXENDTC RFICDTC RFPENDTC SITEID AGE AGEU SEX RACE ETHNIC ARMCD 
ARM ACTARMCD ACTARM COUNTRY;
set DM_SDTM ;
domain="DM";
if ARM=" " then do;
ARM="Screen Failure";
ARMCD="SCRNFAIL";
ACTARM="Screen Failure";
ACTARMCD="SCRNFAIL";
end;
 DM Page 2 
end;
run;





/*ADSL*/


/*Deriving SAFFL*/
data saffl;
set derived.dm_jadhaas4;
if actarm="Screen Failure" then SAFFL="N";
else SAFFL="Y";
keep USUBJID SAFFL;
run;
/*Deriving TRT01P TRT02P TRT01A TRT02A*/
data trt01ptrt02p;
set derived.dm_jadhaas4;
if ARM ne "Screen Failure" then do; 
TRT01P=substr(ARM,1,37);
TRT02P=substr(ARM,39);
end;
keep USUBJID TRT01P TRT02P;
run;
/*sorting ec*/
proc sort data=data_s.ec out=sort_ecnew;
by usubjid ecstdtc EPOCH;
run;
/*Merging sorted ec with sdtm dm*/
data b;
merge sort_ecnew derived.dm_jadhaas4;
by usubjid;
run;
/*Deriving TRT01A TRT02A*/
data b1;
set b;
by usubjid;
retain TRT01A TRT02A;
if VISIT="DAY 1" then TRT01A=scan(ACTARM,1,";");
if VISIT="DAY 8" then TRT02A=substr(ACTARM,39);
if first.usubjid=1 and visit=" " then TRT01A=" ";
if first.usubjid=1 then TRT02A=" ";
if last.usubjid;
run;
 DM Page 3 
/* Deriving TRT01PN TRT02PN TRT01AN TRT02AN**/
data trt01pn;
set trt01ptrt02p;
if TRT01P="P1: Single Dose of QAW039 150mg Day 1 " then TRT01PN=1;
 else if TRT01P="P1: Single Dose of QAW039 450mg Day 1" then TRT01PN=2;
keep USUBJID TRT01P TRT01PN; 
run;
Data trt02pn;
set trt01ptrt02p;
if TRT02P=" P2: Once daily dose of QAW039 150mg Day 8 to 12 " then TRT02PN=1;
 else if TRT02P=" P2: Once daily dose of QAW039 450mg Day 8 to 12" then TRT02PN=2;
keep USUBJID TRT02P TRT02PN; 
run;
data trt01an;
set b1;
if TRT01A="P1: Single Dose of QAW039 150mg Day 1 " then TRT01AN=1;
 else if TRT01A="P1: Single Dose of QAW039 450mg Day 1" then TRT01AN=2;
keep USUBJID TRT01A TRT01AN; 
run;
Data trt02an;
set b1;
if TRT02A=" P2: Once daily dose of QAW039 150mg Day 8 to 12 " then TRT02AN=1;
 else if TRT02A=" P2: Once daily dose of QAW039 450mg Day 8 to 12" then TRT02AN=2;
keep USUBJID TRT02A TRT02AN; 
run;
data trt01pntrt02pn;
merge trt01pn trt02pn;
by usubjid;
run;
data trt01antrt02an;
merge trt01an trt02an;
run;
/*final merge */
data TRTPTRTA;
merge trt01pntrt02pn trt01antrt02an;
by usubjid;
run;
/*Deriving SDT STM SDTM EDT ETM EDTM*/
data SDTEDT;
set derived.dm_jadhaas4;
TRTSDT= input(scan(RFXSTDTC,1,"T"),yymmdd10.);
TRTSTM=input(scan(RFXSTDTC,2,"T"),time5.);
TRTSDTM=input(RFXSTDTC,YMDDTTM16.);
TRTEDT= input(scan(RFXENDTC,1,"T"),yymmdd10.);
TRTETM=input(scan(RFXENDTC,2,"T"),time5.);
TRTEDTM=input(RFXENDTC,YMDDTTM16.);
format TRTSDT TRTEDT E8601DA10. TRTSTM TRTETM time5. TRTSDTM TRTEDTM E8601DT16.;
keep USUBJID TRTSDT TRTSTM TRTSDTM TRTEDT TRTETM TRTEDTM;
run;
/*Deriving TR01SDT,STM,SDTM */
proc sort data=data_s.ec out=sort_ec;
by usubjid ecstdtc;
 DM Page 4 
by usubjid ecstdtc;
run;
data TR01SDT;
set sort_ec;
by usubjid; 
format TR01SDT E8601DA10. TR01STM time5. TR01SDTM E8601DT16.;
if VISIT="DAY 1" and ecstdtc ne "" then TR01SDT=input(scan(ecstdtc,1,"T"),yymmdd10.);
if VISIT="DAY 1" and ecstdtc ne "" then TR01STM=input(scan(ecstdtc,2,"T"),time5.);
if VISIT="DAY 1" and ecstdtc ne "" then TR01SDTM=input(ecstdtc,YMDDTTM16.);
if first.usubjid=1;
keep USUBJID TR01SDT TR01STM TR01SDTM;
run;
/*Deriving TR02SDT,STM,SDTM*/
proc sort data=data_s.ec out=sort_ec;
by usubjid ecstdtc;
run;
proc sort data=Data_s.ec out=sort_ec1;
by USUBJID;
where EPOCH="TREATMENT PERIOD 2";
run;
data TR02SDT;
set sort_ec1;
by usubjid;
retain TR02SDT TR02STM TR02SDTM;
format TR02SDT E8601DA10. TR02STM time5. TR02SDTM E8601DT16.;
if EPOCH="TREATMENT PERIOD 2" and VISIT="DAY 8" then 
TR02SDT=input(scan(ecstdtc,1,"T"),yymmdd10.);
if EPOCH="TREATMENT PERIOD 2" and VISIT="DAY 8" then 
TR02STM=input(scan(ecstdtc,2,"T"),Time5.);
if EPOCH="TREATMENT PERIOD 2" and VISIT="DAY 8" then 
TR02SDTM=input(ecstdtc,YMDDTTM16.);
if first.usubjid=1;
keep USUBJID TR02SDT TR02STM TR02SDTM;
run;
/*Deriving TR01EDT,ETM,EDTM*/
data tr01edt;
set tr02SDT;
by usubjid;
format TR01EDT E8601DA10. TR01ETM time5. TR01EDTM E8601DT16.;
 TR01EDT=TR02SDT;
 TR01ETM=TR02STM;
 TR01EDTM=TR02SDTM;
 
 keep USUBJID TR01EDT TR01ETM TR01EDTM ;
run;
/*Deriving TR02EDT,ETM,EDTM*/
data tr02edt;
set sort_ec;
by usubjid;
format TR02EDT E8601DA10. TR02ETM time5. TR02EDTM E8601DT16.;
if EPOCH="TREATMENT PERIOD 2" and last.usubjid=1 then do;
TR02EDT=input(scan(ecstdtc,1,"T"),yymmdd10.);
 TR02ETM=input(scan(ecstdtc,2,"T"),Time5.);
TR02EDTM=input(ecstdtc,ymddttm16.);
end;
 DM Page 5 
end;
 
if last.usubjid=1;
keep USUBJID TR02EDT TR02ETM TR02EDTM; 
run;
/*Deriving WGTSCR HGTSCR BMISCR*/
proc sort data= data_s.vs out= sort_vs;
by usubjid;
run;
data weight;
set sort_vs;
BY USUBJID;
retain WGTSCR HGTSCR BMISCR;
where visit="SCREENING";
if vstest="Weight" then WGTSCR=input(vsorrEs,10.);
else if vstest ="Height" then HGTSCR=input(vsorrEs,10.);
else if vstest="Body Mass Index" then BMISCR=input(vsorrEs,10.);
IF LAST.USUBJID=1;
KEEP USUBJID WGTSCR HGTSCR BMISCR;
run;
/*Merging derived variables*/
data adsl_jadhaas4_1;
retain STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC 
RFPENDTC SITEID AGE AGEU
SEX RACE ETHNIC ARMCD ARM ACTARMCD ACTARM COUNTRY SAFFL TRT01P TRT02P 
TRT01PN TRT02PN TRT01A TRT02A TRT01AN TRT02AN
TRTSDT TRTSTM TRTSDTM TRTEDT TRTETM TRTEDTM TR01SDT TR02SDT TR01STM TR02STM 
TR01SDTM TR02SDTM TR01EDT TR02EDT TR01ETM TR02ETM 
TR01EDTM TR02EDTM WGTSCR HGTSCR BMISCR;
merge derived.dm_jadhaas4 saffl TRTPTRTA SDTEDT TR01SDT TR02SDT tr01edt tr02edt weight;
by usubjid;
run;
data adsl_jadhaas4_2;
set adsl_jadhaas4_1;




/*TFL*/

/*creating new dataset from adsl*/
data dm_adsl;
set analysis.adsl_jadhaas4;
run;
/*Filtering data where saffl Y*/
data a;
set dm_adsl;
where saffl="Y";
run;
/*sorting data*/
proc sort data=a;
by ACTARMCD;
run;
/*Duplicating data */
data b;
set a;
output;
actarmcd="Total";
output;
run;
proc sort data=b out=sort_b;
by ACTARMCD;
run;

/*Deriving age for subject demographics(safety analysis set)*/
proc means data=sort_b nway noprint;
var age;
by ACTARMCD;
output out=age n=_n mean=_Mean std=_SD min=_Min median=_Median max=_Max;
run;
data agefinal;
set age;
 n=put(_n, 3.);
 Mean=put(_Mean,4.1);
 SD=put(_SD,5.2);
 Min=put(_Min,4.1);
 Median=put(_Median,4.1);
 Max=put(_Max,4.1);
 drop _Mean _Median _n _SD _Min _Max _TYPE_ _FREQ_ ;
 RUN;
proc transpose data=agefinal out=agefinal1;
id ACTARMCD;
var n Mean SD Min Median Max;
run;
data a_;
length _COL_ $ 30;
 set agefinal1;
 If _NAME_="n" then _COL_=" n";
 else if _NAME_="Mean" then _COL_=" Mean";
 else if _NAME_="SD" then _COL_=" SD";
 DM Page 7 
 else if _NAME_="SD" then _COL_=" SD";
 else if _NAME_="Min" then _COL_=" Min";
 else if _NAME_="Median" then _COL_=" Median";
 else if _NAME_="Max" then _COL_=" Max"; 
 drop _NAME_;
run;
data a1;
length _COL_ $ 30;
_COL_="Age (years)";
run;
data final_age;
length _COL_ $30 T01 T02 TOTAL $20;
set a1 a_;ord=1;
run;
/*Deriving weight for subject demographics(safety analysis set)*/
proc means data=sort_b nway noprint;
var WGTSCR;
by ACTARMCD;
output out=weight n=_N mean=_Mean std=_SD min=_Min median=_Median max=_Max;
run;
data weightfinal;
set weight;
 N=put(_N, 3.);
 Mean=put(_Mean,4.1);
 SD=put(_SD,5.2);
 Min=put(_Min,4.1);
 Median=put(_Median,4.1);
 Max=put(_Max,4.1);
 drop _Mean _Median _N _SD _Min _Max _TYPE_ _FREQ_ ;
 RUN;
proc transpose data=weightfinal out=weightfinal1;
id ACTARMCD;
var N mean SD Min Median Max;
run;
/*making space according to TFL SHELL*/
data b_;
length _COL_ $ 30;
 set weightfinal1 ;
 If _NAME_="N" then _COL_=" N";
 else if _NAME_="Mean" then _COL_=" Mean";
 else if _NAME_="SD" then _COL_=" SD";
 else if _NAME_="Min" then _COL_=" Min";
 else if _NAME_="Median" then _COL_=" Median";
 else if _NAME_="Max" then _COL_=" Max"; 
 drop _NAME_;
run;
data b1;
length _COL_ $ 30;
_COL_="Weight (kg)";
run;
data final_weight;
length _COL_ $30 T01 T02 TOTAL $20;
set b1 b_;ord=3;
run;
 DM Page 8 
run;
/*Deriving height for subject demographics(safety analysis set)*/
proc means data=sort_b nway noprint;
var HGTSCR;
By ACTARMCD;
output out= height n=_n mean=_Mean std=_SD min=_Min median=_Median max=_Max;
run;
data heightfinal;
set height;
 n=put(_n, 4.);
 Mean=put(_Mean,5.1);
 SD=put(_SD,6.2);
 Min=put(_Min,5.1);
 Median=put(_Median,5.1);
 Max=put(_Max,5.1);
 drop _Mean _Median _n _SD _Min _Max _TYPE_ _FREQ_ ;
 RUN;
proc transpose data=heightfinal out=heightfinal1;
id ACTARMCD;
var n mean SD Min Median Max;
run;
data c_;
length _COL_ $ 30;
 set heightfinal1;
 If _NAME_="n" then _COL_=" n";
 else if _NAME_="Mean" then _COL_=" Mean";
 else if _NAME_="SD" then _COL_=" SD";
 else if _NAME_="Min" then _COL_=" Min";
 else if _NAME_="Median" then _COL_=" Median";
 else if _NAME_="Max" then _COL_=" Max"; 
 drop _NAME_;
run;
data c1;
length _COL_ $ 30;
_COL_="Height (cm)";
run;
data final_height;
length _COL_ $30 T01 T02 TOTAL $20;
set c1 c_;ord=4;
run;
/*Deriving BMISCR for subject demographics(safety analysis set)*/
proc means data=sort_b nway noprint;
var BMISCR;
by ACTARMCD;
output out=BMI n=_n mean=_Mean std=_SD min=_Min median=_Median max=_Max; 
run;
data BMIfinal;
set bmi;
 n=put(_n, 3.);
 DM Page 9 
 n=put(_n, 3.);
 Mean=put(_Mean,4.1);
 SD=put(_SD,5.2);
 Min=put(_Min,4.1);
 Median=put(_Median,4.1);
 Max=put(_Max,4.1);
 drop _Mean _Median _n _SD _Min _Max _TYPE_ _FREQ_ ;
 RUN;
proc transpose data=BMIfinal out=BMIFinal1;
id ACTARMCD;
var n mean SD Min Median Max;
run;
data d_;
length _COL_ $ 30;
 set BMIFinal1;
 If _NAME_="n" then _COL_=" n";
 else if _NAME_="Mean" then _COL_=" Mean";
 else if _NAME_="SD" then _COL_=" SD";
 else if _NAME_="Min" then _COL_=" Min";
 else if _NAME_="Median" then _COL_=" Median";
 else if _NAME_="Max" then _COL_=" Max"; 
 drop _NAME_;
run;
data d1;
length _COL_ $ 30;
_COL_="BMI(kg/m2)";
run;
data final_BMI;
length _COL_ $30 T01 T02 TOTAL $20;
set d1 d_;ord=5;
run;
/*Deriving sex*/
proc freq data=sort_b noprint;
tables sex*actarmcd/out=sex totpct outpct list;
run;
data sex1;
set sex;
sex_=cats(count,"(",put(PCT_COL,5.2),")");
drop PCT_COL PCT_ROW PERCENT COUNT;
run;
proc transpose data=sex1 out=sex2;
by Sex;
ID ACTARMCD;
var sex_;
run;
proc sort data=sex2 out=sex3(drop=_NAME_);
By descending sex;
run;
data finalsex1;
length _COL_ $ 200. T01 $ 200. T02 $ 200. TOTAL $ 200.;
set sex3;
if sex="M" then _COL_=" Male";
if sex="F" then _COL_=" Female";
drop sex;
 DM Page 10 
drop sex;
run;
data finalsex2;
length _COL_ $ 200. T01 $ 200. T02 $ 200. TOTAL $ 200.;;
_COL_="Sex - n (%)";
run;
data Final_sex;
length _COL_ $ 200. T01 $ 200. T02 $ 200. TOTAL $ 200.;
set finalsex2 finalsex1;ord=2;
run; 
/*Merging age weight height bmi*/
data table1;
length _COL_ $ 200. T01 $ 200. T02 $ 200. TOTAL $ 200.;
set final_age final_sex Final_weight final_height final_bmi;
run;
/*using call symput to drive N*/
data agex;
set agefinal1;
if _Name_="n" then do;
Group1=T01;
Group2=T02;
Group3=Total;
call symputx("N1",T01);
call symputx("N2",T02);
call symputx("N3",Total);
end;
run;

/*Creating Report*/

proc report data=table1 nowd headline split='*';
column (ord _COL_ T01 T02 Total);
define ord/order noprint;
break after ord/skip;
define _COL_/width=40'Characteristics';
define T01/width=20 "Group 1 * N=&N1";
define T02/width=20 "Group 2 * N=&N2";
define Total/width=20 "Total* N=&N3";
run;
