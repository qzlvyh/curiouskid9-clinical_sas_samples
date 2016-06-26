 *** Plot template for clustered bar chart with subgroup ***;
   proc template;
      define statgraph ffg_002;
         begingraph;

          
            %*Colour map - has to match variable by text - same values as DSTREAS;
            discreteattrmap name='colors' / ignorecase=true;
            value "Adverse Event"  / fillattrs=(color=blue transparency=0.7 );
            value "Death"          / fillattrs=(color=red transparency=0.7);
            value "Lack Of Efficacy" / fillattrs=(color=green transparency=0.7);
            value "Lost To Follow-Up"     / fillattrs=(color=yellow transparency=0.7);
            value "Protocol Deviation" / fillattrs=(color=brown transparency=0.7);            
            value "Withdrawal By Subject" / fillattrs=(color=purple transparency=0.7);
            value "Physician Decision"    / fillattrs=(color=black transparency=0.7 );
            value "Non-Compliance With Study Drug" / fillattrs=(color=grey transparency=0.7);
            value "Other"          / fillattrs=(color=pink transparency=0.7);
            enddiscreteattrmap;
            discreteattrvar attrvar=groupmarkers var=dstreasn attrmap='colors';
            layout gridded/ border=false;
               layout datalattice columnvar=exdgr1n / border=false              
                  headerlabeldisplay=value  columnheaders=bottom /* headeropaque=true*/
                  columndatarange=union
                  headerbackgroundcolor=GraphAltBlock:color   /*headerlabelattrs=(weight=bold)*/
                  rowaxisopts=(offsetmin=0 display=(ticks tickvalues label) griddisplay=on 
                  linearopts=(thresholdmax=1))
                  columnaxisopts=(display=(ticks tickvalues));
                  layout prototype /;
                     barchart X=
                 %if &var.=saffl %then %do;
                            trt01an
                   %end;
                 %else %if &var.=fasfl %then %do;
                            trt01pn
                 %end;
                   y=percnt/ 
                        group=groupmarkers name="group" 
                        /*groupdisplay=cluster*/
                     includemissinggroup=true
                     dataskin=crisp 
                     /*                     barlabel=true*/

                     /*                     barlabelattrs=(size=2PT)*/
                     datatransparency=0.8
                     display=(fillpattern fill outline)
                     ;
                  endlayout;
               endlayout;
                entry ' ';
               discretelegend 'group' /location=outside halign=right 
                valign=center borderattrs=(color=black);                
               
            endlayout;
         endgraph;
      end;
   run;

   *** Template to remove border around column header ***;
   proc template;
      define style styles.noheaderborder;
         parent = styles.default;
         class graphborderlines /
            contrastcolor=white
            color=white;
         class graphbackground / 
            color=white;

                  *define the different bar styles;
         style GraphData1 from GraphData1/ fillpattern='L1';
         style GraphData2 from GraphData2/ fillpattern='X1';
         style GraphData3 from GraphData3/ fillpattern='R1';
         style GraphData4 from GraphData4/ fillpattern='L5';
         style GraphData5 from GraphData5/ fillpattern='X5';
         style GraphData6 from GraphData6/ fillpattern='R5';
         style GraphData7 from GraphData7/ fillpattern='L3';
         style GraphData8 from GraphData8/ fillpattern='X3';
         style GraphData9 from GraphData9/ fillpattern='R3';
      end;
   run;