
dm log 'clear';
dm lst 'clear';
dm log 'preview';

/****************************Ending of Standard Top Codes************************************************************/

proc format;
   value trt01an
   1=1
   2=2
   3=3;

    picture pvalj (round default=6)
      0 - < 0.001   ="<.001" (noedit)
      0.001 -  1   ="9.999" ;
run;

%macro t_lv_echo(report_name=,subset=, visitlabel=);

%let rptnm=&report_name;

*================================================================;
*Reading input datasets;
*================================================================;

proc sql;
   create table adxp as 
      select * 
      from adam.adxp
      where
      adxp.saffl="Y" and XPCAT="ECHOCARDIOGRAM" and ADXP.AVISIT in ("BASELINE","WEEK 24","WEEK 36","WEEK 48")  
       and &subset. and adxp.BASETYPE="DOUBLE-BLIND"
      order by usubjid,paramcd,avisitn;

   create table postbaseline as
      select distinct usubjid, paramcd
      from adam.adxp
      where ady gt 1 and &subset.
      order by usubjid,paramcd;

   create table adsl as
      select * 
      from adam.adsl
      where saffl="Y";
quit;

data adxp02;
   merge adxp(in=a) postbaseline(in=b);
   by usubjid paramcd;
   if a and b then aandb=1;
   if a and not b then anotb=1;
   if not a and b then bnota=1;
   if aandb;
run;

data adxp03;
   set adxp;
   ord=avisitn;
run;

proc sort data=adxp03;
   by paramcd param ord trt01an;
run;

proc summary data=adxp03 completetypes nway;
   by paramcd param ord;
   class trt01an/preloadfmt;
   format trt01an trt01an.;
   where not missing(aval);
   var aval;
   output out=aval_stats(drop=_type_ _freq_)
   n= mean= std= median= /autoname;
run;

data aval_stats2;
   set aval_stats;
   length c3-c6 $20;
   by paramcd param ord;
   c3=put(aval_n,3.);
   c4=put(aval_mean,6.2);
   c5=put(aval_stddev,7.3);
   c6=put(aval_median,6.2);

   drop aval_:;
run;

proc sort data=adxp03;
   by paramcd ord trt01an;
run;


ods output lsmeans=lsmeans;
ods output diffs=diffs;
ods output tests3=tests3;


proc mixed data=adxp03;
   by paramcd ord;
   where ord in (5,6,7);
   class trt01an ;
   model chg=base trt01an;
   lsmeans  trt01an/diff cl ;
run;

ods output close;

data lsmeans01;
   set lsmeans;
   length c7 c8 $20;
   if not missing(estimate) then c7=put(round(estimate,0.01),6.2);
   if not missing(stderr) then c8=put(round(stderr,0.001),7.3);
   keep ord trt01an paramcd c7 c8;
run;

data diffs01;
   set diffs;
   length c10 c11 c12 c9 $30;
   if trt01an in (1,2) and _trt01an=3;* and ord=_ord;
   if not missing(estimate) then c9=put(round(estimate,0.01),6.2);
   if not missing(stderr) then c10=put(round(stderr,0.001),7.3);
   if not missing(lower) and not missing(upper) then c11="("||put(round(lower,0.01),6.2)||", "||put(round(upper,0.01),5.2)||")";
   if missing(probt) then c12="-";
   else c12=put(probt,6.3);
   *keep ord trt01an paramcd c10 c11 c12 c9;
run;  

proc sql;
   select count(distinct usubjid) into :n1 from adsl where trt01an=3;
   select count(distinct usubjid) into :n2 from adsl where trt01an=1;
   select count(distinct usubjid) into :n3 from adsl where trt01an=2;
run;

data aval_stats03;
   set aval_stats2;
   length c1 c2 $50;
   if trt01an=3 then c1="Placebo (N=%cmpres(&n1))";
   else if trt01an=1 then c1="Active 0.3mg/kg (N=%cmpres(&n2))";
   else if trt01an=2 then c1="Active 0.6mg/kg (N=%cmpres(&n3))";

   if ord=0 then c2="Baseline";
   else if ord =5 then c2="Week 24";
   else if ord=6 then c2="Week 36";
   else if ord=7 then c2="Week 48";

run;

proc sort data=aval_stats03;
   by paramcd trt01an ord;
run;

proc sort data=lsmeans01;
   by paramcd trt01an ord;
run;

proc sort data=diffs01;
   by paramcd trt01an ord;
run;

data final_pre;
   merge aval_stats03(in=a) lsmeans01(in=b) diffs01(in=c);
   by paramcd trt01an ord;
run;

data final_pre;
   set final_pre;
   if trt01an=3 then trt01an=0;
run;

proc sort data=final_pre out=final(keep=c:);
   by trt01an ord;
run;

data final;
   retain c1-c12;
   set final;
run;

/****************************Begining of Standard Bottom Codes************************************************************/


data out.ir_&rptnm._val ;
   set final;
run;

proc printto print=print;
run;

data ir_&rptnm._val;
   set final;
   array temp[*] _char_;
   do i=1 to dim(temp);
   temp[i]=compress(temp[i]);
   end;
   drop i;
run;

data &rptnm._val;
   set custom.&rptnm._val;
   array temp[*] _char_;
   do i=1 to dim(temp);
   temp[i]=compress(temp[i]);
   end;
   drop i;
run;
proc compare base = ir_&rptnm._val compare = &rptnm._val listall;
   id c1 c2  notsorted;
run;

proc printto print=lst;
run;

proc compare base = ir_&rptnm._val compare = &rptnm._val listall;
   id c1 c2  notsorted;
run;

%mend;

%t_lv_echo(report_name=t_lvef_echo,subset=%str(paramcd in ("LVEF") ));




