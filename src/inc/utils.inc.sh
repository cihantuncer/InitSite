#!/bin/bash

date=`date +%R\ %d-%m-%Y`     # datestamp
date2=`date '+%d-%m-%Y_%H-%M-%S'` # datestamp
scriptLog=""                  # Log File
logEnabled=0                  # Logging indicator
EWIS=""                       # "Message conditions" for all functions
FOUT=""                       # "Return buffer" for all functions

# --- Base Functions ------------------------

# Messages & Stats ----

# Message
# params(2): ["message"] [write to scriptLog ""|1]

function msg {

    local message=$( style "$1")
    local writeLog=$2
    local logStr="$date $1"

    if [[ "$writeLog" == "1" ]] || [[ -z "$writeLog" && "$logEnabled" == "1" ]]; then
        scriptLog="$scriptLog\n$logStr";
    fi

    echo -e "$message"
}

### Error/Warn/Success/Info Messages #############
# params(4): [blink ""|!] ["message"] [write to scriptLog ""|1] [output condition]
# [output condition](OR global EWIS value): <empty>|"error warning info success"

# Example: Simple success message
# > msgSucc "Finished successfully."

# Example: Blinking warning message
# > msgWarn "!" "Files not found."

# Example: Show error message also write it to script logs.
# > msgErr "Something went wrong." 1

# Example: Show messages according to "tewis(this e/w/i/s)" condition.
# > msgCond="err warn"; --> Shows only errors and warnings.
# > msgSuccess "Success message here, but it will not be shown." "" $msgCond

# Example: Show messages according to "EWIS" global condition.
# > setEWIS "succ warn"; --> Shows only successes and warnings.
# > msgErr "Error message here, but it will not be shown."
# > setEWIS "succ inf"; --> Shows only successes and infos.
# > msgSucc "!" "Blinking success message here, it will be shown."
# > setEWIS ""; --> Shows all e/w/i/s messages. (If "tewis(this e/w/i/s)" parameter is not given.)
# > msgErr "This is an error and will be shown."

# Note: "tewis" priority > "scriptEWIS" priority > "EWIS" priority

function msgErr {

    color="red"
    local tewis=$2
    local writeLog=$3
    local logStr="$date $1"

    if [[ "$writeLog" == "1" ]] || [[ -z "$writeLog" && "$logEnabled" == "1" ]]; then
        scriptLog="$scriptLog\n$logStr";
    fi

    if [[ -z "$tewis" && -z "$EWIS" ]] || [[ -z "$tewis" && "$EWIS" == *"err"* ]] || \
       [[ "$tewis" == *"err"* ]] || [[ "$EWIS" == *"debug"* ]]; then

        if [[ "$1" == "!" ]]; then
            local message=$( style "<$color><!>$2</!></$color>")
            shift
        else
            local message=$( style "<$color>$1</$color>")
        fi

        echo -e "$message" 
    fi

}

function statErr {

    if [[ "$1" == "!" ]]; then 
        msgErr $1 "[ERROR] $2" $3 $4 
    else
        msgErr "[ERROR] $1" "$2" $3
    fi
}

function msgWarn {

    color="yellow"
    local tewis=$2
    local writeLog=$3
    local logStr="$date $1"

    if [[ "$writeLog" == "1" ]] || [[ -z "$writeLog" && "$logEnabled" == "1" ]]; then
        scriptLog="$scriptLog\n$logStr";
    fi

    if [[ -z "$tewis" && -z "$EWIS" ]] || [[ -z "$tewis" && "$EWIS" == *"warn"* ]] || \
       [[ "$tewis" == *"warn"* ]] || [[ "$EWIS" == *"debug"* ]]; then

        if [[ "$1" == "!" ]]; then
            local message=$( style "<$color><!>$2</!></$color>")
            shift
        else
            local message=$( style "<$color>$1</$color>")
        fi

       echo -e "$message"
    fi

}

function statWarn {

    if [[ "$1" == "!" ]]; then 
        msgWarn $1 "[WARNING] $2" $3 $4 
    else
        msgWarn "[WARNING] $1" "$2" $3
    fi
}

