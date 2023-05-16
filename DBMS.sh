#!/bin/bash

# Define the main menu
function main_menu {
  clear
  echo "Main Menu"
  echo "1. Create Database"
  echo "2. List Databases"
  echo "3. Connect To Database"
  echo "4. Drop Database"
  echo "5. Exit"
  read -p "Enter your choice: " choice
  case "$choice" in
    1 ) create_database;;
    2 ) list_databases;;
    3 ) connect_to_database;;
    4 ) drop_database;;
    5 ) exit;;
    * ) echo "Invalid choice"; main_menu;;
  esac
}

# Define the function to create a database
function create_database {
     
  # Prompt the user to enter the name of the database
  read -p "Enter the name of the database: " dbname
  cd ~
  
  # Check if the "databases" directory exists, and create it if it doesn't
  if [ ! -d "databases" ]; then
    mkdir databases
  fi
  
  cd databases

  # Check if the database(directory) already exists
  if [ -d "$dbname" ]; then
    echo "Database already exists"
  else
    mkdir "$dbname"
    echo "Database created successfully"
  fi

  read -p "Press enter to continue"

  main_menu
}

# Define the function to list all databases
function list_databases {
  clear

  echo "List of Databases"
  echo "-----------------"
  cd ~/databases
  # Loop through all the directories in the current directory
  for dbname in */; do
    # Print the directory name without the trailing slash
    echo "${dbname%/}" # the % symbol is used to remove the trailing slash (/) from the value of the dbname variable
  done

  # Prompt the user to press enter to continue
  read -p "Press enter to continue"

  main_menu
}

# Define the function to connect to a database
function connect_to_database {
  # Prompt the user to enter the name of the database
  read -p "Enter the name of the database: " dbname
  cd ~/databases

  if [ -d "$dbname" ]; then
    cd "$dbname"
    table_menu
  else
    echo "Database does not exist"
    read -p "Press enter to continue"
    main_menu
  fi
}

# Define the function to drop a database
function drop_database {
  # Prompt the user to enter the name of the database
  read -p "Enter the name of the database: " dbname
  cd ~/databases

  if [ -d "$dbname" ]; then
    rm -r "$dbname"
    echo "Database dropped successfully"
  else
    echo "Database does not exist"
  fi

  read -p "Press enter to continue"

  main_menu
}

# Define the table menu
function table_menu {
  clear
  echo "Table Menu"
  echo "1. Create Table"
  echo "2. List Tables"
  echo "3. Drop Table"
  echo "4. Insert Into Table"
  echo "5. Select From Table"
  echo "6. Update Table"
  echo "7. Delete from Table"
  echo "8. Back to Main Menu"
  read -p "Enter your choice: " choice
  case "$choice" in
    1 ) create_table;;
    2 ) list_tables;;
    3 ) drop_table;;
    4 ) insert_data;;
    5 ) select_from_table;;
    6 ) update_table;;
    7 ) delete_from_table;;
    8 ) cd ..; main_menu;;
    * ) echo "Invalid choice"; table_menu;;
  esac
}

# Define function to create tables
function create_table {
  read -p "Enter the name of the table: " tablename 
  validate_name "$tablename"
  if [ $? -ne 0 ]; then
    return
  fi

  if [ -e "$tablename" ]; then
    echo "A file with the same name exists."
    create_table
    return
  fi

  touch "$tablename"  
  read -p "Enter the name of the primary key column (must be unique for each row): " pk_colname
  read -p "Enter the data type for the primary key column (integer/float/string): " pk_datatype

  while true; do
    read -p "Enter the number of additional columns (excluding the primary key column): " numcols 
    if [ $numcols -lt 1 ]; then
      echo "Error: At least one additional column is required"
    else
      break
    fi
  done

  cols="$pk_colname:$pk_datatype PRIMARY KEY" # Initializes the string with the primary key column name and data type

  # Loop through the number of columns specified by the user and prompt them to enter the name and data type for each column
  for (( i=1; i<=$numcols; i++ )); do
    read -p "Enter the name of column $i: " colname
    read -p "Enter the data type for column $i (string/integer/float): " datatype

    # Append the column name and data type to the string, separated by a comma
    cols+=",$colname:$datatype"
  done

  # Write the column names and data types to the table file
  echo "$cols" > "$tablename"

  echo "Table created successfully"
  read -p "Press enter to continue"

  table_menu
}

