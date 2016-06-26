*** GTL Template to create dot and forest plot ***;
proc template;
  define statgraph ForestPlot_3Col; 
  dynamic _pct; 
  begingraph;
  layout lattice / columns=3 columngutter=0 columnweights=(.5 .2 .3);   
      legendItem type=marker name="Active" / markerattrs=(color=blue symbol=trianglefilled)
        label="Active"; 
      legendItem type=marker name="plb" / markerattrs=(color=red symbol=circlefilled)
        label="Placebo"; 

  *** Frequency plot ***;
    layout overlay /
                   yaxisopts=(type=discrete reverse=true display=(tickvalues) tickvalueattrs=(size=8pt)) 
                   xaxisopts=(type=linear offsetmin=0.05 offsetmax=0.052 
                   label="Percentage of Subjects" griddisplay=on
                   linearopts=(viewmin=0 thresholdmax=1));

      scatterplot y=paramn x=pct1 / markerattrs=(color=blue symbol=trianglefilled size=3pct);
      scatterplot y=paramn x=pct2 / markerattrs=(color=red symbol=circlefilled size=3pct);
      discretelegend "Active" "plb" / across=1 location=outside valign=bottom;
    endlayout;

  *** HR plot ***;
    layout overlay / 
                   yaxisopts=(type=discrete reverse=true display=none) 
                   xaxisopts=(type=linear offsetmin=0.12 offsetmax=0.1 
                   label="Hazard Ratio" griddisplay=off
                   linearopts=(tickvaluefitpolicy=thin viewmin=0 viewmax=4 tickvaluelist=(0 1 2 3 4)));

      referenceline x=0 / lineattrs=(pattern=solid) datatransparency=0.5; 
      referenceline x=1 / lineattrs=(pattern=solid) datatransparency=0.5; 
      referenceline x=2 / lineattrs=(pattern=solid) datatransparency=0.5; 
      referenceline x=3 / lineattrs=(pattern=solid) datatransparency=0.5; 
      referenceline x=4 / lineattrs=(pattern=solid) datatransparency=0.5; 

      highlowplot y=paramn low=dlowercl high=duppercl /  /*type=bar barwidth=0.1 fillattrs=(color=black)*/
          type=line lineattrs=(color=black pattern=solid)
         lowcap=lcap highcap=hcap ;
      scatterplot y=paramn x=dhr / markerattrs=(color=black symbol=circlefilled size=3pct);
      entry  halign=center "Active vs Placebo" 
          / textattrs=(size=8pt) pad=(right=2.75%) location=outside valign=bottom;
    endlayout;

  *** Statistics ***;
    layout overlay / walldisplay=none border=false
                   yaxisopts=(reverse=true type=discrete display=none)
                   xaxisopts=(type=linear display=none offsetmin=0.15 offsetmax=0.1);
      entry  halign=left "            " halign=center "         (N=&pop1.)      (N=&pop2.)" 
          / textattrs=(size=8pt) pad=(right=2.75%) location=outside valign=top;
      entry  halign=left "  (95% CI)  " halign=center "          Active Placebo " 
          / textattrs=(size=8pt) pad=(right=3%) location=outside valign=top;
      entry  halign=left "Hazard Ratio" halign=center "          N (%) of Events" halign=right "P-value" 
          / textattrs=(size=8pt) pad=(right=2.75%) location=outside valign=top;  

      scatterplot y=paramn x=eval(constant*1) / markercharacter=ci;
      scatterplot y=paramn x=eval(constant*1.9) / markercharacter=nevntc;
      scatterplot y=paramn x=eval(constant*2.7) / markercharacter=pval;
    endlayout; 

  endlayout;
  endgraph;
  end;
run;
