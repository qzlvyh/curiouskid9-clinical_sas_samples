
dm log 'clear';
dm lst 'clear';
dm log 'preview';


%let pgm_name=t_teae_max_sum;
%let rptnm=&pgm_name.;


%pre_process_setup;

*================================================;
*format for toxicity grade;
*================================================;

proc format;
   value atoxgr
   10="Any grade"
   11="1/2"
   12="3/4/5"
   13="5";
run;

*====================================================;
*obtaining the required input datasets;
*====================================================;

data adsl;
   set adam.adsl;
   where saffl="Y";
run;

data adsl;
   set adsl;
   output;
   trt01an=9;
   output;
run;

data adae;
   set adam.adae;
   where saffl="Y" and trtan in (1,2);
   if missing(asoc) then asoc="Not coded";
   if missing(adecod) then adecod="Not coded";
   if not missing(atoxgrn) then atoxgrn_new=10;
   output;
   if atoxgrn in (1,2) then atoxgrn_new=11;
   output;
   if 3 le atoxgrn le 5 then atoxgrn_new=12;
   output;
   if atoxgrn = 5 then atoxgrn_new=13;
   output;
run;

data adae(rename=(atoxgrn_new=atoxgrn));
   set adae;
   where atoxgrn_new in (10 11 12 13);
   drop atoxgrn;
run;

data adae;
   set adae;
   output;
   trtan=9;
   output;
run;

*====================================================;
*obtaining treatment counts into macro variable;
*====================================================;

proc sql noprint;
   select count(*) into :n1 from adsl where trt01an=1;
   select count(*) into :n2 from adsl where trt01an=2;
   select count(*) into :n9 from adsl where trt01an=9;
   select count(*) into :m1 from adsl where trt01an=1 and sex="M";
   select count(*) into :f1 from adsl where trt01an=1 and sex="F";
quit;


%put total subjects :&n1;
%put total male subjects :&m1;
%put total female subjects :&f1;

*==========================================================;
*creating trteatment counts/gender counts dataset;
*==========================================================;

data trtcount;
   trtan=1;
   trtcount=&n1;
   malecount=&m1;
   femalecount=&f1;
   output;
   trtan=2;
   trtcount=coalesce(&n2,0);
   output;
   trtan=9;
   trtcount=coalesce(&n9,0);
   output;
run;

proc sort data=trtcount;
   by trtan;
run;


*===================================================================;
*lables and references for footnotes-dynamic;
*===================================================================;
%let deathref=;
%let death30ref=;
%let deathfnote=;


%macro footnote;
proc sql noprint;
   select count(*) into :deaths from adae where dthonfl="Y";
   select count(*) into :deaths30 from adae where DTH30FL="Y";
quit;

%if &deaths gt 0 %then %do;
   %let deathref=*c;
%end;

%if &deaths30 gt 0 %then %do;
   %let death30ref=*c;
%end;

%let deathsoverall=%eval(&deaths+&deaths30);

%if &deathsoverall gt 0 %then %do;
   %let deathfnote=*c - Deaths are also included as serious adverse events and discontinuations due to adverse events.;
%end;

%mend;
options mprint symbolgen;

%footnote;

%put &deathref;
%put &death30ref;
options nomprint nosymbolgen;


*===========================================================;
*treatment-wise counts;
*===========================================================;

proc sql;
   create table counts as 
      select "Subjects with >= 1 TEAE" as label length=200, 
      "" as asoc length=200,
      "" as adecod length=200,ATOXGRN ,
      count(distinct usubjid) as count, trtan 
         from adae where amaxfl="Y"
            group by trtan,ATOXGRN 

   union all corr 

      select asoc, asoc as label length=200,
      "" as adecod length=100,ATOXGRN ,
      count(distinct usubjid) as count, trtan
         from adae where amaxsfl="Y"
            group by trtan,asoc,ATOXGRN 

   union all corr

      select asoc length=200,"  "||strip(adecod) as label length=200,
      adecod length=200,ATOXGRN ,
      count(distinct usubjid) as count, trtan 
         from adae where amaxpfl="Y"
            group by trtan,asoc,adecod,ATOXGRN 
      order by asoc,adecod,ATOXGRN ,trtan;
quit;

proc sort data=adae out=termsex(keep=adecod termsex) nodupkey;
   by adecod termsex;
run;

proc sort data=counts;
   by adecod;
run;

data counts;
   merge counts(in=a) termsex(in=b);
   by adecod;
   if a;
run;

*==================================================;
*creating all aectc grades for each pterm level;
*==================================================;


proc sort data=counts out=dummy(keep=asoc adecod label) nodupkey;
   by asoc adecod label;
run;

data dummy;
   set dummy;
   count=0;
   do atoxgrn=10 to 13;
   do trtan=1,2,9;
      output;
   end;
   
   end;
run;

proc sort data=counts out=countsx ;
   by asoc adecod label atoxgrn trtan;
run;

proc sort data=countsx;
   by asoc adecod label atoxgrn trtan;
run;

data counts;
   merge dummy(in=a) countsx(in=b);
   by asoc adecod label atoxgrn trtan;
run;

*========================================================;


proc sort data=counts;
   by trtan;
run;

proc sort data=trtcount;
   by trtan;
run;

data counts;
   merge counts(in=a) trtcount(in=a);
   by trtan;
   if a;
run;

data counts;
   set counts;
   length cp $ 20;
   /*if termsex="M" then 
   do;cp=put(count,3.)|| " ("||put((count/malecount)*100,5.1)||")"; label=trim(label)||"*a"; end;
   if termsex="F" then 
   do; cp=put(count,3.)|| " ("||put((count/femalecount)*100,5.1)||")";label=trim(label)||"*b"; end;
   if missing(termsex) then*/ cp=put(count,3.)|| " ("||put((count/trtcount)*100,5.1)||")";
run;

proc sort data=counts;
   by asoc adecod label atoxgrn;
run;

proc transpose data=counts out=counts2 prefix=trt;
   by asoc adecod label atoxgrn;
   var cp;
   id trtan;
run;

*========================================================;
*obtain socord and ptord;
*========================================================;

*------------------;
*obtain pt total;
*------------------;

data counts2x;
   set counts2;
   by asoc adecod label atoxgrn;
   where atoxgrn =10;
   ptcount=input(scan(trt1,1,"("),best.);
   if first.adecod then call missing(pttotal);
   pttotal+ptcount;
   if last.adecod;
   keep asoc adecod label  pttotal;
run;

*-----------------------;
*get pttotal onto counts;
*-----------------------;

data counts2;
   merge counts2(in=a) counts2x(in=b);
   by asoc adecod label;
run;

*-----------------------;
*socord and ptord;
*-----------------------;

proc sort data=counts2;
   by asoc descending pttotal adecod label;
run;

data temp;
   set counts2;
run;

data counts2;
   set counts2;
   by asoc descending pttotal adecod label;
   if first.asoc then socord+1;
   if first.adecod then ptord+1;
run;

proc sort data=counts2;
   by socord asoc ptord adecod label atoxgrn;
run;


*========================================================;

data final;
   set counts2;
   length c1 $200 c3 c4 c5 $20;
   c1=label;
   c2=put(atoxgrn,atoxgr.);
   c3=trt1;
   c4=trt2;
   c5=trt9;
   if mod(_n_,16)=1 then page+1;
run;

proc sort data=final;
   by socord asoc ptord adecod label atoxgrn;
run;

data custom.&rptnm._val;
   set final;
   keep c1-c5;
run;




%post_process_setup;