#**************************************************************************************************************************

# Define the function to list all tables
function list_tables {
  clear 
  echo "List of Tables" 
  echo "--------------"
  
  # Loops through all the  files in the current directory and removes the "" extension to display only the table names
  for table in *; do
    echo "${table}"
  done
  
  read -p "Press enter to continue" 
  table_menu 
}

#**************************************************************************************************************************

# Define the function to drop a table
function drop_table {
  read -p "Enter the name of the table: " tablename
  if [ -f "$tablename" ]; then
    rm "$tablename"
    echo "Table dropped successfully"
  else
    echo "Table does not exist"
  fi
  read -p "Press enter to continue"
  table_menu
}
#**************************************************************************************************************************

# Define the function to insert data into a table
function insert_data {
  read -p "Enter the name of the table: " tablename

  if [ -f "$tablename" ]; then
    cols=$(head -n1 "$tablename")
    IFS=',' read -ra col_parts <<< "$cols"
    colnames=()
    coltypes=()
    pk_colname=""
    for col_part in "${col_parts[@]}"; do
      colname=$(echo "$col_part" | cut -d':' -f1)
      coltype=$(echo "$col_part" | cut -d':' -f2)
      coltypes+=("$coltype")
      colnames+=("$colname")
      if echo "$col_part" | grep -q "PRIMARY KEY"; then
        pk_colname="$colname"
        pk_col_index=$i
      fi
    done
    numcols=$(echo "$cols" | tr ',' '\n' | wc -l)

    pk_datatype=$(echo "${coltypes[0]}" | cut -d' ' -f1)

    while true; do
      read -p "Enter the data for the $pk_colname column: " pk_data
      while ! validate_data "$pk_data" "${pk_datatype}"; do
        echo "Invalid data type for column $pk_colname"
        read -p "Enter a valid value for the $pk_colname column: " pk_data
      done

      # Check if the primary key value already exists in the table
      pk_col=$(cut -d',' -f1 "$tablename")
      if grep -q "^$pk_data," "$tablename"; then
        echo "Error: The value '$pk_data' already exists in the table for the $pk_colname column."
      else
        break
      fi
    done

    values=""
    for (( i=2; i<=$numcols; i++ )); do
      read -p "Enter the data for column ${colnames[$i-1]}: " data
      while ! validate_data "$data" "${coltypes[$i-1]}"; do
        echo "Invalid data type for column ${colnames[$i-1]}"
        read -p "Enter a valid value for the ${colnames[$i-1]} column: " data
      done
      values+="$data,"
    done

    # Remove the trailing comma from the values string
    values="${values%,}"

    # Insert the data into the table file
    echo "$pk_data,$values" >> "$tablename"

    echo "Data inserted successfully"
    read -p "Press enter to continue"

    table_menu
  else
    echo "Table does not exist"
    read -p "Press enter to continue"

    table_menu
  fi
}

#******************************************************************************************************************************************************

