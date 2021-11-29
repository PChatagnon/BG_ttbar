// main04.cc is a part of the PYTHIA event generator.
// Copyright (C) 2019 Torbjorn Sjostrand.
// PYTHIA is licenced under the GNU GPL v2 or later, see COPYING for details.
// Please respect the MCnet Guidelines, see GUIDELINES for details.

// This is a simple test program.
// It illustrates how to generate and study "total cross section" processes,
// i.e. elastic, single and double diffractive, and the "minimum-bias" rest.
// All input is specified in the main06.cmnd file.
// Note that the "total" cross section does NOT include
// the Coulomb contribution to elastic scattering, as switched on here.

#include "Pythia8/Pythia.h"

using namespace Pythia8;

//==========================================================================

int main(int argc, char* argv[]) {

  // Generator.
  Pythia pythia;

  // Read in commands from external file.

  cout<<argv[1]<<" "<<argv[2]<<endl; 
  
  string inputConfig ="";
  if(string(argv[1])=="ttbar"){inputConfig="pythia8.cmnd";}
  else if(string(argv[1])=="Diff"){inputConfig="SD_pythia8.cmnd";}

  pythia.readFile(inputConfig);
  //pythia.readFile("SD_pythia8.cmnd");

  cout<<"Start Pythia with "<<inputConfig<<endl;

  // Setup the process
  pythia.readString("Top:gg2ttbar = on");    
  pythia.readString("Top:qqbar2ttbar = on");    
  pythia.readString("PartonLevel:MPI = on"); 
 
  // Extract settings to be used in the main program.
  int    nEvent    = atoi(argv[3]);//= pythia.mode("Main:numberOfEvents");
  int    nAbort    = pythia.mode("Main:timesAllowErrors");

  cout<<"Number of events to be simulated "<<nEvent<<endl;  

  // Create an LHAup object that can access relevant information in pythia.
  //LHAupFromPYTHIA8 myLHA(&pythia.process, &pythia.info); // hard process only
  LHAupFromPYTHIA8 myLHA(&pythia.event, &pythia.info);   // full event info

  // Open a file on which LHEF events should be stored, and write header.
  myLHA.openLHEF(argv[2]);
  //myLHA.openLHEF("tt_pythia8.lhe");
  //myLHA.openLHEF("SD_tt_pythia8.lhe");
  
  // Initialize.
  pythia.init();
  
  // Store initialization info in the LHAup object.
  myLHA.setInit();
  
  // Write out this initialization info on the file.
  myLHA.initLHEF();

  // Begin event loop.
  int iAbort = 0; int iEvent = 0;
  while (iEvent < nEvent) {

    // Generate events. Quit if too many failures.
    if (!pythia.next()) {
      if (++iAbort < nAbort) continue;
      cout << " Event generation aborted prematurely, owing to error!\n";
      break;
    }


	// store only AB->AX
	//if(pythia.info.code()!=code) continue;
	iEvent++;
	// store only 
	// Store event info in the LHAup object.
    myLHA.setEvent();

	// Write out this event info on the file.
    // With optional argument (verbose =) false the file is smaller.
    myLHA.eventLHEF();

  // End of event loop.
  }

  // Final statistics and histograms.
  pythia.stat();

  // Update the cross section info based on Monte Carlo integration during run.
  myLHA.updateSigma();
  
  // Write endtag. Overwrite initialization info with new cross sections.
  myLHA.closeLHEF(true);
  
  // Done.
  return 0;
}
