#!/bin/bash
#./run.sh excl_ttbar 16006 1 QED 15 lephad
startMsg='Job started on '`date`
echo $startMsg
source /cvmfs/cms.cern.ch/cmsset_default.sh

####### USER SETTINGS ###########
basedir=/afs/cern.ch/user/p/pchatagn/BG_TTbar_Interface/
PythiaFolder=/afs/cern.ch/user/p/pchatagn/BG_TTbar_Interface/pythia8306/DiffractiveTTbar/
outfolder=/eos/cms/store/group/phys_top/TTbarDiffractive/mc/TTToSemiLeptonic_NoDiffractive_MiniAOD/
CMSSWFolder=/eos/user/p/pchatagn/CMSSW_10_6_24/

echo "export the voms proxy"
#voms-proxy-init --voms cms --out /afs/cern.ch/user/p/pchatagn/TTbarInterface/GEN_10_6_10_ProtonReco/myproxy509
export X509_USER_PROXY=/afs/cern.ch/user/p/pchatagn/TTbarInterface/GEN_10_6_10_ProtonReco/myproxy509
export HOME=/afs/cern.ch/user/p/pchatagn
#mkdir .dasmaps/
#cp /afs/cern.ch/user/p/pchatagn/.dasmaps/das_maps_dbs_prod.js .dasmaps/.
#echo "check map"
#ls -lrt .dasmaps/
echo $X509_USER_PROXY

#################################
puleupDir=\'/eos/cms/store/mc/RunIISummer19ULPrePremix/Neutrino_E-10_gun/PREMIX/UL17_106X_mc2017_realistic_v6-v1/100000\'
nEvents=1000

#setup10() {
#    echo scram p CMSSW CMSSW_10_6_24
#    export SCRAM_ARCH=slc7_amd64_gcc700
#    if [ -r CMSSW_10_6_24/src ] ; then 
#       echo release CMSSW_10_6_24 already exists
#    else
#       echo No release of CMSSW
#      scram p CMSSW CMSSW_10_6_24
#      curl file:///afs/cern.ch/user/m/mpitt/public/exclusive_top/pythia_fragment --retry 2 --create-dirs -o CMSSW_10_6_24/src/Configuration/GenProduction/python/FSQ-RunIISummer19UL17GEN-00000-fragment.py
#    fi
#    cd CMSSW_10_6_24/src   
#    eval `scram runtime -sh`
#    scram b
#    cd ../../
#}

setup10() {
    echo scram p CMSSW CMSSW_10_6_20
    export SCRAM_ARCH=slc7_amd64_gcc700
    if [ -r CMSSW_10_6_20/src ] ; then
       echo release CMSSW_10_6_20 already exists
    else
       echo No release of CMSSW
      scram p CMSSW CMSSW_10_6_20
    fi
    cd CMSSW_10_6_20/src
    eval `scram runtime -sh`
    #curl -s -k https://cms-pdmv.cern.ch/mcm/public/restapi/requests/get_fragment/TOP-RunIISummer20UL17pLHEGEN-00002 --retry 3 --create-dirs -o Configuration/GenProduction/python/My-fragment.py
    curl file:///afs/cern.ch/user/p/pchatagn/BG_TTbar_Interface/pythia8306/DiffractiveTTbar/TTbartoAll_TuneCP5_13TeV --retry 2 --create-dirs -o Configuration/GenProduction/python/My-fragment.py
    scram b
    cd ../../
}



setup9UL() {
    echo scram p CMSSW CMSSW_9_4_14_UL_patch1
    if [ -r CMSSW_9_4_14_UL_patch1/src ] ; then 
       echo release CMSSW_9_4_14_UL_patch1 already exists
    else
      export SCRAM_ARCH= slc7_amd64_gcc630
      scram p CMSSW CMSSW_9_4_14_UL_patch1
    fi
    cd CMSSW_9_4_14_UL_patch1/src
    eval `scram runtime -sh`
    cd ../../
}

# check number of arguments
if [ "$#" -ne 3 ]; then
  echo $#
  echo "Usage: $0 NAME I" >&2
  echo "Example: $0 BG 0" >&2
  exit 1
fi

echo ./run.sh $1
echo
proc=${1}
ii=${2}