function msgSucc {

    color="green"
    local tewis=$2
    local writeLog=$3
    local logStr="$date $1"

    if [[ "$writeLog" == "1" ]] || [[ -z "$writeLog" && "$logEnabled" == "1" ]]; then
        scriptLog="$scriptLog\n$logStr";
    fi

    if [[ -z "$tewis" && -z "$EWIS" ]] || [[ -z "$tewis" && "$EWIS" == *"succ"* ]] || \
       [[ "$tewis" == *"succ"* ]] || [[ "$EWIS" == *"debug"* ]]; then

        if [[ "$1" == "!" ]]; then
            local message=$( style "<$color><!>$2</!></$color>")
            shift
        else
            local message=$( style "<$color>$1</$color>")
        fi

        echo -e "$message"
    fi

}

function statSucc {

    if [[ "$1" == "!" ]]; then 
        msgSucc "$1" "[SUCCESS] $2" "$3" "$4" 
    else
        msgSucc "[SUCCESS] $1" "$2" "$3"
    fi
}

function msgInfo {

    local tewis=$2
    local writeLog=$3
    local logStr="$date $1"

    if [[ "$writeLog" == "1" ]] || [[ -z "$writeLog" && "$logEnabled" == "1" ]]; then
        scriptLog="$scriptLog\n$logStr";
    fi

    if [[ -z "$tewis" && -z "$EWIS" ]] || [[ -z "$tewis" && "$EWIS" == *"inf"* ]] || \
       [[ "$tewis" == *"inf"* ]] || [[ "$EWIS" == *"debug"* ]]; then

        if [[ "$1" == "!" ]]; then
            local message=$( style "<!>$2</!>")
            shift
        else
            local message=$( style "$1")
        fi

       echo -e "$message"
    fi
}

function statInfo {

    if [[ "$1" == "!" ]]; then 
        msgInfo $1 "[INFO] $2" $3 $4 
    else
        msgInfo "[INFO] $1" "$2" $3
    fi
}

function msgDebug {

    local tewis=$2
    local writeLog=$3
    local logStr="$date $1"

    if [[ "$writeLog" == "1" ]] || [[ -z "$writeLog" && "$logEnabled" == "1" ]]; then
        scriptLog="$scriptLog\n$logStr";
    fi

    if [[ -z "$tewis" && "$EWIS" == *"debug"* ]] || [[ "$tewis" == *"debug"* ]]; then

        if [[ "$1" == "!" ]]; then
            local message=$( style "<!>$2</!>")
            shift
        else
            local message=$( style "$1")
        fi

        echo -e "$message"
    fi
}


# Set/Remove Error/Warning/Info/Success conditions
# If scriptEWIS is present, It overrides EWIS.
# If tewis parameter is present, It overrides scriptEWIS.
# Note: "tewis" priority > "scriptEWIS" priority > "EWIS" priority

# params(1): [output condition]

function setEWIS {

    if [[ -z $scriptEWIS ]]; then
        EWIS="$1"
    else
        EWIS=$scriptEWIS
    fi
}

# # params(0)

function removeEWIS {

    if [[ -z $scriptEWIS ]]; then
        EWIS=""
    else
        EWIS=$scriptEWIS
    fi
}

#################################################

# Write script logs to script/path/log/file.log

function writeLog {

    local logPath="$SCRIPT_PATH/log"
    local logFile="$logPath/$scname $date2.log"

    mkdir -p "$logPath"
    touch "$logFile"

    if [ -f "$logFile" ]; then
        echo -e "$scriptLog" > "$logFile"
    fi
}

function exitScript {

    if [[ -z $1 ]]; then
        exitLevel=1
    else
      exitLevel=$1
    fi

    if [[ "$logEnabled" == "1" ]]; then
        writeLog
    fi

    exit $exitLevel
}

 
function yesNo {

    FOUT="";
    
    local errmsg="Please enter (y)es or (n)o"
    
    [ "$2" ] && errmsg="$2"
    
	while true; do
    
    	read -p "$( msgWarn "$1 " )"  inpt
        
	    case $inpt in
	        [yY] | [yY][Ee][Ss] ) FOUT="1"; break;;
	        [nN] | [n|N][O|o]   ) FOUT="0"; break;;
	                           *) FOUT="";  msgErr "$errmsg";;
	    esac
	done
}

