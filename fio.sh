#!/bin/bash
#================================================================================
# Name: fio.sh
# Type: bash script
# Date: 11-May 2021
# From: Customer Architecture & Engineering (CAE) - Microsoft
#
# Copyright and license:
#
#       Licensed under the Apache License, Version 2.0 (the "License"); you may
#       not use this file except in compliance with the License.
#
#       You may obtain a copy of the License at
#
#               http://www.apache.org/licenses/LICENSE-2.0
#
#       Unless required by applicable law or agreed to in writing, software
#       distributed under the License is distributed on an "AS IS" basis,
#       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
#       See the License for the specific language governing permissions and
#       limitations under the License.
#
#       Copyright (c) 2020 by Microsoft.  All rights reserved.
#
# Ownership and responsibility:
#
#       This script is offered without warranty by Microsoft.  Anyone using this
#       script accepts full responsibility for use, effect, and maintenance.
#       Please do not contact Microsoft support unless there is a problem with
#       a supported Azure or Linux component used in this script.
#
# Description:
#
#       Script to call Linux FIO utility, inspired by the documentation at
#       "https://docs.oracle.com/en-us/iaas/Content/Block/References/samplefiocommandslinux.htm".
#
# Command-line Parameters:
#
#       Call syntax...
#
#               fio.sh label file-name[:filename-list] [ MiB [ secs ] ]
#
#       Parameters...
#               label           free-format text label, usually indicates type of storage
#               file-name       (mandatory - no default) file-name to be used by FIO as a "test area"
#               filename-list   (optional - no default) list of filenames, delimited by colons (":")
#               MiB             (optional - default 100) size of each file
#               secs            (optional - default 120) duration of each FIO test
#
# Dependencies:
#
#       Installation of Linux "fio" command:    sudo yum install -y fio
#
# Advice:
#
#       Please update the script version in the "Modifications" section and do
#       the same for the "_progVersion" variable in the script?
#
# Modifications:
#       TGorman 11may21 v0.1    written and tested
#       TGorman 23oct23 v1.0    posted to Github
#================================================================================
_progVersion="1.0"
#
#--------------------------------------------------------------------------------
# Capture command-line parameter values into shell variables...
#--------------------------------------------------------------------------------
case $# in
        2)      _label=$1
                _destPathString=$2
                typeset -i _MiB=100
                typeset -i _secs=120
                ;;
        3)      _label=$1
                _destPathString=$2
                typeset -i _MiB=${3}
                typeset -i _secs=120
                ;;
        4)      _label=$1
                _destPathString=$2
                typeset -i _MiB=${3}
                typeset -i _secs=${4}
                ;;
        *)      echo "Usage: \"fio.sh label file-name[:filename-list] [ nbr-of-MiB [ secs ] ]\"; aborting..."
                echo "  invalid number of parameters; aborting..."
                exit 1
                ;;
esac
#
#--------------------------------------------------------------------------------
# Parse the directory path string into a shell array (if more than one directory
# path is specified)...
#--------------------------------------------------------------------------------
IFS=':' read -r -a _destPathArray <<< "${_destPathString}"
typeset -i _nbrFileNames=0
typeset -i _nbrDevices=0
for _file in "${_destPathArray[@]}"
do
        #
        typeset -i _nbrFileNames=${_nbrFileNames}+1
        #
        if [ -b ${_file} ]
        then
                typeset -i _nbrDevices=${_nbrDevices}+1
        elsif [ -c ${_file} ]
                typeset -i _nbrDevices=${_nbrDevices}+1
        fi
        #
done
if (( ${_nbrDevices} > 0 && ${_nbrDevices} != ${_nbrFileNames} ))
then
        echo "Usage: \"fio.sh label file-name[:filename-list] [ nbr-of-MiB [ secs ] ]\"; aborting..."
        echo "\"filename-list\" consists of both devices and files, use one or the other"
        exit 1
