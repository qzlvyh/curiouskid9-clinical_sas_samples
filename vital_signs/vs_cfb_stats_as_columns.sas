%let _x_x_debug=;
dm log 'clear';
dm lst 'clear';
dm output 'clear';

%include "path";

%let pgm_name=t_vs_long;

%&_x_x_debug.pre_process_setup;



%macro pul;

proc format;
   value trt
   1 = "Active 0.3mg/kg"
   2 = "Active 0.6mg/kg"
   3 = "Placebo"
   ;
run;

* read the input datasets ;

proc sql;
   create table adsl as select usubjid,trt01pn,trt02pn,pcountry from adam.adsl where saffl = "Y" order by usubjid;
   create table advss as select usubjid, avisit, avisitn, aval, chg, base from adam.advss where saffl = "Y" and 
      not missing(avisitn) and basetype = "LONG TERM" and paramcd = "&paramcd";
   create table qs as select a.trt01pn,a.trt02pn,a. pcountry,b.* from adsl a inner join advss b on a.usubjid = b.usubjid;
quit;

data adsl;
   set adsl;
%trt_duplication;

run;

data qs;
   set qs;
%trt_duplication;

run;

* find safety analysis subjects count ;

proc sql;
   select count(unique usubjid) into:n1-:n6 from adsl group by treatment;
quit;

%put &n1 &n2 ;

* descriptive statistics on aval ;

proc means data = qs nway noprint;
   class treatment avisitn avisit;
   var aval;
   output out = stat_aval n = n mean = mean std = std median = median;
run;

proc means data = qs nway noprint;
   class treatment avisitn avisit;
   where avisitn gt 0 and base ne . and chg ne .;
   var chg;
   output out = stat_change n = chg_n mean = chg_mean std = chg_std median = chg_median;
run;

data stat;
   length c1 $100;
   merge stat_aval stat_change;
   by treatment avisitn avisit;
   c3 = put(n,3.);
   c4 = put(mean,6.2);
   c6 = put(std,6.3);
   c5 = put(median,6.2);
   if not missing(chg_n) then c7 = put(chg_n,3.);
   if not missing(chg_mean) then c8 = put(round(chg_mean,0.01),7.2);
   if not missing(chg_std) then c10 = put(round(chg_std,0.001),7.3);
   if not missing(chg_median) then c9 = put(round(chg_median,0.01),7.2);
 
   if treatment=1 then c1="Placebo/0.3mg/kg (N=%cmpres(&n1))";
   else if treatment=2 then c1="Placebo/0.6mg/kg (N=%cmpres(&n2))";
   else if treatment=3 then c1="Placebo/Total (N=%cmpres(&n3))";
   else if treatment=4 then c1="Active 0.3mg/kg (N=%cmpres(&n4))";
   else if treatment=5 then c1="Active 0.6mg/kg (N=%cmpres(&n5))";
   else if treatment=6 then c1="Active Total (N=%cmpres(&n6))";

   keep c: treatment avisit avisitn ;
run;

* mixed model analysis on chg ;

proc sort data = qs;
   by avisitn;
run;

* converting the treatment arms to have sorting order in defining treatment difference values ;

data qs1;
   set qs;
   where chg ne . ;
   if treatment = 1 then treatment_ = 2;
   else if treatment = 2 then treatment_ = 1;
   else if treatment = 3 then treatment_ = 3;
run;


ods listing close;
ods output lsmeans=lsmean
           diffs=diff;
Proc mixed data=qs;              
 where avisitn gt 0;
 by avisitn avisit;
 class treatment ;             
 model chg=base treatment;             
 lsmeans treatment/diff cl;               
Run;
ods listing;

data lsmean;
   set lsmean;
   if not missing(estimate) then  c11=put(round(estimate,0.01),6.2);
   if not missing(stderr) then c12=put(round(stderr,0.001),6.3);
   keep avisitn avisit treatment c11 c12;
run;

proc sort data = stat;
   by treatment avisitn;
run;

proc sort data = lsmean;
   by treatment avisit;
run;
* arranging the treatment arm according to the data ;

data three;
   length avisit $100;
   set lsmean;
   by treatment avisit;
run;

proc sort data = three;
   by treatment avisitn;
run;

data three;
   merge three stat;
   by treatment avisitn;
run;

data final;
   set three ;
   c2 = propcase(avisit);
   page = ceil(_n_/15);
run;

proc sort data = final;
   by treatment avisitn;
run;

data custom.&rptnm._val;
   set final;
   keep c1-c10;
run;


%mend pul;

%let paramcd = SYSBP;
%let rptnm = t_vs_sbp_long;
%let ttl1 = Vital Signs - Systolic Blood Pressure (mmHg);
%pul;

%let paramcd = DIABP;
%let rptnm = t_vs_dbp_long;
%let ttl1 = Vital Signs - Diastolic Blood Pressure (mmHg);
%pul;

%let paramcd = PULSE;
%let rptnm = t_vs_hr_long;
%let ttl1 = Vital Signs - Pulse Rate (beats per minute);
%pul;

%let paramcd = HEIGHT;
%let rptnm = t_height_long;
%let ttl1 = Height (cm);
%pul;

%let paramcd = WEIGHT;
%let rptnm = t_weight_long;
%let ttl1 = Weight (kg);
%pul;


%&_x_x_debug.post_process_setup;