SEED=`expr 123456 + ${nEvents} \* ${2}`

#echo `expr 123456 + ${nEvents} \* ${2}`


#setup cmsenv
#cd $CMSSWFolder
#echo in CMSSW folder:
#pwd
#eval `scramv1 runtime -sh`
#cd -
#echo CMSENV setup done

mkdir -p ${outfolder}/MINIAOD/${proc}

folder=${proc}_${ii}
#create a temporary where samples will be generated
mkdir -pv $folder
cd $folder


#Pythia Generation
cd ${PythiaFolder}

#./main_SDttbar ttbar ttbar.lhe ${nEvents}

cd -

#cp ${PythiaFolder}ttbar.lhe . 


#CMSSW (set up in lxplus7)
setup10


echo "GEN-SIM starting"
#cmsDriver.py step1 --filein file:ttbar.lhe  --fileout file:stepLHE.root --mc --eventcontent LHE --datatier LHE --conditions 106X_mc2017_realistic_v6 --step NONE --python_filename step0_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n -1
#cmsRun step0_cfg.py


cmsDriver.py Configuration/GenProduction/python/My-fragment.py --python_filename step1_cfg.py --eventcontent RAWSIM --datatier GEN-SIM --fileout file:stepSIM.root --conditions 106X_mc2017_realistic_v6 --beamspot Realistic25ns13TeVEarly2017Collision --customise_commands process.RandomNumberGeneratorService.generator.initialSeed="cms.untracked.uint32(${SEED})" --step GEN,SIM --geometry DB:Extended --era Run2_2017 --no_exec --mc -n ${nEvents}

#cmsDriver.py Configuration/GenProduction/python/TOP-RunIISummer20UL17pLHEGEN-00002-fragment.py --filein file:stepLHE.root --fileout file:stepSIM.root --mc --eventcontent RAWSIM --datatier GEN-SIM --conditions 106X_mc2017_realistic_v6 --beamspot Realistic25ns13TeVEarly2017Collision --step GEN,SIM --nThreads 8 --geometry DB:Extended --era Run2_2017 --python_filename step1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n -1


#cmsDriver.py Configuration/GenProduction/python/TTbartoAll_TuneCP5_13TeV.py --fileout file:stepSIM.root --mc --eventcontent RAWSIM --datatier GEN-SIM --conditions 106X_mc2017_realistic_v6 --beamspot Realistic25ns13TeVEarly2017Collision --step GEN,SIM --nThreads 8 --geometry DB:Extended --era Run2_2017 --python_filename step1_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $nEvents

cmsRun step1_cfg.py

#echo EXIT using exit command
#exit

#echo "DIGI-RAW starting"
#cmsDriver.py step1 --python_filename step2_cfg.py --eventcontent RAWSIM --datatier GEN-SIM-RAW --fileout file:stepDR.root --pileup 'E7TeV_AVE_2_BX2808,{"N": 3.0}'  --pileup_input dbs:/MinBias_TuneCP5_13TeV-pythia8/RunIISummer20UL17SIM-106X_mc2017_realistic_v6-v2/GEN-SIM --beamspot Realistic25ns13TeVEarly2017Collision --conditions 106X_mc2017_realistic_v6 --step DIGI,L1,DIGI2RAW --geometry DB:Extended --filein file:stepSIM.root --era Run2_2017 --no_exec --mc -n $nEvents
#sed -i "/process.mix.input.fileNames/a process.mix.input.seed = cms.untracked.int32(${SEED})" step2_cfg.py
#cmsRun step2_cfg.py

echo "DIGI-RAW starting"
cmsDriver.py step1 --python_filename step2_cfg.py --eventcontent RAWSIM --datatier GEN-SIM-RAW --fileout file:stepDR.root --pileup 'E7TeV_AVE_2_BX2808,{"N": 3.0}'  --pileup_input dbs:/MinBias_TuneCP5_13TeV-pythia8/RunIISummer20UL17SIM-106X_mc2017_realistic_v6-v2/GEN-SIM --beamspot Realistic25ns13TeVEarly2017Collision --conditions 106X_mc2017_realistic_v6 --step DIGI,L1,DIGI2RAW --geometry DB:Extended --filein file:stepSIM.root --era Run2_2017 --no_exec --mc -n $nEvents
sed -i "/process.mix.input.fileNames/a process.mix.input.seed = cms.untracked.int32(${SEED})" step2_cfg.py
cmsRun step2_cfg.py

