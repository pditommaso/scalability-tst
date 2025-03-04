#!/bin/bash

#module load Java # For working on biocluster- change for AWS
echo "Analysis done on: "
date 
set -x

##############################################################################################
#### For bioinfo scalability: scalability scenarios meaningful in the context of bioinformatics.
#### Part I: Allocate 1 node, and benchmark time for tasks=1:#cores in this node
#### Part II: Increase the number of nodes in the cluster gradually (i.e. increase the number of
#### tasks by the number of cores in a node, and benchmark. 
#### The script read value for cores from a file: cores.txt in the same directory
##############################################################################################

#nextflow="/home/ubuntu/software/nextflow"
nextflow="/home/a-m/azzaea/software/nextflow/19.04.1" #biocluster path
resultsDir="results.nf"
logsDir="${resultsDir}/logs-nf" #######
hostsDir="${resultsDir}/hosts"
mkdir -p ${resultsDir} ${logsDir} ${hostsDir}

progress="${logsDir}/progress_bioinfoScaling.txt"
echo "Starting BioInfo Scalability Analysis" >> ${progress}
echo "##############################################################################################" >> ${progress}
${nextflow} -v >> ${progress}
echo "##############################################################################################" >> ${progress}

ifstat -t -T -n -w > ${logsDir}/network-report.txt

log1="${logsDir}/bioinfoScaling_processes-1_host.txt"
log2="${logsDir}/bioinfoScaling_processes-2_host.txt"
echo "cores,tasks,user,system,elapsed,cpu,avMemory,involuntaryContextSwitch,voluntaryContextSwitch,faults,inputs,outputs,socketsIn,socketsOut,exitStatus" | tee -a ${log1} ${log2}

for line in {1..10}; do
	cores=`cat cores.txt | sed -n ${line}p`  #goes to the forks param
	tasks=${cores}
	echo -n "${cores},${tasks}," | tee -a ${log1} ${log2}

	##### processes: 1
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log1} \
		${nextflow} run host_process.nf -profile cluster --ntasks=${tasks} --forks=${cores} --log=${hostsDir}/host1_tasks${tasks}.txt

	#### Processes: 2
	/usr/bin/time --format "%U,%S,%e,%P,%K,%c,%w,%F,%I,%O,%r,%s,%x" --append --output ${log2} \
		${nextflow} run host_workflow.nf -profile cluster --ntasks=${tasks} --forks=${cores} --log=${hostsDir}/host2_tasks${tasks}.txt

	echo -e "Done processing * ${tasks} * tasks, on * ${cores} * cores" >> ${progress}	
done
echo "##############################################################################################" >> ${progress}


cd ${hostsDir}
echo "nodes processes tasks" > ../summarize_hosts_nodes.txt
for file in `ls -1v`; do
    echo `wc -l $file`| sed 's/_/ /g' >> ../summarize_hosts_nodes.txt
done

echo "Bio-Scalability analysis completed for Nextflow!" | mail -s "WfMS- Bio-Scalability" "azzaea@gmail.com"