# params(1) : [Count down seconds]
# returns   : none
 
function countDown {

	echo ""

	secs=$1

	while true; do
	         
		if [ "$secs" == "0" ]; then
			break;
		else
			echo "...$secs"
			sleep 1
		fi

		((secs--))

	done 


	echo ""
}

# Prompt    : Get User Input (Can be empty)
# params(1) : ["Message for Prompt"]
# returns   : user input

function getInput {

    FOUT=""
    
    read -p "$( msg "$1 " )"  inpt
        
	FOUT=$inpt
}

# Prompt    : Forced Get User Input (Can't be empty)
# params(2) : ["Message for Prompt"] ["Message for Input Error"]
# returns   : user input

function getFInput {

    FOUT="";
    
    local errmsg="Input is empty, please enter again"
    
    [ "$2" ] && errmsg="$2"
    
	while true; do
    
    	read -p "$( msgWarn "$1 " )"  inpt
        
	    if [ -z "$inpt" ]; then
        
		      FOUT="";  msgErr "$errmsg";
		else
		      FOUT=$inpt; break;
		fi
        
	done
}

# Prompt    : Get User Input as Password with Confirmation
# params(2) : ["Message for Prompt"] ["Message for Input Error"]
# returns   : password

function getPasswd {

    FOUT="";
    
    local errmsg="Input is empty, please enter password again"
    
    [ "$2" ] && errmsg="$2"
    
	pmsg="$1"

    passwd=""
    
	while true; do
    
    	read -s -p  "$( msgWarn "$pmsg " )"  inpt
        
	    if [ -z "$inpt" ]; then
        	echo ""
		    FOUT="";  msgErr "$errmsg";
		else
			if [ "$passwd" == "" ]; then
                
                passwd="$inpt"
                echo ""
                pmsg="Confirm password:"
                
                
			else
                             
                if [ "$inpt" != "$passwd" ]; then
                	
                	echo ""; msgErr "Passwords do not match. Please enter again.";
                    
                    passwd=""
                    pmsg="$1"
                
                else
                
                	FOUT="$inpt"; break;
                
                fi
              
              fi
 	              
		fi
	done
	echo ""
}

# Prompt    : Get Number Input from User (Can't be empty)
# params(2) : ["Message for Prompt"] ["Message for Input Error"]
# returns   : user input (number)

function getNumber {

    FOUT="";
    
    local errmsg="Please enter a number";
    
    [ "$2" ] && errmsg="$2"
    
    while true; do
    
        read -p "$( msgWarn "$1 " )" inpt

        if ! [[ "$inpt" =~ ^[0-9]+$ ]]; then
        
            FOUT="";  msgErr "$errmsg";
        else
            FOUT=$inpt; break;
        fi
    done   
}

# Prompt    : Get Positive Number Input from User (Can't be empty)
# params(2) : ["Message for Prompt"] "[Message for Input Error"]
# returns   : user input (positive number)

function getPNumber {

    FOUT="";
    
    local errmsg="Please enter a positive number";
    
    [ "$2" ] && errmsg="$2"
    
    while true; do
    
        read -p "$( msgWarn "$1 " )" inpt

        if [[ "$inpt" =~ ^[0-9]+$ ]] && [ "$inpt" -gt 0 ]; then
            FOUT="$inpt"; break;
        else
        	msgErr "$errmsg";
        fi
    done   
}

# Check   : Check If Value in Array
# params  : ["variable"] [arrayname]
# returns : "index number" for founded / "-1" for not founded

function inArray {

  	local -n arr=$2
    local inArr="-1"
	local i=0;

    for v in "${arr[@]}";
    do  
        if [ "$v" == "$1" ]; then
        
        	inArr=$i
            break;
        fi
        ((i++))
	done
    
    FOUT=$inArr
}

# Numbered Menu : Create Menu from Array, Prompt & Check User Selection
# params(3)     : [arrayname] ["Message for Prompt"] ["Message for Input Error"]
# returns       : selected item value from menu list