echo "HLT starting"
setup9UL
cmsDriver.py step1 --filein file:stepDR.root  --fileout file:stepHLT.root --mc --eventcontent RAWSIM --datatier GEN-SIM-RAW --conditions 94X_mc2017_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:2e34v40 --nThreads 8 --geometry DB:Extended --era Run2_2017 --python_filename stepHLT_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $nEvents
cmsRun stepHLT_cfg.py

echo "AOD starting"
setup10
cmsDriver.py step1 --filein file:stepHLT.root  --fileout file:stepAOD.root --mc --eventcontent AODSIM --runUnscheduled --datatier AODSIM --conditions 106X_mc2017_realistic_v6 --step RAW2DIGI,L1Reco,RECO,RECOSIM --nThreads 8 --geometry DB:Extended --era Run2_2017 --python_filename step3_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $nEvents
cmsRun step3_cfg.py

echo "MINIAOD starting"
cmsDriver.py step1 --filein file:stepAOD.root  --fileout file:miniAOD.root --mc --eventcontent MINIAODSIM --runUnscheduled --datatier MINIAODSIM --conditions 106X_mc2017_realistic_v6 --step PAT --nThreads 8 --geometry DB:Extended --era Run2_2017 --python_filename step4_cfg.py --no_exec --customise Configuration/DataProcessing/Utils.addMonitoring -n $nEvents
cmsRun step4_cfg.py

echo done with production, ls
ls -hs

echo Run analysis
#setup cmsenv
cd $CMSSWFolder
echo in CMSSW folder:
pwd
eval `scramv1 runtime -sh`
cd -
echo CMSENV setup done

dirCode=${CMSSWFolder}/src/TopLJets2015/TopAnalysis/test
cmsRun ${dirCode}/runMiniAnalyzer_cfg.py runOnData=False era=era2017_H inputFile=file:miniAOD.root outFilename=analysis_${proc}_${ii}.root  runProtonFastSim=150 doPUProtons=True ListVars=lowmu

echo Run the ntuplizer
python ${CMSSWFolder}/src/TopLJets2015/TopAnalysis/scripts/runLocalAnalysis.py -i analysis_${proc}_${ii}.root -o ntuple_${proc}_${ii}.root --njobs 1 -q local --era era2017 -m RunExclusiveTop_NoTrig

/eos/user/p/pchatagn/CMSSW_10_6_24/bin/slc7_amd64_gcc820/post_process_diffractive_ttbar ntuple_${proc}_${ii}.root

#Copy output file to $outfolder
echo "Copying to storage"
#echo cp miniAOD.root  ${outfolder}/MINIAOD/${proc}/${proc}_${ii}.root
cp miniAOD.root  ${outfolder}/MINIAOD/${proc}/${proc}_${ii}.root
outfolderNtuple=/eos/cms/store/group/phys_top/TTbarDiffractive/mc/TTToSemiLeptonic_NoDiffractive_Pierre/BG
#cp miniAOD.root  ${outfolderNtuple}/${proc}_${ii}.root
cp analysis_${proc}_${ii}.root ${outfolderNtuple}
cp ntuple_${proc}_${ii}.root ${outfolderNtuple}/ntuple_${proc}_${ii}.root
cp slimmed_ntuple_${proc}_${ii}.root ${outfolderNtuple}
#cp stepDR.root  ${outfolder}/MINIAOD/${proc}/stepDR_${proc}_${ii}.root
#cp stepHLT.root  ${outfolder}/MINIAOD/${proc}/stepHLT_${proc}_${ii}.root
#cp stepLHE.root  ${outfolder}/MINIAOD/${proc}/stepLHE_${proc}_${ii}.root
#cp stepSIM.root  ${outfolder}/MINIAOD/${proc}/stepSIM_${proc}_${ii}.root
#cp step1_cfg.py ${outfolder}/MINIAOD/${proc}/step1_cfg.py

cd ../
#remove the temporary where samples were generated
rm -rf ${proc}_${ii}
echo $startMsg
echo job finished on `date`

