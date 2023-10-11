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
#               fio.sh file-name[:filename-list] [ MiB [ secs ] ]
#
#       Parameters...
#               file-name       (mandatory - no default) file-name to be used by FIO as a "test area"
#               filename-list   (optional - no default) list of filenames, delimited by colons (":")
#               MiB             (optional - default 100) size of each file
#               secs            (optional - default 120) duration of each FIO test
#
# Dependencies:
#
#       Installation of Linux "fio" command:    sudo yum install -y fio
#
# Modifications:
#       TGorman 11may21 v0.1    written and tested
#       TGorman 11oct23 v1.0    posted to Github
#================================================================================
#
#--------------------------------------------------------------------------------
# Capture command-line parameter values into shell variables...
#--------------------------------------------------------------------------------
case $# in
        1)      typeset -i _MiB=100
                typeset -i _secs=120
                ;;
        2)      typeset -i _MiB=${2}
                typeset -i _secs=120
                ;;
        3)      typeset -i _MiB=${2}
                typeset -i _secs=${3}
                ;;
        *)      echo "Usage: \"fio.sh file-name[:filename-list] [ nbr-of-MiB [ secs ] ]\"; aborting..."
                echo "  invalid number of parameters; aborting..."
                exit 1
                ;;
esac
#
#--------------------------------------------------------------------------------
# Parse the directory path string into a shell array (if more than one directory
# path is specified)...
#--------------------------------------------------------------------------------
_fileNameString=$1
IFS=':' read -r -a _fileNameArray <<< "${_fileNameString}"
typeset -i _nbrFileNames=0
typeset -i _nbrDevices=0
typeset -i _nbrFiles=0
typeset -i _nbrNotFound=0
for _file in "${_fileNameArray[@]}"
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
if (( ${_nbrNotFound} > 0 ))
then
        exit 1
fi
if (( ${_nbrDevices} > 0 && ${_nbrDevices} != ${_nbrFileNames} ))
then
        echo "Usage: \"fio.sh file-name[:filename-list] [ nbr-of-MiB [ secs ] ]\"; aborting..."
        echo "\"filename-list\" consists of both devices and files, use one or the other"
        exit 1
fi
#
#--------------------------------------------------------------------------------
# RANDRW
#--------------------------------------------------------------------------------
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=256 --name=randrw-IOPS \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=1 --name=randrw-latency \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=1 --time_based --group_reporting --runtime=${_secs} --eta-newline=1
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=1 --name=randrw-latency4 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=4 --time_based --group_reporting --runtime=${_secs} --eta-newline=1
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=1 --name=randrw-latency8 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=8 --time_based --group_reporting --runtime=${_secs} --eta-newline=1
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=1 --name=randrw-latency16 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=16 --time_based --group_reporting --runtime=${_secs} --eta-newline=1
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=1 --name=randrw-latency32 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=32 --time_based --group_reporting --runtime=${_secs} --eta-newline=1
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=1 --name=randrw-latency64 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=64 --time_based --group_reporting --runtime=${_secs} --eta-newline=1
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=1 --name=randrw-latency96 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=96 --time_based --group_reporting --runtime=${_secs} --eta-newline=1
fio --filename=${_fileNameString} --bs=8k --rw=randrw --iodepth=1 --name=randrw-latency128 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --numjobs=128 --time_based --group_reporting --runtime=${_secs} --eta-newline=1
fio --filename=${_fileNameString} --bs=256k --rw=randrw --iodepth=64 --name=randrw-thruput \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1
#
#--------------------------------------------------------------------------------
# RANDREAD
#--------------------------------------------------------------------------------
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=256 --name=randread-IOPS \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=1 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency4 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency8 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=8 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency16 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=16 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency32 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=32 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency64 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=64 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency96 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=96 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=8k --rw=randread --iodepth=1 --name=randread-latency128 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=128 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=256k --rw=randread --iodepth=64 --name=randread-thruput \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 --readonly
#
#--------------------------------------------------------------------------------
# SEQREAD
#--------------------------------------------------------------------------------
fio --filename=${_fileNameString} --bs=8k --rw=read --iodepth=256 --name=seqread-IOPS \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 --readonly
fio --filename=${_fileNameString} --bs=256k --rw=read --iodepth=64 --name=seqread-thruput\
        --size=${_MiB}MB --direct=1 --ioengine=libaio --iodepth=64 --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1 --readonly
#
#--------------------------------------------------------------------------------
# SEQWRITE
#--------------------------------------------------------------------------------
fio --filename=${_fileNameString} --bs=8k --rw=write --iodepth=256 --name=seqwrite-IOPS \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1
fio --filename=${_fileNameString} --bs=256k --rw=write --iodepth=64 --name=seqwrite-thruput4 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1
fio --filename=${_fileNameString} --bs=256k --rw=write --iodepth=64 --name=seqwrite-thruput8 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1
fio --filename=${_fileNameString} --bs=256k --rw=write --iodepth=64 --name=seqwrite-thruput16 \
        --size=${_MiB}MB --direct=1 --ioengine=libaio --runtime=${_secs} --numjobs=4 --time_based --group_reporting --eta-newline=1

exit 0
