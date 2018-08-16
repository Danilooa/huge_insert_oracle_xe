# huge_insert_oracle_xe

### requirement

__Oracle xe__ running locally  
The user's %PATH% must point to __SQLPLUS__  

### usage

1. Download __huge_insert_oracle_xe.sh__  
2. Place __huge_insert_oracle_xe.sh__ together with a huge insert script  
3. Give __huge_insert_oracle_xe.sh__ persmission to execute:  
    `$ chmod u+rwx huge_insert_oracle_xe.sh`  
4. Run __huge_insert_oracle_xe.sh__:  
    `$ ./huge_insert_oracle_xe.sh oracle_user=<ORACLE USER> oracle_password=<ORACLE PASSWORD> insert_script=<HUGE INSERT SCRIPT> max_line_file=<NUMBER OF INSERTS PER TRANSACTION`

### Caution

This script will create many files in the directory where it is placed. Then, it will delete those files during the execution. Take care because the name of those files are used to elect which one will be deleted. Avoid letting important files together with this script with they have the following patterns in their names: "unprocessed_insert_script", "processing_insert_script", "processed_insert_script".
 