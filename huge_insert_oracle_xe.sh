#!/bin/bash
set -e

INSERT_SCRIPT="none"
MAX_LINE_FILE="100000"
ORACLE_USER="admin"
ORACLE_PASSWORD="oracle"

UNPROCESSED="unprocessed"
PROCESSED="processed"
PROCESSING="processing"
INSERT_SCRIPT_LITERAL="insert_script"
UNPROCESSED_SCRIPT_NAME=${UNPROCESSED}_${INSERT_SCRIPT_LITERAL}
PROCESSED_SCRIPT_NAME=${PROCESSED}_${INSERT_SCRIPT_LITERAL}

LINE_START_TRANSACTION="SET TRANSACTION READ WRITE"
LINE_COMMIT="COMMIT;"
LINE_TURN_OFF_OUTPUT_SQLPLUS="SET TERMOUT OFF;"
LINE_TURN_ON_OUTPUT_SQLPLUS="SET TERMOUT ON;"

SCRIPT_TOP="$LINE_START_TRANSACTION\n$LINE_TURN_OFF_OUTPUT_SQLPLUS"
SCRIPT_BOTTOM="$LINE_TURN_ON_OUTPUT_SQLPLUS\n$LINE_COMMIT"

echo $TMP_HASH
for ARGUMENT_VALUE in "$@"
do
    ARGUMENT_VALUE_SPLITTED=(${ARGUMENT_VALUE//=/ })
    ARGUMENT=${ARGUMENT_VALUE_SPLITTED[0]}
    VALUE=${ARGUMENT_VALUE_SPLITTED[1]}
    case $ARGUMENT in
    insert_script)
        INSERT_SCRIPT=$VALUE
        ;;
    max_line_file)
        MAX_LINE_FILE=$VALUE
        ;;
    oracle_user)
        ORACLE_USER=$VALUE
        ;;
    oracle_password)
        ORACLE_PASSWORD=$VALUE
        ;;
    *)
        echo "Parameter '$ARGUMENT' desn't exist"
        ;;
    esac    
done

echo "-------------------------------------------------------------"
echo "Splitting $INSERT_SCRIPT in"
split -d --lines=$MAX_LINE_FILE --additional-suffix=.sql $INSERT_SCRIPT $UNPROCESSED_SCRIPT_NAME
UNPROCESSED_SCRIPTS=($(ls -A1 $UNPROCESSED_SCRIPT_NAME*sql))
printf '%s\n' "${UNPROCESSED_SCRIPTS[@]}"
SCRIPTS_TO_PROCESS=${#UNPROCESSED_SCRIPTS[@]}
echo "$SCRIPTS_TO_PROCESS part(s)"

echo "-------------------------------------------------------------"
echo "Processing "
for UNPROCESSED_SCRIPT in "${UNPROCESSED_SCRIPTS[@]}"
do
    PROCESSING_SCRIPT=`echo "$UNPROCESSED_SCRIPT" | sed -e "s/$UNPROCESSED/$PROCESSING/g"`
    echo "$UNPROCESSED_SCRIPT -> $PROCESSING_SCRIPT"
    mv $UNPROCESSED_SCRIPT $PROCESSING_SCRIPT

    # Placing the statements to start a transaction and turn off the sqlplus's output
    # at beginning of the script and committing.
    # Also, turning on the sqlplus's output on the bottom of the script
    sed -i -e '1i\'"$SCRIPT_TOP\n" -e '$ a\'"\n$SCRIPT_BOTTOM" $PROCESSING_SCRIPT
    
    # Breaking each insert statement in two line using the pattern ' values'
    sed -i -e 's/ values/\n values/Ig' $PROCESSING_SCRIPT

    SQLPLUS_COMMAND="exit | sqlplus -S $ORACLE_USER/$ORACLE_PASSWORD @$PROCESSING_SCRIPT > /dev/null"
    echo $SQLPLUS_COMMAND
    eval $SQLPLUS_COMMAND
   
    PROCESSED_SCRIPT=`echo "$PROCESSING_SCRIPT" | sed -e "s/$PROCESSING/$PROCESSED/g"`
    echo "$PROCESSING_SCRIPT -> $PROCESSED_SCRIPT"
    mv $PROCESSING_SCRIPT $PROCESSED_SCRIPT
    
    echo " "
done

echo "-------------------------------------------------------------"
echo "Removing processed scripts "
PROCESSED_SCRIPTS_TO_DELETE=($(ls -A1 $PROCESSED_SCRIPT_NAME*sql))
for PROCESSED_SCRIPT_TO_DELETE in "${PROCESSED_SCRIPTS_TO_DELETE[@]}"
do
    echo "removing $PROCESSED_SCRIPT_TO_DELETE"
    rm $PROCESSED_SCRIPT_TO_DELETE
done

echo "-------------------------------------------------------------"
echo "Finished successfully "