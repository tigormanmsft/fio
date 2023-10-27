# fio.sh
Linux bash script named "fio.sh" available to standardize testing using Linux FIO utility

The general idea is that the "fio.sh" script always calls the same FIO tests for...
1. Random-access reads (which mimic indexed table access in Oracle database)
2. Random-access writes (which roughly mimics DBWR behavior in Oracle database)
3. Sequential-access reads (which mimics full scan table access in Oracle database)
4. Sequential-access writes (which roughly mimics LGWR and RMAN behavior in Oracle Database)

Output from the FIO utility is captured to a text file, and the "raw" output in that text file is then parsed into a comma-separated file for analysis in a spreadsheet or a relational database.

# Call syntax for "fio.sh" script

- fio.sh label file-name[:filename-list] [ MiB [ secs ] ]

Parameters...
- label           (mandatory - no default) free-format text label, usually indicates type of storage
- file-name       (mandatory - no default) file-name to be used by FIO as a "test area"
- filename-list   (optional - no default) list of filenames, delimited by colons (":")
- MiB             (optional - default 100) size of each file
- secs            (optional - default 120) duration of each FIO test

# Output

The script creates two files:  "raw" FIO output stored with a ".txt" file extension and comma-separated metrics stored with a ".csv" file extension.

Both filenames have similar format...

- fio_${label}\_${nbrVCpus}-${nbrCpuCores}\_${ramGB}\_[dev|fs]\_${MiB}

where...
- label          (source: command-line parameter, free-format text label, indicating type of storage)
- nbrVCpus       (source: output from Linux "lscpu" command, number of vCPUs in VM)
- nbrCpuCores    (source: output from Linux "lscpu" command, number of CPU cores in VM)
- ramGB          (source: output from Linux "free -g" command, number of GB of RAM in VM)
- dev            (source: results from Linux conditionals from command-line parameter, testarea consists of block- or character-special "raw" device(s))
- fs             (source: parsing from Linux conditionals from command-line parameter, testarea consists of filesystem file(s))
- MiB            (source: command-line parameter, size (in MiB) of the testarea)