function nMenu {

	FOUT="";

    local errmsg="Please enter a number from menu list";
    
    [ "$3" ] && errmsg="$3"

  	local -n arr=$1
    local n=1
    
    for v in "${arr[@]}";
    do 
    	echo "[$n] $v"
        ((n++))
	done

    echo ""
    
    local iNum="0"
   
    while true; do
    
		getPNumber "$2" "$errmsg";
        
        iNum=$(("$FOUT-1"))
                       
        if [ "${arr[$iNum]}" == "" ]; then
        
        	msgErr "$errmsg"
        else
        
        	FOUT="${arr[iNum]}"
            break;
        
        fi
    done  
}

# Add Indent : Adds indents to given multiline text
# params(2)  : [text] [skip first line of given text (Necessary for some cases.) "1"] for .
# returns    : selected item value from menu list

function addIndent {

    local indent="    "
    local text="$1"
    local skipFirst="0";
    
    [ "$2" ] && skipFirst="$2"

    local indented_text=""

    while IFS= read -r line; do

        if [ "$skipFirst" == "1" ]; then

            indented_text+="$line"$'\n'
            skipFirst="0"

            continue;
        fi

        indented_text+="$indent$line"$'\n'

    done <<< "$text"
    echo "$indented_text"
}

# Multi Replace : Replaces contents between given patterns for all occurences
# params(2)     : [start pattern] [end pattern] [replacement content] [target document]
# returns       : Updates target file with given text

