#!/bin/bash
mkdir DBMS 2>> ./ERRORLOG/.error.log
clear

function mainMenu {
  echo -e "Main Menu :"
  echo "1) create new DB"
  echo "2) Delete DB"
  echo "3) open DB"
  echo "4) List existing DBs"
  echo "5) Exit"
  echo -e "\nEnter your Choice: \c"
  read ch
  case $ch in
    1)  createDB ;;
    2)  dropDB ;;
    3)  selectDB ;;
    4)  clear;echo "existing DBs :"; ls ./DBMS ; mainMenu;;
    5) exit ;;
    *) clear; echo " Wrong Choice " ; mainMenu;
  esac
}

function createDB {
  echo -e "Enter Database Name: \c"
  read dbName
  mkdir ./DBMS/$dbName
  if [[ $? == 0 ]]
  then
    clear
    echo "Database Created Successfully"
  else
    clear
    echo "Error Creating Database \" $dbName \""
  fi
  mainMenu
}

function dropDB {
  echo -e "Enter Database Name: \c"
  read dbName
  rm -r ./DBMS/$dbName 2>>./ERRORLOG/.error.log
  if [[ $? == 0 ]]; then
    clear
    echo "Database Dropped Successfully"
  else
    clear
    echo "Database Not found"
  fi
  mainMenu
}

function selectDB {
  echo -e "Enter Database Name: \c"
  read dbName
  cd ./DBMS/$dbName 2>>./ERRORLOG/.error.log
  if [[ $? == 0 ]]; then
    clear
    echo "Database $dbName was Successfully Selected"
    tablesMenu
  else
    clear
    echo "Database $dbName wasn't found"
    mainMenu
  fi
}


function tablesMenu {
  echo -e "\nTables Menu"
  echo "1) Create New Table"
  echo "2) Delete Table"
  echo "3) Insert Into Table"
  echo "4) Update Table"
  echo "5) Show Existing Tables"
  echo "6)Back To Main Menu"
  echo "7)Exit"
  echo -e "\nEnter your Choice: \c"
  read ch
  case $ch in
    1)  createTable ;;
    2)  dropTable;;
    3)  insert;;
    4)  updateTable;;
    5)  clear;echo "existing tables :"; ls .; tablesMenu ;;
    6)  clear; cd ../.. 2>>./ERRORLOG/.error.log; mainMenu ;;
    7)  exit ;;
    *)  clear; echo " Wrong Choice " ; clear; tablesMenu;
  esac

}

function createTable {
  echo -e "Table Name: \c"
  read tableName
  if [[ -f $tableName ]]; then
    clear
    echo "table already existed ,choose another name"
    tablesMenu
  fi
  echo -e "Number of Columns: \c"
  read colsNum
  counter=1
  sep="|"
  rSep="\n"
  pKey=""
  metaData="Field"$sep"Type"$sep"key"
  while [ $counter -le $colsNum ]
  do
    echo -e "Name of Column No.$counter: \c"
    read colName

    echo -e "Type of Column $colName: "
    select var in "int" "str"
    do
      case $var in
        int ) colType="int";break;;
        str ) colType="str";break;;
        * ) echo "Wrong Choice" ;;
      esac
    done
    if [[ $pKey == "" ]]; then
      echo -e "Make PrimaryKey ? "
      select var in "yes" "no"
      do
        case $var in
          yes ) pKey="PK";
          metaData+=$rSep$colName$sep$colType$sep$pKey;
          break;;
          no )
          metaData+=$rSep$colName$sep$colType$sep""
          break;;
          * ) echo "Wrong Choice" ;;
        esac
      done
    else
      metaData+=$rSep$colName$sep$colType$sep""
    fi
    if [[ $counter == $colsNum ]]; then
      temp=$temp$colName
    else
      temp=$temp$colName$sep
    fi
    ((counter++))
  done
  touch .$tableName
  echo -e $metaData  >> .$tableName
  touch $tableName
  echo -e $temp >> $tableName
  if [[ $? == 0 ]]
  then
    echo "Table Created Successfully"
    tablesMenu
  else
    echo "Error Creating Table $tableName"
    tablesMenu
  fi
}

function dropTable {
  echo -e "Enter Table Name: \c"
  read tName
  rm $tName .$tName 2>>./ERRORLOG/.error.log
  if [[ $? == 0 ]]
  then
    clear
    echo "Table Dropped Successfully"
  else
    clear
    echo "Error Dropping Table $tName"
  fi
  tablesMenu
}

function insert {
  echo -e "Table Name: \c"
  read tableName
  if ! [[ -f $tableName ]]; then
    clear
    echo "Table $tableName isn't existed ,choose another Table"
    tablesMenu
  fi
  colsNum=`awk 'END{print NR}' .$tableName`
  sep="|"
  rSep="\n"
  for (( i = 2; i <= $colsNum; i++ )); do
    colName=$(awk 'BEGIN{FS="|"}{ if(NR=='$i') print $1}' .$tableName)
    colType=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $2}' .$tableName)
    colKey=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $3}' .$tableName)
    echo -e "$colName ($colType) = \c"
    read data

    # Validate Input
    if [[ $colType == "int" ]]; then
      while ! [[ $data =~ ^[0-9]*$ ]]; do
        echo -e "invalid DataType !!\n"
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    if [[ $colKey == "PK" ]]; then
      while [[ true ]]; do
        if [[ $data =~ ^[`awk 'BEGIN{FS="|" ; ORS=" "}{if(NR != 1)print $(('$i'-1))}' $tableName`]$ ]]; then
          echo -e "invalid input for Primary Key !!"
        else
          break;
        fi
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    #Set row
    if [[ $i == $colsNum ]]; then
      row=$row$data$rSep
    else
      row=$row$data$sep
    fi
  done
  echo -e $row"\c" >> $tableName
  if [[ $? == 0 ]]
  then
    clear
    echo "Data Inserted Successfully"
  else
    clear
    echo "Error Inserting Data into Table $tableName"
  fi
  row=""
  tablesMenu
}

function updateTable {
  echo -e "Enter Table Name: \c"
  read tName
  echo -e "Enter Condition Column name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Not Found"
    tablesMenu
  else
    echo -e "Enter Condition Value: \c"
    read val
    res=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $tName 2>>./ERRORLOG/.error.log)
    if [[ $res == "" ]]
    then
      echo "Value Not Found"
      tablesMenu
    else
      echo -e "Enter FIELD name to set: \c"
      read setField
      setFid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$setField'") print i}}}' $tName)
      if [[ $setFid == "" ]]
      then
        echo "Not Found"
        tablesMenu
      else
        echo -e "Enter new Value to set: \c"
        read newValue
        NR=$(awk 'BEGIN{FS="|"}{if ($'$fid' == "'$val'") print NR}' $tName 2>>./ERRORLOG/.error.log)
        oldValue=$(awk 'BEGIN{FS="|"}{if(NR=='$NR'){for(i=1;i<=NF;i++){if(i=='$setFid') print $i}}}' $tName 2>>./ERRORLOG/.error.log)
        echo $oldValue
        sed -i ''$NR's/'$oldValue'/'$newValue'/g' $tName 2>>./ERRORLOG/.error.log
        echo "Row Updated Successfully"
        tablesMenu
      fi
    fi
  fi
}

mainMenu

