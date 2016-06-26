
proc template;
   define statgraph mline;
      dynamic _xvar _yvar _errl _errh _byval3_ _byval4_;
      nmvar tlistmax;
      begingraph;

          entrytitle "Parameter = " _byval3_  / 
          textattrs=(size=9pt /*weight=bold*/) pad=(bottom=20px);

         %*Colour map - has to match variable by text or format;
         discreteattrmap name='colors' / ignorecase=true;
            value "Placebo"  / lineattrs  =(color=black   pattern=shortdash) markerattrs=(color=black);
            value "Active"  / lineattrs  =(color=blue  pattern=longdash) markerattrs=(color=blue);
         enddiscreteattrmap;
         discreteattrvar attrvar=groupmarkers var=trtan attrmap='color';

         %*Define 2 block layout and size*;
         layout lattice /rows=3 columns=1 rowweights=(.9 .05 .05) columndatarange=union;

            %*Mean +/- plot*;
            layout overlay /
               xaxisopts=(type=linear label="Visit"
                 linearopts=(tickvaluelist=(0 12 24 36 52 76 104) /*_byval4_*/ tickvaluefitpolicy=stagger)
                 tickvalueattrs=(size=8pt))
               yaxisopts=(label=_byval3_
                 linearopts=(thresholdmin=0 thresholdmax=1));
               seriesplot x=_xvar y=_yvar  / group=groupmarkers name="series" break=true;
               scatterplot x=_xvar y=_yvar / group=groupmarkers name="scatter" primary=true
                 yerrorlower=_errl yerrorupper=_errh;
               mergedlegend "scatter" "series"  /
                 location=outside valign=bottom halign=center
                 across=2 displayclipped=true valueattrs=(size=8pt);
               endlayout;

             layout overlay;
                 entry halign=left 'Number of Subjects' /valign=top;
             endlayout;

               %*Freq plot *;
               layout overlay /
                  xaxisopts=(type=linear display=none linearopts=(tickvaluelist=_byval4_)) walldisplay=none;
                  blockplot x=eval(int(_xvar)) block=numsc / class=trtan 
                     display=(values label)
                     valuehalign=start 
                     repeatedvalues=true 
                     labelattrs=(family="Arial" size=8pt)
                     valueattrs=(family="Arial" size=8pt);
               endlayout;
            endlayout;
      endgraph;
   end;
run;
