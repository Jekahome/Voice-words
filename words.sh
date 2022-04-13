#!/bin/bash

# Startup arguments:
#
# dir/d - directory with sound files, default source="words"
# limit/l - count play file , default all words
# random/r - sorted unique files, default true
# timeout/t - pause play, default 0s
# recursion/R - recursive search of all files, default false
# extensions/e - file's extensions, default mp3
# check-translation/ct - enter translation, default true
# reverse-check-translation/rct - enter original translation, default false
# random-translation/rt - enter a translation of the original or source word or do not type anything randomly, default false
#
# Example:
#
# ./words.sh l=2 t=1 d="words" r=true
# ./words.sh limit=2 timeout=1 dir="words" random=true
# ./words.sh d="words" r=true
# ./words.sh r=true l=5 t=3
# ./words.sh r=true l=5 t=3 R=true e=mp3
#
# ./words.sh ct=true
# ./words.sh rct=true
# ./words.sh rt=true

# You need : sudo apt install sqlite3

source="words"  # folder mp3 files
limit=0
timeout=0 # timeout beetwen sound word, s-seconds, m-minute
isRandom=true
fileExtension="mp3"
isRecursion=false
isCheckTranslation=true
isReverseCheckTranslation=false
isRandomTranslation=false

storeSoundWords=();
isWasSoundIndex=true;
words=()
error_words=()
isErrorTranslate=false

sqlite3=$('which' sqlite3)
DB_FILE="db/words.db"
 
function createTables(){
$sqlite3 $DB_FILE  "
        create table IF NOT EXISTS words (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                word TEXT UNIQUE NOT NULL,
                translate TEXT DEFAULT '""',
                sentences TEXT DEFAULT '""');"
}

function deleteTables(){
 $(sqlite3 $DB_FILE "delete from words");
}

function showAllWordsDb(){
 echo $(sqlite3 $DB_FILE "select * from words");
}
 
function dump(){
 $(sqlite3 $DB_FILE .dump > "dump/dump_words_$(date +"%m-%d-%Y").sql")
# cat dump_words.sql | sqlite3 words.db
}
function import() {
   $(cat $1.sql | sqlite3 db/words.db)
}

function formatText(){
 echo -e "\e[31m${1}\e[0m"
}

function formatTextBold(){
 echo -n -e "\e[1;33m${1}\e[0m"
}
 
function formatBackground(){
 echo -e "\e[35;47m${1}\e[0m"
}

function formatBold(){
 echo -e "\e[1m${1}\e[0m"
}

function formatWord(){
 echo -e "\e[1;42m${1}\e[0m\n"
}

function formatWordSentence(){
 echo -e "\e[1;32m${1} => $2\e[0m\n"
}

function isCorrectTranslation(){

   if [ "$2" ] && echo "$1" | grep -iqw "$2";
   then
     return 0;
   else
       echo -n -e "\e[31mCorrect result: \e[0m"
       echo -n -e "\e[31;4m${1}\e[0m\n"
       sleep 1s

        for key in "${error_words[@]}";
        do
            if [ "$key" = "$3" ];
            then
              return 0;
             fi
        done

        isErrorTranslate=true
        error_words+=("$3")
   fi
}

function setEnumTranslation(){
       # 0 - isCheckTranslation && isReverseCheckTranslation = false
       # 1 - isCheckTranslation = true
       # 2 - isReverseCheckTranslation = true
        enum_translation="$(( ( RANDOM % 3 )))"
            case $enum_translation in
               0)
                   isCheckTranslation=false
                   isReverseCheckTranslation=false
                    ;;
               1)
                   isCheckTranslation=true
                   isReverseCheckTranslation=false
                    ;;
               2)
                   isCheckTranslation=false
                   isReverseCheckTranslation=true
                    ;;
               *)
                   isCheckTranslation=false
                   isReverseCheckTranslation=false
                    ;;
          esac
}

function sound() {
    $(mplayer -really-quiet "${1}" 2> ./log/mplayer_errors.log);
}