fi
#
#--------------------------------------------------------------------------------
# Determine the number of vCPUs, the number of CPU cores, and the GB of RAM...
#--------------------------------------------------------------------------------
_nbrVCpus=`lscpu | grep "^CPU(s):" | awk '{print $2}'`
_nbrHT=`lscpu | grep "^Thread(s) per core:" | awk '{print $4}'`
_nbrCpuCores=`echo ${_nbrVCpus} ${_nbrHT} | awk '{printf("%d\n", $1/$2)}'`
_ramGB=`free -g | grep "^Mem:" | awk '{print $2}'`
#
#--------------------------------------------------------------------------------
# create an output file with the following naming convention...
#
#       fio_${_label}_${_nbrVCpus}-${_nbrCpuCores}_${_ramGB}_[dev|fs]_${_MiB}.txt
#
# where...
#       label           free-format text label, indicating type of storage
#       _nbrVCpus       number of vCPUs in VM
#       _nbrCpuCores    number of CPU cores in VM
#       _ramGB          number of GB of RAM in VM
#       dev             testarea consists of block- or character-special device(s)
#       fs              testarea consists of filesystem file(s)
#       _MiB            size (in MiB) of the testarea
#--------------------------------------------------------------------------------
if (( ${_nbrDevices} > 0 ))
then
        _devFs="dev"
else
        _devFs="fs"
