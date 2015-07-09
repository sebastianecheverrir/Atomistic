#!/bin/bash
#01/07/2015
#Sebastian ECHEVERRI RESTREPO
#sebastianecheverri@ at gmail.com

#############################################################################

#Reads an output file .out from abinit and generates .in files to be read by v_sim

#inputs
#	.out file

#outputs
#	series of .in files
#	this files are numbered starting from file00000.in 


#notes
#the generated files only contain the necessary information for visualization,
#	they are not enough for running a simulation with abinit


#############################################################################
#############################################################################


#File to read
OutFileName=$1


######
#This part reads the initial configuration (the atom positions will be the 
#	same as in the input file used for the simulation

#Reading acell, rprim, ntypat, znucl.
#v_sim asks for chkprim so it is also written

grep acell $OutFileName | head -1 > file00000.in
grep -A2 rprim $OutFileName | head -3 >> file00000.in
echo 'chkprim     0' >> file00000.in
grep -m2 ntypat $OutFileName | tail -1 >> file00000.in
grep znucl $OutFileName | head -1 >> file00000.in

#Reading natom. in the .out file, typat might take more than one line. The
#	maximum number of values per line is 20. So, the number of atoms is
#	used to see how many lines need to be read
grep -m3  natom $OutFileName | tail -1 >> file00000.in

natom=`grep -m3  natom $OutFileName | tail -1 | awk '{print $2}'`
natom_1=`awk -v natom=$natom 'BEGIN{print natom-1}'`

if [ $natom -le 20 ]
then
	grep -m3 typat $OutFileName | tail -1 >> file00000.in
elif [ $natom -le 40 ]
then
	grep -m3 -A1 typat $OutFileName | tail -2 >> file00000.in
elif [ $natom -le 60 ]
then
	grep -m3 -A2 typat $OutFileName | tail -3 >> file00000.in
fi

grep -m1 -A $natom_1 xred $OutFileName >> file00000.in


######
#for the rest of the configurations

#reading the number of files that will be generated
nfiles=`grep  '(xred)' $OutFileName | wc | awk '{print $1}'`

#checking if the box dimensions are changed. If they are not changed, 
#	the initial values are used
optcell=`grep optcell $OutFileName | head -1 | awk '{print $2}'`

for i in  $(seq -f "%05g" 1 $nfiles)
#for i in `seq 1 $nfiles`;
do
	#if the cell dimensions do not change,the initial values are used
	#	for acell and rprim
        #if the cell dimensions change,the values of acell is different for 
	#	for each file. Note that angdeg is used instead of rprim 
	if [ ! -z "$optcell" ]; then
		grep -m$i -A1 '(acell)'  $OutFileName | tail -1 | awk '{print "acell", $0}' > file$i.in
		grep -m$i  -A1  "degrees]" $OutFileName | tail -1 | awk '{print "angdeg", $0}' >> file$i.in
	else
		grep acell $OutFileName | head -1 > file$i.in
		grep -A2 rprim $OutFileName | head -3 >> file$i.in

	fi

	#v_sim asks for chkprim so it is also written
	echo 'chkprim     0' >> file$i.in

        #reading ntypat, znucl
	grep -m2 ntypat $OutFileName | tail -1 >> file$i.in
	grep znucl $OutFileName | head -1 >> file$i.in

	#Reading natom. in the .out file, typat might take more than one line. The
	#       maximum number of values per line is 20. So, the number of atoms is
	#       used to see how many lines need to be read
	grep -m3  natom $OutFileName | tail -1 >> file$i.in
	if [ $natom -le 20 ]
	then
        	grep -m3 typat $OutFileName | tail -1 >> file$i.in
	elif [ $natom -le 40 ]
	then
        	grep -m3 -A1 typat $OutFileName | tail -2 >> file$i.in
	elif [ $natom -le 60 ]
	then
        	grep -m3 -A2 typat $OutFileName | tail -3 >> file$i.in
	fi

	#reading the coordinates xred
	echo 'xred     ' >> file$i.in
	grep -m$i -A $natom '(xred)' $OutFileName | tail -$natom >> file$i.in


	echo "Generating file" $i 

done




