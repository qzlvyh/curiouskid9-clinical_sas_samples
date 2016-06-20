
dm log 'clear';
dm lst 'clear';
dm log 'preview';


%let pgm_name=t_os;
%let rptnm=&pgm_name.;


%pre_process_setup;

proc sort data=adam.adtte out=adtte;
   by usubjid aseq;
   where paramcd="OS";
run;

proc sort data=adam.adsl out=adsl(keep=usubjid trt01an);
   by usubjid;
   where pprotfl="Y" and trt01an in (1,2);
run;

data adsl;
   set adsl;
   output;
   trt01an=3;
   output;
run;

data adtte ;
   set adtte;
   output;
   trtan=3;
   output;
run;

proc sort data=adsl;
   by usubjid trt01an;
run;

proc sort data=adtte;
   by usubjid trtan;
run;

data adtte;
   merge adtte(in=a) adsl(in=b rename=(trt01an=trtan));
   by usubjid trtan;
   if a and b;
run;

proc sql noprint;
   select count(distinct usubjid) into :n1 from adsl where trt01an=1;
   select count(distinct usubjid) into :n2 from adsl where trt01an=2;
   select count(distinct usubjid) into :n3 from adsl where trt01an=3;
quit;

data trttotal;
   trtan=1; trttotal=coalesce(&n1,0); output;
   trtan=2; trttotal=coalesce(&n2,0); output;
   trtan=3; trttotal=coalesce(&n3,0); output;
run;

*-------------------------------------------------------------------;
*creating dummy shell to handle the very sparse data;
*-------------------------------------------------------------------;
data shell;
   length c1 $100 c2 c3 c4 $30;
   group=1;
   ord=1;
   c1="Number (%) of Patients with Events";
   c2="  0 (  0.0)";
   c3=c2;
   c4=c2;
   output;
   group=2;
   ord=0;
   c1="Number (%) of Patients Censored";
   output;
   group=3;
   ord=1;
   c1="Minimum, days";
   c2="  -";
   c3=c2;
   c4=c2;
   output;
   ord=2;
   c1="25th percentile (95% CI)";
   c2="  -  (  -,  - )";
   c3=c2;
   c4=c2;
   output;
   ord=3;
   c1="Median (95% CI)";
   output;
   ord=4;
   c1="75th percentile (95% CI)";
   output;
   ord=5;
   c1="Maximum";
   c2="  -";
   c3=c2;
   c4=c2;
   output;

   group=4;
   ord=0;
   c1="Probability (%) that overall survival time is at least:";
   c2="";
   c3="";
   c4="";
   output;
   ord=1;
   c1="3 Months (95% CI)";
   c2="  -  (  -,  - )";
   c3=c2;
   c4=c2;
   output;
   ord=2;
   c1="6 Months (95% CI)";
   output;
   ord=3;
   c1="12 Months (95% CI)";
   output;
run;

 
*=========================================================================;
*core processing;
*=========================================================================;

*----------------------------------;
*group 1: events;
*----------------------------------;
proc sql;
   create table group1 as 
      select trtan, 1 as group, 1 as ord, count(distinct usubjid) as count
      from adtte
      where cnsr=0
      group by trtan;
quit;

data dummy_group1;
   do trtan=1 to 3;
      do group=1;
         do ord=1;
         count=0;
         output;
         end;
      end;
   end;
run;

data group1;
   merge dummy_group1 group1;
   by trtan;
run;

data group1;
   merge group1 trttotal;
   by trtan;
run;

data group1;
   set group1;
   length cp $30;
   if trttotal ne 0 then cp=put(count,3.)||" ("||put(count/trttotal*100,5.1)||")";
   keep group ord trtan cp;
run;

proc transpose data=group1 out=trans_group1(drop=_:) prefix=trt;
   by group ord;
   var cp;
   id trtan;
run;

data trans_group1;
   set trans_group1;
   length c2-c4$30;
   c2=trt1;
   c3=trt2;
   c4=trt3;
   keep group ord c2-c4;
run;

data final_1;
   merge shell trans_group1;
   by group ord;
run;



*---------------------------------------------------------;
*group 2 : number of patients censored;
*---------------------------------------------------------;

proc sql;
   create table group2 as 
      select trtan, 2 as group, 0 as ord,"Number (%) of Patients Censored" as c1 length=100,
      coalesce(count(distinct usubjid),0) as count
      from adtte
      where cnsr=1
      group by trtan

      union all corr

      select trtan, 2 as group, 1 as ord,"  "||strip(propcase(evntdesc)) as c1 length=100,
      coalesce(count(distinct usubjid),0) as count
      from adtte
      where cnsr=1
      group by trtan,evntdesc;
quit;

proc sort data=group2;
   by group ord c1;
run;

data group2;
   set group2(rename=(ord=old_ord));
   by group old_ord c1;
   retain ord;
   if old_ord=0 then ord=0;
   else if old_ord=1 and first.c1 then ord=ord+1;
   drop old_ord;
