
proc template;
   define statgraph kmplot;
   dynamic x_var y_var1 y_var2 _byval2_;
    begingraph;
         *Graph title;
          entrytitle "Category = " _byval2_ / 
          textattrs=(size=9pt ) pad=(bottom=20px);

         *Colour map;
         discreteattrmap name='colors' / ignorecase=true;
         value 'Active'  / lineattrs=(color=blue pattern=shortdash) markerattrs=(color=blue symbol=trianglefilled);
         value 'Placebo'     / lineattrs=(color=red  pattern=shortdash) markerattrs=(color=red symbol=circlefilled);
         enddiscreteattrmap;
         discreteattrvar attrvar=gmarker var=trtan attrmap='colors';

         %*Define 2 block layout and size*;
         layout lattice /rows=3 columns=1 rowweights=(.83 .03 .14) columndatarange=unionall;

            %*Start KM plot*;
            layout overlay / 
               xaxisopts=(Label="Time at Risk (years)"
               display=(tickvalues line label ticks ) 
               type=linear linearopts=(tickvaluesequence=(start=0 end=2.5 increment=0.5) viewmin=0 viewmax=2.5))
               yaxisopts=( Label="Cumulative Incidence of Subjects with Event"
               type=linear  linearopts= (viewmin=0 viewmax=0.8) );
               StepPlot X=x_var Y=y_var1 / primary=true Group=gmarker
                  LegendLabel="Cumulative Incidence of Subjects with Event" NAME="STEP";

               %*Censored observations are suppressed but can be added here*;
               scatterPlot X=x_var Y=y_var2 / Group=gmarker markerattrs=(symbol=plus)
                      LegendLabel="Censored" NAME="SCATTER";
               DiscreteLegend "STEP"/ 
                  location=outside halign=center valign=bottom across=2 valueattrs=(family="Arial" size=8pt);
            endlayout;

            %*** Define left-aligned title for block ***;
            layout overlay;
               entry halign=left 'Number of Subjects at Risk';
            endlayout;

            %*Start at risk value plot;
            layout overlay /
               xaxisopts=(type=linear display=none) walldisplay=none;
               blockplot x=blkx block=blkrsk / class=trtan 
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
