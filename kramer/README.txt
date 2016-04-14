

This should contain the original Kramer model code from Jason. The code should be unchanged, except I added a single function called

kramer/kramer/kramer_remove_all_but_IB.m

This implements the full kramer model with the B, RS, and LTS cells cut out. This is a test to make sure that the model IB cells in the kramer model are the same as the kramer_IB model. IT appears that they are (see Google Doc presentation)




~~~ Jason's original email ~~~

I've attached two models:
(1) kramer.zip contains the full RS-B-LTS-IB model
(2) kramer_IB.zip contains the 4-compartment IB model only

To run the simulation, unzip a model, move (in Matlab) to the directory containing all the files, and execute the m-file therein. 

I've tried to take all variable names and values from the supp material for the 2008 paper. I'm not sure it's behaving as it should though. If you find any problems let me know; I'll try to look at this more later and see if it reproduces results from the paper. Unfortunately I wasn't able to find the exact model I worked with a couple years ago; hopefully this version will be useful. I stayed home today because of the closing but can discuss it in person tomorrow if you'll be at BU.

(3) kramer.m
I've attached a different version of kramer.m that includes an additional parameter (sup_fanout) for adjusting the fanout among superficial cells. In the version I sent a minute ago, the connectivity is all-to-all. In this script, it can be set to all-to-all (sup_fanout=inf) or local modules (sup_fanout=.5); the latter may be what Mark used in the paper; the difference may be insignificant though because of the gap junctions connecting RS cells and the all-to-all connectivity from IB axons to superficial interneurons.