fi
#
#--------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
_outFile=fio_${_label}_${_nbrVCpus}-${_nbrCpuCores}_${_ramGB}_${_devFs}_${_MiB}.txt
_outCsv=fio_${_label}_${_nbrVCpus}-${_nbrCpuCores}_${_ramGB}_${_devFs}_${_MiB}.csv
rm -f ${_outFile} ${_outCsv}
echo "`date`: v${_progVersion} \"$0 $*\""       >  ${_outFile}
echo ""                                         >> ${_outFile}
echo "# `date`: v${_progVersion} \"$0 $*\""     >  ${_outCsv}
echo "#"                                        >> ${_outCsv}
#
#--------------------------------------------------------------------------------
# RANDREAD
# I/O operations performed during indexed access (a.k.a. "db file sequential read"
# or "cell single block physical read")
# - attempting to maximize IOPS: bs=8k, iodepth=256, numjobs=4
# - attempting to maximize latency: bs=8k, iodepth=1, numjobs=1->128
# - attempting to maximize throughput: bs=256k, iodepth=64, numjobs=128
#
#--------------------------------------------------------------------------------
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=256 --name=randread-IOPS \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency1 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=1 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency4 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency8 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=8 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency16 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=16 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency32 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=32 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency64 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=64 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency96 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=96 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency128 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=128 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=256k --rw=randread --iodepth=64 --name=randread-thruput \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
#
#--------------------------------------------------------------------------------
# RANDWRITE
# I/O operations performed by DBWn processes
# - attempting to maximize IOPS: bs=8k, iodepth=256, numjobs=4
# - attempting to maximize latency: bs=8k, iodepth=1, numjobs=1->128
# - attempting to maximize throughput: bs=256k, iodepth=64, numjobs=128
#--------------------------------------------------------------------------------
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=256 --name=randwrite-IOPS \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=1 --name=randwrite-latency1 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=1 --time_based --group_reporting --runtime=${_secs} --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=1 --name=randwrite-latency4 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=4 --time_based --group_reporting --runtime=${_secs} --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=1 --name=randwrite-latency8 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=8 --time_based --group_reporting --runtime=${_secs} --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=1 --name=randwrite-latency16 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=16 --time_based --group_reporting --runtime=${_secs} --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=1 --name=randwrite-latency32 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=32 --time_based --group_reporting --runtime=${_secs} --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=1 --name=randwrite-latency64 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=64 --time_based --group_reporting --runtime=${_secs} --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=1 --name=randwrite-latency96 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=96 --time_based --group_reporting --runtime=${_secs} --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=8k --rw=randwrite --iodepth=1 --name=randwrite-latency128 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=128 --time_based --group_reporting --runtime=${_secs} --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=256k --rw=randwrite --iodepth=64 --name=randwrite-thruput \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
#
#--------------------------------------------------------------------------------
# SEQREAD
# I/O operations performed during full scans (i.e. "direct path read", "db file
# scattered read", "cell multi block physical read", etc)
# - attempting to maximize IOPS: bs=8k, iodepth=256, numjobs=4
# - attempting to maximize throughput: bs=256k, iodepth=64, numjobs=4-16
#--------------------------------------------------------------------------------
fio --filename=${_destPathString} --bs=8k --rw=read --iodepth=256 --name=seqread-IOPS \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=256k --rw=read --iodepth=64 --name=seqread-thruput4 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --iodepth=64 --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=256k --rw=read --iodepth=64 --name=seqread-thruput8 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --iodepth=64 --runtime=${_secs} --numjobs=8 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=256k --rw=read --iodepth=64 --name=seqread-thruput16 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --iodepth=64 --runtime=${_secs} --numjobs=16 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
#
#--------------------------------------------------------------------------------
# SEQWRITE
# I/O operations performed by LGWR process and by RMAN processes writing backupsets
# - attempting to maximize IOPS: bs=8k, iodepth=256, numjobs=4
# - attempting to maximize throughput: bs=256k, iodepth=64, numjobs=4-16
#--------------------------------------------------------------------------------
fio --filename=${_destPathString} --bs=8k --rw=write --iodepth=256 --name=seqwrite-IOPS \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=256k --rw=write --iodepth=64 --name=seqwrite-thruput4 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=256k --rw=write --iodepth=64 --name=seqwrite-thruput8 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=8 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
fio --filename=${_destPathString} --bs=256k --rw=write --iodepth=64 --name=seqwrite-thruput16 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=16 --time_based --group_reporting --eta-newline=1 >> ${_outFile}
#
#--------------------------------------------------------------------------------
# Parse out the latency, IOPS, and throughput information into CSV format...
#--------------------------------------------------------------------------------
_name=""
typeset -i _lineCnt=0
while read _line
do
        if [[ "`echo ${_line} | grep 'groupid='`" != "" ]]
        then
                if [[ "${_name}" != "" ]]
                then
                        if (( ${_lineCnt} == 0 ))
                        then
                                echo "label,#vcpus,#cpucores,ramGiB,devORfs,testareaMiB,testName,latencyUOM,latencyMin,latencyMax,latencyAvg,latencyStD,IopsMin,IopsMax,IopsAvg,IopsStD,thruputMBps" >> ${_outCsv}
                        fi
                        echo "${_label},${_nbrVCpus},${_nbrCpuCores},${_ramGB},${_devFs},${_MiB},${_name},${_latUom},${_latMin},${_latMax},${_latAvg},${_latStD},${_iopsMin},${_iopsMax},${_iopsAvg},${_iopsStD},${_thruputMBps}" >> ${_outCsv}
                        typeset -i _lineCnt=${_lineCnt}+1
                fi
                _name=`echo ${_line} | awk '{print $1}' | sed 's/://'`
        fi
        if [[ "`echo ${_line} | grep '^iops '`" != "" ]]
        then
                _iopsMin=`echo ${_line} | awk -F: '{print $2}' | sed -e 's/=/ /g' -e 's/,//g' | awk '{print $2}'`
                _iopsMax=`echo ${_line} | awk -F: '{print $2}' | sed -e 's/=/ /g' -e 's/,//g' | awk '{print $4}'`
                _iopsAvg=`echo ${_line} | awk -F: '{print $2}' | sed -e 's/=/ /g' -e 's/,//g' | awk '{print $6}'`
                _iopsStD=`echo ${_line} | awk -F: '{print $2}' | sed -e 's/=/ /g' -e 's/,//g' | awk '{print $8}'`
        fi
        if [[ "`echo ${_line} | grep '^lat ([mun]sec):'`" != "" ]]
        then
                _latUom=`echo ${_line} | awk '{print $2}' | sed 's/(//' | sed 's/)//' | sed 's/://'`
                _latMin=`echo ${_line} | awk -F: '{print $2}' | sed -e 's/=/ /g' -e 's/,//g' | awk '{print $2}'`
                _latMax=`echo ${_line} | awk -F: '{print $2}' | sed -e 's/=/ /g' -e 's/,//g' | awk '{print $4}'`
                _latAvg=`echo ${_line} | awk -F: '{print $2}' | sed -e 's/=/ /g' -e 's/,//g' | awk '{print $6}'`
                _latStD=`echo ${_line} | awk -F: '{print $2}' | sed -e 's/=/ /g' -e 's/,//g' | awk '{print $8}'`
        fi
        if [[ "`echo ${_line} | grep '^[RW][ER][AI][DT][:E][ :]'`" != "" ]]
        then
                _thruputMBps=`echo ${_line} | awk '{print $2}' | sed 's/bw=//' | sed 's=MiB/s=='`
        fi

done < ${_outFile}
#
exit 0