# Define the function to select data from the table
function select_from_table {
  read -p "Enter the name of the table: " tablename 

  if [ -f "$tablename" ]; then
    cols=$(head -n1 "$tablename") # Reads the first line of the table file to get the column names and data types
    IFS=',' read -ra col_parts <<< "$cols"
    colnames=()
    for col_part in "${col_parts[@]}"; do
      colname=$(echo "$col_part" | cut -d':' -f1)
      colnames+=("$colname")
    done
    numcols=$(echo "$cols" | tr ',' '\n' | wc -l) # Counts the number of columns in the table file

    echo "${colnames[@]}"
    echo "---------------"

    read -p "Do you want to select specific data from a column (y/n)? " select_data # Prompts the user to select specific data from a column

    if [[ "$select_data" == "y" ]]; then 
      read -p "Enter the name of the column: " column_name 

      read -p "Do you want to select all data in the $column_name column (a) or apply a condition (b)? " select_option 

      col_index=-1
      for ((i=0;i<${#colnames[@]};i++)); do
        if [[ "${colnames[$i]}" == "$column_name" ]]; then
          col_index=$i
          break
        fi
      done

      if [[ $col_index -eq -1 ]]; then
        echo "Column not found in table"
      else
        # Loop through the rows and retrieve the values in the specified column
        values=()
        mapfile -t lines < "$tablename"
        for ((i=1;i<${#lines[@]};i++)); do
          IFS=',' read -ra row <<< "${lines[i]}"
          value="${row[$col_index]}"
          if [[ "$value" == "NULL" ]]; then
            value=0
          fi
          values+=("$value")
        done

        if [[ "$select_option" == "a" ]]; then
          # Display all data in the selected column
          echo "${values[@]}"
        elif [[ "$select_option" == "b" ]]; then
          read -p "Enter the condition (e.g., >5, ==\"John\", etc.): " condition 

          # Filter the data based on the condition
          echo "Values in the $column_name column that satisfy the condition $condition:"
          for value in "${values[@]}"; do
            if (( $(bc <<< "$value $condition") )); then
              echo "$value"
            fi
          done
        else
          echo "Invalid option"
        fi
      fi
    else
      echo "Selected all data from table \"$tablename\""
      cat "$tablename"  # Display all data in the table
    fi
  else
    echo "Table does not exist" # Displays an error message if the table file does not exist
  fi

  read -p "Press enter to continue"
  table_menu 
}


#************************************************************************************************************************************************

# Define the function to update data in a table
function update_table {
  read -p "Enter the name of the table: " tablename 

  if [ -f "$tablename" ]; then
    cols=$(head -n1 "$tablename")
    IFS=',' read -ra col_parts <<< "$cols"
    colnames=()
    coltypes=()
    pk_colname=""
    for col_part in "${col_parts[@]}"; do
      colname=$(echo "$col_part" | cut -d':' -f1)
      coltype=$(echo "$col_part" | cut -d':' -f2)
      coltypes+=("$coltype")
      colnames+=("$colname")
      if echo "$col_part" | grep -q "PRIMARY KEY"; then
        pk_colname="$colname"
        pk_col_index=$i
      fi
    done

    echo "$cols" # Displays the column names
    echo "---------------"
    tail -n +2 "$tablename" | awk '{print}' ORS='\n' # Displays the contents of the table, starting with the second line (skipping the column names)
    echo # Adds an empty line for formatting purposes

    read -p "Enter the name of the primary key column: " pk_colname
    while ! [[ " ${colnames[@]} " =~ " ${pk_colname} " ]]; do
      read -p "No column named $pk_colname exists. Please enter a valid column name: " pk_colname
    done
    
    read -p "Enter the value of the primary key for the row to update: " pk_value
    while ! grep -q "^$pk_value," "$tablename"; do
      read -p "No row with primary key value of $pk_value exists. Please enter a valid primary key value: " pk_value
    done

    # Read the input file into an array
    mapfile -t lines < "$tablename"

    # Find the index of the row with the given primary key value
    index=-1
    for ((i=1;i<${#lines[@]};i++)); do
      IFS=',' read -ra row <<< "${lines[i]}"
      pk_col_index=$(echo "$cols" | tr ',' '\n' | grep -n "^$pk_colname:" | cut -d':' -f1)
      if [[ "${row[$pk_col_index-1]}" == "$pk_value" ]]; then
        index=$i
        break
      fi
    done

    # Check if the primary key value exists in the table
    if [[ $index -eq -1 ]]; then
      echo "Primary key not found in table"
    else
      # Save the row to update in an array
      IFS=',' read -ra row_to_update <<< "${lines[index]}"
      echo "Row to update: ${lines[index]}"

      # Loop through the columns and ask the user to enter a new value for each one
      for ((i=0;i<${#row_to_update[@]};i++)); do
        colname="${colnames[$i]}"
        col_datatype="${coltypes[$i]}"
        basic_datatype=${col_datatype%%\(*)} # Extract the basic data type (e.g. "int" or "string")

        if [[ "$colname" != "$pk_colname" ]]; then
          read -p "Enter new value for $colname ($basic_datatype): " new_value
          while ! validate_data "$new_value" "$basic_datatype"; do
            read -p "Invalid input. Please enter a value of type $basic_datatype: " new_value
          done

          # Update the corresponding value in the row with the new value
          row_to_update[$i]="$new_value"
        fi
      done

      # Replace the old row with the updated row
      lines[$index]=$(IFS=','; echo "${row_to_update[*]}")
      echo "Updated row: ${lines[index]}"

      # Write the updated table to a temporary file
      tmpfile=$(mktemp)
      printf "%s\n" "${lines[@]}" > "$tmpfile"

      # Replace the original file with the temporary file
      mv "$tmpfile" "$tablename"

      echo "Row with primary key value of $pk_value updated successfully."
    fi
  else
    echo "Table $tablename does not exist. Aborting update."
    return
  fi

  read -p "Press enter to continue"
  table_menu
}



# Define function to delete_from_table
function delete_from_table {
  read -p "Enter the name of the table: " tablename 

  if [ -f "$tablename" ]; then
    cols=$(head -n1 "$tablename")
    IFS=',' read -ra col_parts <<< "$cols"
    colnames=()
    coltypes=()
    pk_colname=""
    for col_part in "${col_parts[@]}"; do
      colname=$(echo "$col_part" | cut -d':' -f1)
      coltype=$(echo "$col_part" | cut -d':' -f2 | sed 's/ PRIMARY KEY//')
      coltypes+=("$coltype")
      colnames+=("$colname")
      if echo "$col_part" | grep -q "PRIMARY KEY"; then
        pk_colname="$colname"
        pk_col_index=$i
      fi
    done

    echo "${colnames[@]}" # Displays the column names
    echo "${coltypes[@]}" # Displays the column data types
    echo "---------------"
    tail -n +2 "$tablename" | awk '{print}' ORS='\n' # Displays the contents of the table, starting with the second line (skipping the column names)
    echo # Adds an empty line for formatting purposes

    read -p "Enter the name of the column to delete by condition: " colname
    while ! [[ " ${colnames[@]} " =~ " ${colname} " ]]; do
      read -p "No column named $colname exists. Please enter a valid column name: " colname
    done

    # Find the index of the column
    col_index=-1
    for ((i=0;i<${#colnames[@]};i++)); do
      if [[ "${colnames[$i]}" == "$colname" ]]; then
        col_index=$i
        break
      fi
    done

    # Check if the column exists in the table
    if [[ $col_index -eq -1 ]]; then
      echo "Column not found in table"
    else
      # Loop through the rows and retrieve the values in the specified column
      values=()
      mapfile -t lines < "$tablename"
      for ((i=1;i<${#lines[@]};i++)); do
        IFS=',' read -ra row <<< "${lines[i]}"
        value="${row[$col_index]}"
        values+=("$value")
      done

      # Prompt the user for the condition
      read -p "Enter the condition for deleting rows (e.g. >2 for numeric columns or string to search for in string columns): " condition

      # Loop through the rows and delete those that satisfy the condition
      for ((i=1;i<${#lines[@]};i++)); do
        IFS=',' read -ra row <<< "${lines[i]}"
        value="${row[$col_index]}"
        col_datatype="${coltypes[$col_index]}"
        basic_datatype=${col_datatype%%\(*)}

        if [[ "$basic_datatype" == "int" ]]; then
          if (( "$value" $condition )); then
            row[$col_index]="NULL"
            lines[$i]=$(IFS=','; echo "${row[*]}")
          fi
        elif [[ "$basic_datatype" == "string" ]]; then
          echo "Condition not supported for string data type."
        else
          echo "Unsupported data type: $basic_datatype"
        fi
      done

      # Write the updated table to a temporary file
      tmpfile=$(mktemp)
      printf "%s\n" "${lines[@]}" > "$tmpfile"

      # Replace the original file with the temporary file
      mv "$tmpfile" "$tablename"

      echo "Rows where $colname $condition deleted successfully."
    fi
  else
    echo "Table $tablename does not exist. Aborting delete."
    return
  fi

  read -p "Press enter to continue"
  table_menu
}

#****************************************************************************************************************************

function validate_data {
  local data="$1"
  local datatype="$2"

  case "$datatype" in
    int)
      if [[ "$data" =~ ^-?[0-9]+$ ]]; then
        return 0
      else
        return 1
      fi
      ;;
    string)
      if [[ "$data" =~ ^[a-zA-Z]+$ ]]; then
        return 0
      else
        return 1
      fi
      ;;
    *)
      echo "Invalid data type: $datatype"
      return 1
      ;;
  esac
}

function validate_name {
  local name="$1"
  if [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    return 0
  else
    return 1
  fi
}


# Call the main menu function
main_menu