function multiReplace {

    local start_pattern="${1}"
    local end_pattern="${2}"
    local replacement_content="${3}"
    local doc="${4}"

    # Temporary file for intermediate storage
    local tmp_file="${doc}.tmp"

    # Extract line numbers for start and end patterns and store them
    local line_numbers=()
    while IFS= read -r line; do
        line_numbers+=("$line")
    done < <(awk -v start="${start_pattern}" -v end="${end_pattern}" '
    BEGIN {
        start_found = 0;
    }
    {
        if ($0 ~ start) {
            if (start_found == 0) {
                start_line = NR;
                start_found = 1;
            }
        }
        if ($0 ~ end && start_found == 1) {
            end_line = NR;
            print start_line, end_line;
            start_found = 0;
        }
    }
    ' "${doc}" 2>/dev/null)

    # Reverse the order of line numbers for correct replacement
    for (( idx=${#line_numbers[@]}-1 ; idx>=0 ; idx-- )) ; do
        start_line=$(echo "${line_numbers[idx]}" | awk '{print $1}')
        end_line=$(echo "${line_numbers[idx]}" | awk '{print $2}')

        # Process each block
        sed -n "1,$((start_line-1))p" "${doc}" > "${tmp_file}"
        echo "${replacement_content}" >> "${tmp_file}"
        sed -n "$((end_line+1)),\$p" "${doc}" >> "${tmp_file}"

        # Move processed content back to the original file
        mv "${tmp_file}" "${doc}"
    done

    # Cleanup temporary file
    rm -f "${tmp_file}"
}

# Trim      : Removes leading and trailing spaces from string
# params(2) : [string]
# returns   : Trimmed string

function trim {
    string="$1"
    trimmed=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "$string")
    
    printf '%s' "$trimmed"
}

# Find String In File : Searches and writes/returns provided string in the provided file  
# params(4)           : [string to be searched] [file path] [info detail level 0|1(default)|2]
#                       [echo to variable 0(default)|1]
# returns             : echoes/returns founded lines (by detail levels)

function findStringInFile {

	declare string=$1
	declare file=$2
	declare details=1
	declare toVar=0
	declare found=""

	if [[ -z $3 ]]; then details=1; else details=$3; fi
	if [[ -z $4 ]]; then toVar=0; else toVar=$4; fi

	local i=0

	{
	while IFS=: read -r line_number line_content; do

		if [[ $details == 0 ]]; then
			str="line $line_number"
		elif [[ $details == 1 ]]; then
			str=$line_content
		elif [[ $details == 2 ]]; then
			str="File: $file, Line: $line_number, Content: $line_content"
		fi

		if [[ $toVar == 1 ]]; then
			found+="\n$str"
		else
			echo "$str"
		fi

		((i++))

	done < <(grep -n "$string" "$file")
	}

	if [[ $toVar == 1 ]]; then
		echo $found
	fi

}


# Check if service exists
# params(1) : [service name]
# returns   : "found"|"notfound"

function isServiceExists {

    local service=$1

    if [[ -n "$service" ]]; then
        if service --status-all | grep -F "$service" > /dev/null 2>&1; then
            echo "found"
        else
            echo "notfound"
        fi
    fi
}

# Check if service is enabled
# params(1) : [service name]
# returns   : "notfound"|"unknown"|"enabled"|"disabled"

function isServiceEnabled {
    
	local service=$1
    exists=$( isServiceExists $service )

	if [[ "$exists" == "found" ]]; then
        systemctl is-enabled $service
    else
        echo "notfound"
	fi
}

# Check if service is active
# params(1) : [service name]
# returns   : "notfound"|"unknown"|"active"|"inactive"

function isServiceActive {

	local service=$1
    exists=$( isServiceExists $service )

    if [[ ! "$exists" == "found" ]]; then
        msgErr "notfound"
    else
        systemctl is-active $service
	fi

}

# Enable service
# params(1) : [service name]
# returns   : Result messages

function enableService {

    local service=$1
    local stat=$(isServiceEnabled $1) 

    if [[ "$stat" == "notfound" ]]; then

        msgErr "$service not found."
        
    elif [[ "$stat" == "enabled" ]]; then

        msgInfo "$service service is already enabled."
    else

        if systemctl enable $service > /dev/null 2>&1; then

            msgSucc "$service service enabled."
        else
            msgErr "$service service could not be enabled."
        fi

    fi
}

# Disable service
# params(1) : [service name]
# returns   : Result messages

function disableService {

    local service=$1
    local stat=$(isServiceEnabled $1) 

    if [[ "$stat" == "notfound" ]]; then

        msgErr "$service service not found."
        
    elif [[ "$stat" == "disabled" ]]; then

        msgInfo "$service service is already disabled."
    else

        if systemctl disable $service > /dev/null 2>&1; then

            msgSucc "$service service disabled."
        else
            msgErr "$service service could not be disabled."
        fi

    fi
}

# Start service
# params(1) : [service name]
# returns   : Result messages

function startService {
    
    local service=$1
    local isActive=$(isServiceActive $1) 

    if [[ "$isActive" == "notfound" ]]; then

        msgErr "$service not found."
        
    elif [[ "$stat" == "active" ]]; then

        msgInfo "$service is already running."
    else

        if systemctl start $service > /dev/null 2>&1; then

            msgSucc "$service service started."
        else
            msgErr "$service service could not be started."
        fi

    fi

}

# Stop service
# params(1) : [service name]
# returns   : Result messages

function stopService {

    local service=$1
    local isActive=$(isServiceActive $1) 

    if [[ "$isActive" == "notfound" ]]; then

        msgErr "$service not found."
        
    elif [[ "$stat" == "inactive" ]]; then

        msgInfo "$service is already stopped."
    else

        if systemctl stop $service > /dev/null 2>&1; then

            msgSucc "$service service stopped."
        else
            msgErr "$service service could not be stopped."
        fi

    fi

}

# Restart service
# params(1) : [service name]
# returns   : Result messages

function restartService {

    local service=$1
    local isActive=$(isServiceActive $1) 

    if [[ "$isActive" == "notfound" ]]; then

        msgErr "$service not found."
        
    else

        if systemctl restart $service > /dev/null 2>&1; then

            msgSucc "$service service restarted."
        else
            msgErr "$service service could not be restarted."
        fi

    fi 
}


# systemctl polyfill

if ! command -v systemctl > /dev/null 2>&1; then

    function systemctl {

        local com="$1"
        local service="$2"

          if [[ "$com" == "is-enabled" ]]; then

            if  ls /etc/rc*.d/* | grep -q "$service" ; then
                echo "enabled"
            else
                echo "disabled"
            fi

        elif [[ "$com" == "is-active" ]]; then

            if service $service status > /dev/null 2>&1; then
                echo "active"
            else
                echo "inactive"
            fi

        elif [[ "$com" == "enable" ]]; then

            update-rc.d $service defaults

        elif [[ "$com" == "disable" ]]; then

            update-rc.d -f $service remove

        elif [[ "$com" == "start" ]]; then

            service $service start

        elif [[ "$com" == "stop" ]]; then

            service $service stop

        elif [[ "$com" == "restart" ]]; then

            service $service restart
        fi

    }	
fi



