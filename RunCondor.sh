#!/bin/zsh
outpath=/eos/user/p/pchatagn/OutputDirFPMC/MINIAOD
N1=${1}
N2=${2}

extime="tomorrow" #"testmatch" #testmatch tomorrow workday
condor="condor_generator.sub"
echo "executable  = run.sh" > $condor
echo "output      = ${condor}.out" >> $condor
echo "error       = ${condor}.err" >> $condor
echo "log         = ${condor}.log" >> $condor
echo "+JobFlavour =\"${extime}\"">> $condor
echo "requirements = (OpSysAndVer =?= \"CentOS7\")" >> $condor  # SLCern6 CentOS7

name="BG"


for i in {$N1..$N2}; do
      echo submit ${name}_${i}.root
      echo "arguments   = $name ${i} ${i}" >> $condor
      echo "queue 1" >> $condor
done


echo "Submitting $condor"
echo condor_submit $condor
condor_submit $condor