run;

proc sort data=group2;
   by trtan;
run;

data group2;
   merge group2(in=a) trttotal;
   by trtan;
   if a;
run;

data group2;
   set group2;
   length cp $30;
   if trttotal ne 0 then cp=put(count,3.)||" ("||put(count/trttotal*100,5.1)||")";
run;

proc sort data=group2;
   by group ord c1;
run;

proc transpose data=group2 out=trans_group2(drop=_:) prefix=trt;
   by group ord c1;
   var cp;
   id trtan;
run;

data trans_group2;
   set trans_group2;
   length c2-c4 $30;
   c2=trt1;
   c3=trt2;
   c4=trt3;
   keep group ord c1-c4;
run;

data final_2;
   merge final_1 trans_group2;
   by group ord c1;
run;

*-----------------------------------------------------------;
*group 3 : min max;
*-----------------------------------------------------------;
proc sort data=adtte;
   by trtan;
run;

proc summary data=adtte;
   by trtan;
   var aval;
   output out=group3_minmax min= max=/autoname;
run;

data dummy_group3;
   call missing(trtan,aval_min, aval_max);
run;

data group3_minmax2;
   if 0 then set dummy_group3;
   set group3_minmax;
   length min max $30;
   if not missing(aval_min) then min=put(aval_min,3.);
   if not missing(aval_max) then max=put(aval_max,3.);
run;

proc transpose data=group3_minmax2 out=trans_group3mm;
   by trtan;
   var min max;
run;

data trans_group3mm;
   if 0 then do; length col1 $30; col1=""; end;
   set trans_group3mm;
   if _name_="min" then ord=1;
   if _name_="max" then ord=5;
   group=3;
run;

proc sort data=trans_group3mm;
   by group ord;
run;

proc transpose data=trans_group3mm out=trans_group3mm2 prefix=trt;
   by group ord;
   var col1;
   id trtan;
run;

data trans_group3mm2;
   set trans_group3mm2;
   length c2-c4 $30;
   c2=trt1;
   c3=trt2;
   c4=trt3;
   keep group ord c2-c4;
run;

ods output ProductLimitEstimates = ple;
ods output Quartiles = quart (drop = stratum);

proc lifetest data=adtte method=km timelist=91.3125,182.625,365.25 reduceout outsurv=survest alpha=0.05;
   time aval*cnsr(1);
   strata trtan;
run;
ods output close;

data group4_surv;;
   set survest;
   length cp  $30 x1 $5 x2 x3 $6;
   if not missing(survival) then x1=put(survival*100,5.1);
   else x1="  -";
   if not missing(sdf_lcl) then x2=put(sdf_lcl*100,5.1);
   else x2="  -";
   if not missing(sdf_ucl) then x3=put(sdf_ucl*100,5.1);
   else x3="  -";
   cp= x1||" ("||x2||", "||x3||")";
   group=4;
   if timelist=91.3125 then ord=1;
   else if timelist=182.625 then ord=2;
   else if timelist=365.25 then ord=3;
   keep group ord cp trtan;
run;

proc sort data=group4_surv;
   by group ord;
run;

proc transpose data=group4_surv out=trans_group4(drop=_:) prefix=trt;
   by group ord;
   var cp;
   id trtan;
run;

data trans_group4;
   set trans_group4;
   length c2-c4 $30;
   c2=trt1;
   c3=trt2;
   c4=trt3;
   keep group ord c2-c4;
run;

data group3_quart;
   set quart;
   length cp  $30 x1 $5 x2 x3 $6;
   if not missing(estimate) then x1=put(estimate,5.1);
   else x1="  -";
   if not missing(lowerlimit) then x2=put(lowerlimit,6.2);
   else x2="  -";
   if not missing(upperlimit) then x3=put(upperlimit,6.2);
   else x3="  -";
   cp= trim(x1)||" ("||x2||", "||x3||")";
   group=3;
   if percent=25 then ord=2;
   else if percent=50 then ord=3;
   else if percent=75 then ord=4;
   keep group ord cp trtan;
run;

proc sort data=group3_quart;
   by group ord;
run;

proc transpose data=group3_quart out=trans_group3quart(drop=_:) prefix=trt;
   by group ord;
   var cp;
   id trtan;
run;

data trans_group3quart;
   set trans_group3quart;
   length c2-c4 $30;
   c2=trt1;
   c3=trt2;
   c4=trt3;
   keep group ord c2-c4;
run;

data final_group3;
   set trans_group3mm2 trans_group3quart;
   by group ord;
run;

data final_3;
   merge final_2 final_group3;
   by group ord;
run;

data final;
   merge final_3 trans_group4;
   by group ord;
run;

data custom.&rptnm._val;
   set final;
   keep c1-c4;
run;



%post_process_setup;