function saveDbOrShow(){
    IFS='|'; 
    read -r -a res <<< $(sqlite3 $DB_FILE "select translate,sentences from words where word='"${1}"' limit 1;");
    unset IFS;

    if [[ $res == "" ]]
    then
      formatBackground "This word needs to be added."
      sound "$2"
      formatTextBold "Enter the word translation \"${1}\": "
      read  -r input_translate
      input_translate="$(echo -e "${input_translate}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      formatTextBold "Enter example in english for \"${1}\": "
      read  -r input_sentence
      input_sentence="$(echo -e "${input_sentence}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      input_translate=${input_translate//[^a-z0-9а-я,."'" ]/ }
      input_sentence=${input_sentence//[^a-z0-9а-я,."'" ]/ }
 
      $sqlite3 $DB_FILE " insert into words (word,translate,sentences) values  (\"${1}\", \"${input_translate}\", \"${input_sentence}\");"
      formatWordSentence "$1" "$input_sentence"
    else

           if [ "$isRandomTranslation" = true ]
           then
              setEnumTranslation
           fi

          if [ "$isCheckTranslation" = true ] && [ "$isReverseCheckTranslation" = false ];
          then
            formatWordSentence "$1" "${res[1]}"
            echo -n "Enter the translation for \"${1}\": "
            sound "$2"
            read  -r input_translation
            input_translation="$(echo -e "${input_translation}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            isCorrectTranslation "${res[0]}" "$input_translation" "$2"
          elif  [ "$isReverseCheckTranslation" = true ];
          then
            # Only origin original
            pattern="s/$1/.../ig"
            echo "$(echo -e "${res[1]}" | sed  -e $pattern)"

            echo -n "Enter the original translation \"${res[0]}\": "
            read  -r input_translation
            input_translation="$(echo -e "${input_translation}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            sound "$2"
            isCorrectTranslation "${1}" "$input_translation" "$2"
            formatWordSentence "$1" "${res[1]}"
          else
            formatWordSentence "$1" "${res[1]}"
          fi
    fi
}

function setRandomTranslation(){
   if [ -n "$1" ]
    then
        if [ "$1" = true ]
        then isRandomTranslation=true
        else isRandomTranslation=false
        fi
    fi
}

function setReverseCheckTranslation(){
  if [ -n "$1" ]
    then
        if [ "$1" = true ]
        then isReverseCheckTranslation=true
        else isReverseCheckTranslation=false
        fi
    fi
}

function setCheckTranslation(){
  if [ -n "$1" ]
    then
        if [ "$1" = true ]
        then isCheckTranslation=true
        else isCheckTranslation=false
        fi
    fi
}

function setRecursion(){
    if [ -n "$1" ]
    then
        if [ "$1" = true ]
        then isRecursion=true
        else isRecursion=false
        fi
    fi
}

function setExtensions(){
    if [ -n "$1" ]
    then   
        fileExtension="$1"
    fi
}


function isDirExists() {
    if ! [ -n "$1" ] || ! [ -d "$1" ];
        then  
            echo "Directory '$1' not found!" 1>&2
	        exit 1
    fi
}

function setSourceDir(){
    if [ -n "$1" ] && [ -d "$1" ]
    then
        source=$1
    else
        echo "The directory with files is missing or not accessible for reading!" 1>&2
	    exit 1 
    fi
}

function isNumeric(){
    if [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null
        then return 1
    elif [ -n "$2" ]
    then
      echo "`$2` must be a numeric value!" 1>&2
      exit 1
    else
       echo "Data type must be a numeric!" 1>&2
       exit 1
    fi 
}

function setLimit(){
    if [ -n "$1" ]
    then
        limit=$1
    else 
        echo "Arguments function 'setLimit' not found!" 1>&2
	    exit 1
    fi
}

function setRandom(){
    if [ -n "$1" ]
    then
        if [ "$1" = true ]
        then isRandom=true
        else isRandom=false
        fi
    fi
}

function setTimeout(){
    if [ -n "$1" ]
    then
        timeout=$1
    else 
        echo "Arguments function 'setTimeout' not found!" 1>&2
	    exit 1
    fi
}


function setSettings(){
    index=`expr index "$1" =`;

    key=${1:0:$index-1}
    value=${1:$index}

    if [ "$key" = "dir" ] || [ "$key" = "d" ]
    then
      isDirExists "$value"
      setSourceDir "$value"
    elif [ "$key" = "limit" ] || [ "$key" = "l" ]
    then
      isNumeric $value $key
      setLimit $value
    elif [ "$key" = "random" ] || [ "$key" = "r" ]
    then
       setRandom $value
    elif [ "$key" = "timeout" ] || [ "$key" = "t" ]
    then
      isNumeric $value $key
      setTimeout $value
    elif [ "$key" = "recursion" ] || [ "$key" = "R" ]
    then
      setRecursion $value
    elif [ "$key" = "extensions" ] || [ "$key" = "e" ]
    then
      setExtensions $value
    elif [ "$key" = "check-translation" ] || [ "$key" = "ct" ]
    then
      setCheckTranslation $value
     elif [ "$key" = "reverse-check-translation" ] || [ "$key" = "rct" ]
    then
      setReverseCheckTranslation $value
    elif [ "$key" = "random-translation" ] || [ "$key" = "rt" ]
    then
        setRandomTranslation $value
    elif [ "$1" = "--help" ] || [ "$1" = "help" ]
    then
      echo "Key not found. The key must be one of these:
      dir/d
      limit/l
      random/r
      timeout/t
      recursion/R
      check-translation/ct
      reverse-check-translation/rct
      random-translation/rt

      Exampl:
      ./words.sh ct=true
      ./words.sh rct=true
      ./words.sh rt=true
      " 1>&2
	  exit 0
    else
      echo "Configuration key not found"
      exit 1
    fi
}



function showWord(){
 if [ -n "$1" ]
    then
      local full_path_word=$1
      indexSepExt=`expr index "$full_path_word" .`;
      local name_word="${1:0:$indexSepExt-1}"
      
      indexSepExt=`expr index "$name_word" /`;
       
        while [ $indexSepExt -gt 0 ]
        do
         name_word="${name_word:$indexSepExt}"
         indexSepExt=`expr index "$name_word" /`;
        done
         saveDbOrShow "${name_word:$indexSepExt}" "$full_path_word"
    fi
}

function loadWords(){
   if [ "$isErrorTranslate" = true ]; then
        # words=()
        unset words[@]
        words="${error_words[*]}"
        # error_words=()
        unset error_words[@]
        isErrorTranslate=false
    elif [ $isRecursion = true ]; then
        words=($(find "$source" -name "*.$fileExtension"));
    else
        words=($(find "$source" -maxdepth 1 -name "*.$fileExtension"));
    fi
}


function isUniqueSoundIndex(){
   if [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null
   then  
        isWasSoundIndex=false
        isUniqueWord="${words[$1]}"
 
        for unique_word in "${storeSoundWords[@]}";
        do 
             if [ "$unique_word" = "$isUniqueWord" ]
             then 
                isWasSoundIndex=true 
             fi
        done    
   fi
}

function generateUniqueSoundIndex(){
  
        while [ $isWasSoundIndex = true ]
        do
          local index="$(( ( RANDOM % ${#words[@]} )))"
          isUniqueSoundIndex $index
        done
        storeSoundWords=("${storeSoundWords[@]}" ${words[$index]})
        isWasSoundIndex=true;
}

function runSounds(){
    loadWords

    if [ $limit -eq 0 ] || [ $limit -gt ${#words[@]} ]
    then 
        limit=${#words[@]}
    fi

            if [ $isRandom = true ]
            then
                isWasSoundIndex=true
                for (( i=0; i<$limit; i++ ));
                do
                   generateUniqueSoundIndex 
                done
                isWasSoundIndex=false

                for unique_word in "${storeSoundWords[@]}";
                do 
                    sleep "$timeout"s
                    showWord "$unique_word";
                    #$(mplayer -really-quiet "$unique_word" 2> ./log/mplayer_errors.log);   # &>/dev/null
                done
                storeSoundWords=()
            else
               for (( i=0; i<$limit; i++ ));
                do
                   showWord "${words[$i]}";
                   #$(mplayer -really-quiet "${words[$i]}" 2> ./log/mplayer_errors.log);
                   sleep "$timeout"s
                done
            fi


            if [ "$isErrorTranslate" = true ]
            then
              runSounds
            fi
}

#############################################
# before
#############################################
#deleteTables
#dump
#exit;




#############################################
# start
#############################################

    if [ $# -eq 0 ]  
    then
       # no arguments   
       # initialization with default values
      isDirExists "$source"
      
    elif [ $# -ge 0 ]
    then
      # there are arguments
      # checking all keys
        for key_setting in "$@";  
        do 
             setSettings "$key_setting"
        done
      
    fi

# initial sqlite3 databases
createTables

# start word play

runSounds


exit 0;





