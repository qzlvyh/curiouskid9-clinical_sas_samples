
%let _x_x_debug=; 
dm log 'clear';
dm lst 'clear';
dm output 'clear';
options mprint;


%let pgm_name=t_ecg_central_long;

%&_x_x_debug.pre_process_setup;

%let rptnm=t_ecg_central_long;

proc format;
   value treatment
      1=1 2=2 3=3 4=4 5=5 6=6;
run;
 
*--------------------------------------------------------------------;
*Reading input datasets;
*--------------------------------------------------------------------;

proc sort data=adam.adsl out=adsl (keep=usubjid trt: tr:);
   by usubjid ;
   where saffl="Y";
run;

proc sort data=adam.adegs out=adegs;
   by usubjid paramcd param avisitn avisit;
   where saffl="Y" and paramcd in ("HRMEAN","PRMEAN","QRSDUR","QTMEAN","QTCF","QTCB","RRMEAN")
         and ((AVISIT="BASELINE" and BASETYPE="LONG TERM") or (AVISIT="ENDPOINT" and BASETYPE="LONG TERM" )) ;
run;

data adegs;
   merge adegs(in=a) adsl(in=b);
   by usubjid;
   if a and b;
run;

data adsl;
   set adsl;
    if trt01an=3 then do;
         treatment=3;
         output;
      if trt02an=1 then do;
         treatment=1;
         output;
      end;
      else if trt02an=2 then do;
         treatment=2;
         output;
      end;
   end;
   if (trt02an=1 and trt01an not in (3, .)) or (trt01an=1 and trt02an=.) then do;
      treatment=6;
      output;
      treatment=4;
      output;
   end;

   if (trt02an=2 and trt01an not in (3, .)) or (trt01an=2 and trt02an=.) then do;
      treatment=6;
      output;
      treatment=5;
      output;
   end;  
run;

data adegs;
   set adegs;
    if trt01an=3 then do;
         treatment=3;
         output;
      if trt02an=1 then do;
         treatment=1;
         output;
      end;
      else if trt02an=2 then do;
         treatment=2;
         output;
      end;
   end;
   if (trt02an=1 and trt01an not in (3, .)) or (trt01an=1 and trt02an=.) then do;
      treatment=6;
      output;
      treatment=4;
      output;
   end;

   if (trt02an=2 and trt01an not in (3, .)) or (trt01an=2 and trt02an=.) then do;
      treatment=6;
      output;
      treatment=5;
      output;
   end;  
run;

proc sort data=adegs;
   by paramcd param;
run;

data adegs1 adegs2;
   set adegs;
   if avisit="BASELINE" then output adegs1;
   else if avisit="ENDPOINT" then output adegs2;
run; 
*=======================================================;
*descriptive stats for numeric variables;
*=======================================================;
%macro descriptive(
      indsn=,
      var=,
      label=,
      group=,
      n=,
      mean=,
      sd=,
      min=,
      median=,
      max=
      );

proc summary data=&indsn. completetypes nway;
   by paramcd param;
   class treatment/preloadfmt;
   format treatment treatment.  ;
   where not missing(&var.);
   var &var.;
   output out=&var._stats(drop=_type_ _freq_)
   n= mean= std= min= median= max= /autoname;
run;

data &var._stats2;
   set &var._stats;
   n=put(&var._n,&n.);
   mean=put(&var._mean,&mean.);
   sd=put(&var._stddev,&sd.);
   min=put(&var._min,&min.);
   median=put(&var._median,&median.);
   max=put(&var._max,&max.);

   drop &var._:;
run;

proc transpose data=&var._stats2 out=&var._stats3(drop=_name_) label=statistic;
   by paramcd param treatment ;
   var n mean sd min median max;
   label n="n"
         mean="Mean"
         sd="SD"
         min="Min"
         median="Median"
         max="Max";
run;

data &var._stats4;
   set &var._stats3;
   select(statistic);
      when("n") intord=1;
      when ("Mean") intord=2;
      when ("SD") intord=3;
      when ("Min") intord=5;
      when ("Median") intord=4;
      when ("Max") intord=6;
   otherwise;
   end;
run;

proc sort data=&var._stats4;
   by  paramcd param intord statistic;
run;

proc transpose data=&var._stats4 out=_final_stats_&var. prefix=&var._;
   by  paramcd param intord statistic;
   var col1;
   id treatment ;
run;

data final_stats_&var.;
   set _final_stats_&var.;
   length c1-c2 $200;
   c1=param;
   c2=statistic;
   keep paramcd intord c1 c2 &var._:;
run;

%mend;

%descriptive(
      indsn=adegs1,
      var=aval,
      n=4.,
      mean=6.1,
      sd=7.2,
      min=6.1,
      median=6.1,
      max=6.1
      );

%descriptive(
      indsn=adegs2,
      var=chg,
      n=4.,
      mean=6.1,
      sd=7.2,
      min=6.1,
      median=6.1,
      max=6.1
      );

data finalstats;
   merge final_stats_aval final_stats_chg;
   by paramcd c1 intord c2;
run;

data finalstats;
   set finalstats;
   if upcase(PARAMCD)="QTMEAN" then do; paramn=1; c1="QT Interval (msec)"; end;
   else if upcase(PARAMCD)="QTCF" then do; paramn=2; c1="QTcF (msec)"; end;
   else if upcase(PARAMCD)="QTCB" then do; paramn=3; c1="QTcB (msec)"; end;
   else if upcase(PARAMCD)="RRMEAN" then  do; paramn=4; c1="RR Interval (msec)"; end;
   else if upcase(PARAMCD)="PRMEAN" then  do; paramn=5; c1="PR (msec)"; end;
   else if upcase(PARAMCD)="QRSDUR" then  do; paramn=6; c1="QRS (msec)"; end;
   else if upcase(PARAMCD)="HRMEAN" then  do; paramn=7; c1="HR (beats/min)"; end;
run;

data final;
   set finalstats;
   length c3 - c14 $20;
   c3=aval_1;
   c4=chg_1;
   c5=aval_2;
   c6=chg_2;
   c7=aval_3;
   c8=chg_3;
   c9=aval_4;
   c10=chg_4;
   c11=aval_5;
   c12=chg_5;
   c13=aval_6;
   c14=chg_6;
   c2="  "||strip(c2);
   if paramn in (1,2) then page=1;
   else if paramn in (3,4) then page=2;
   else if paramn in (5,6) then page=3;
   else page=4;
   keep page paramn intord c1-c14;
run;

proc sort data=final;
   by page paramn intord;
run;

data custom.t_ecg_central_long_val;
   set final;
   keep c1-c14;
run;

proc sql noprint;
   select count(distinct usubjid) into :n1-:n6 from adsl group by treatment;
quit;


%&_x_x_debug.post_process_setup;

