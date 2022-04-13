#!/bin/bash

# Startup arguments:
#
# ns - group of words of irregular verbs, from 0 to 12

# Example:
#
# ./verbs_nouns.sh 
# ./verbs_nouns.sh ns=2

# ----------------------------------------------------
# Task: to study the forms of irregular verbs

# Pour in the existing base of frequency irregular verbs and frequency nouns
# Pour in examples of using all words

# Methods of study:
# - ask to enter the desired form of the verb
# - ask to enter on the basis of the verb (rus / en) an example of using a verb with frequency nouns from a
# combination in the right form (the occurrence of the desired form of the verb in the sentence will be checked)
# - ask for a translation
# --------------------------------------------------

sqlite3=$('which' sqlite3)
DB_FILE="db/words.db"
source="irregular_verbs"
source_infinitive="${source}/infinitive"
source_past_simple="${source}/past_simple"
source_past_participle="${source}/past_participle"
number_similarity=2 # between 0-12
number_programm=1
fileExtension="mp3"
help_dir="help"

#0: const - которые не видоизменяются
#1: const_2_3, - идентичные в Present и Past Patriciple
#2: const_o_in_2_3, - с -О- в Past и Past Participle
#3: const_o_in_2, - с -О- только в Past
#4: const_ew_in_2_own_in_3, - на -EW во второй колонке и на -OWN в третьей
#5: const_n_in_3, -  с -N в конце в третьей колонке
#6: common_topic_work, - работа
#7: common_topic_home, - домашние дела
#8: common_topic_senses, - чувства
#9: common_topic_negative, - негатив
#10: common_topic_fidget, - непоседа
#11: common_topic_state, - состояние
#12: common_topic_training, - обучение

similarity_array=("const" "const_2_3" "const_o_in_2_3" "const_o_in_2" "const_ew_in_2_own_in_3" "const_n_in_3" "common_topic_work"
"common_topic_home" "common_topic_senses" "common_topic_negative" "common_topic_fidget" "common_topic_state" "common_topic_training");

function isDirExists() {
    if ! [ -n "$1" ] || ! [ -d "$1" ];
        then
            echo "Directory '$1' not found!" 1>&2
	          exit 1
    fi
}

function setNumberSimilarity() {
    if [ -n "$1" ] && (( "$1" <= ${#similarity_array[@]}  )) &&  [ "$1" -ge "0" ]
    then
        number_similarity="$1"
    else
        echo "Arguments function 'setNumberSimilarity' not found!" 1>&2
	    exit 1
    fi
}

function setProgramm() {
    if [ "$1" -ge "4" ];then
      echo "Program numbers must be between 1 and 3"
      exit 1;
      fi

    if [ "$1" -le "0" ];then
       echo "Program numbers must be between 1 and 3"
       exit 1;
    fi

    number_programm="$1"

}

function setSettings(){
    index=`expr index "$1" =`;

    if [ "$index" -lt 2 ]
     then echo "WTF" exit 1
    fi

    key=${1:0:$index-1}
    value=${1:$index}

    if [ "$key" = "ns" ]
    then
      setNumberSimilarity "$value"
    elif [ "$key" = "programm" ]  
    then
      setProgramm "$value"
    else
      echo "Key not found. The key must be one of these:'ns','programm'" 1>&2
	  exit 0
    fi
}


 

function isCorrectTranslation(){

   if [ "$2" ] && echo "$1" | grep -iqw "$2";
   then
     return 0;
   else
     echo -n -e "\e[31mCorrect result should have: \e[0m"
     echo -n -e "\e[31;4m${1}\e[0m\n"
   fi
}

function isThereOneVerb() {

   if [ "$2" ] && echo "$1" | grep -iqw "$2";
   then
     return 0;
   elif [ "$3" ] &&  echo "$1" | grep -iqw "$3";
   then
     return 0;
   else
     echo -n -e "\e[31mCorrect result should have: \e[0m"
     echo -n -e "\e[31;4m${4}\e[0m\n"
   fi
}

function correctShow() {

    local indexSepExt=`expr index "$1" ,`;

      if [ "$indexSepExt" -eq "0" ];then
         isCorrectTranslation "$1" "$2"
      else
         isThereOneVerb "$2" "${1:0:$indexSepExt-1}" "${1:$indexSepExt}"  "$1"
      fi
}

function soundCorrect() {
    if  [ -z "$1" ] ||  [ -z "$2" ]
   then
     echo "soundCorrect:missing arguments !"
     exit 1
   fi

    local verbs_sound="$1"
    local source_sound="$2"
    local indexSepExt=`expr index "$verbs_sound" ,`;

     if [ "$indexSepExt" -eq "0" ];then
         $(mplayer -really-quiet "$source_sound/$verbs_sound.$fileExtension" 2> ./log/mplayer_errors.log);
       else
         $(mplayer -really-quiet "$source_sound/${verbs_sound:0:$indexSepExt-1}.$fileExtension" 2> ./log/mplayer_errors.log);
         sleep 500ms
         $(mplayer -really-quiet "$help_dir/or.mp3" 2> ./log/mplayer_errors.log);
          sleep 500ms
         $(mplayer -really-quiet "$source_sound/${verbs_sound:$indexSepExt}.$fileExtension" 2> ./log/mplayer_errors.log);
      fi
}

isUniqueIndex=false
function isExistsValue() {
   isUniqueIndex=false
   local array_temp=($2)

  for id_temp in "${array_temp[@]}";
  do
    if [ "$id_temp" -eq "$1" ]
     then
      isUniqueIndex=false
      return 1;
     fi
  done
  isUniqueIndex=true
 }

function programm_three(){

    IFS=',';
    read -r -a ids <<< $(sqlite3 $DB_FILE "select group_concat(id,\",\") from irregular_verbs
    where similarity='"${similarity_array[number_similarity]}"' ");
    unset IFS;

    local unique_ids=()
    while [ "${#unique_ids[@]}" -lt "${#ids[@]}"  ]
    do
      index="$(( ( RANDOM % ${#ids[@]} )))"
      isExistsValue "${ids[$index]}" "${unique_ids[*]}"
      if  [ $isUniqueIndex = true ];then
         unique_ids+=("${ids[$index]}")
      fi
    done

   if  [ -z "$ids" ]
   then
     echo "WTF id's irregular_verbs aren't exists"
     exit 1
   fi

   echo -e "\e[30;47mFind the irregular verb from the text:\e[0m"

   IFS='|';
   for id in "${unique_ids[@]}";
   do
      read -r -a row  <<< $(sqlite3 $DB_FILE "select infinitive,past_simple,past_participle,translate,sentence_infinitive,
      sentence_past_simple,sentence_past_participle,similarity from irregular_verbs where id='"${id}"';");

      local infinitive="${row[0]}"
      local past_simple="${row[1]}"
      local past_participle="${row[2]}"
      local translate="${row[3]}"
      local sentence_infinitive="${row[4]}"
      local sentence_past_simple="${row[5]}"
      local sentence_past_participle="${row[6]}"
      local similarity="${row[7]}"

      local true_result=""
      local true_source=""
      local number_form="$(( ( RANDOM % 3 )))"

          case $number_programm in
       0)
           true_result="$infinitive"
           true_source="$source_infinitive"
           echo "$sentence_infinitive"
           echo -n ": "
           read  -r input_verb
            ;;
       1)
           true_result="$past_simple"
           true_source="$source_past_simple"
           echo "$sentence_past_simple"
           echo -n ": "
           read  -r input_verb
            ;;
       2)
          true_result="$past_participle"
          true_source="$source_past_participle"
          echo "$sentence_past_participle"
          echo -n ": "
          read  -r input_verb
            ;;
       *)
          true_result="$infinitive"
          true_source="$source_infinitive"
          echo "$sentence_infinitive"
          echo -n ": "
          read  -r input_verb
            ;;
      esac
      correctShow "$true_result" "$input_verb"
      soundCorrect "$true_result" "$true_source"
    done
    unset IFS;
}

# make a sentence based on an irregular verb from a translation using a noun.
function programm_two(){
    IFS=',';
    read -r -a ids <<< $(sqlite3 $DB_FILE "select group_concat(id) from irregular_verbs
    where similarity='"${similarity_array[number_similarity]}"';");
    unset IFS;

   if  [ -z "$ids" ]
   then
     echo "WTF id's irregular_verbs aren't exists"
     exit 1
   fi

   local unique_ids=()
    while [ "${#unique_ids[@]}" -lt "${#ids[@]}"  ]
    do
      index="$(( ( RANDOM % ${#ids[@]} )))"
      isExistsValue "${ids[$index]}" "${unique_ids[*]}"
      if  [ $isUniqueIndex = true ];then
         unique_ids+=("${ids[$index]}")
      fi
    done

   IFS='|';
   for id in "${unique_ids[@]}";
   do
      read -r -a row  <<< $(sqlite3 $DB_FILE "select infinitive,past_simple,past_participle,translate,sentence_infinitive,
      sentence_past_simple,sentence_past_participle,similarity from irregular_verbs where id='"${id}"';");

      read -r -a row_nouns <<< $(sqlite3 $DB_FILE "select word from nouns where id = (abs(random()) % (select (select max(id) from nouns)+1)) or id = (select max(id) from nouns) order by id limit 1;");

      local infinitive="${row[0]}"
      local past_simple="${row[1]}"
      local past_participle="${row[2]}"
      local translate="${row[3]}"

       echo -e "\e[30;47mEnter an example using the word \e[0m\e[1;4;35;47m\"${translate}\"\e[0m\e[30;47m in the form\e[0m\e[1;30;47m \"Past Simple\" \e[0m\e[30;47mand use \e[0m\e[1;4;35;47m\"$row_nouns\":\e[0m"
       read  -r input_sentence_past_simple

       correctShow "$past_simple" "$input_sentence_past_simple"
       soundCorrect "$past_simple" "$source_past_simple"
    done
    unset IFS;
}


# translation and input of three forms.
function programm_one(){
    IFS=',';
    read -r -a ids <<< $(sqlite3 $DB_FILE "select group_concat(id) from irregular_verbs
    where similarity='"${similarity_array[number_similarity]}"';");
    unset IFS;

   if  [ -z "$ids" ]
   then
     echo "WTF id's irregular_verbs aren't exists"
     exit 1
   fi

    local unique_ids=()
    while [ "${#unique_ids[@]}" -lt "${#ids[@]}"  ]
    do
      index="$(( ( RANDOM % ${#ids[@]} )))"
      isExistsValue "${ids[$index]}" "${unique_ids[*]}"
      if  [ $isUniqueIndex = true ];then
         unique_ids+=("${ids[$index]}")
      fi
    done


   IFS='|';
   for id in "${unique_ids[@]}";
   do
      read -r -a row  <<< $(sqlite3 $DB_FILE "select infinitive,past_simple,past_participle,translate,sentence_infinitive,
      sentence_past_simple,sentence_past_participle,similarity from irregular_verbs where id='"${id}"';");

      local infinitive="${row[0]}"
      local past_simple="${row[1]}"
      local past_participle="${row[2]}"
      local translate="${row[3]}"

       echo -e "\e[30;47mEnter the word \e[0m\e[1;4;35;47m\"${translate}\"\e[0m"

       # infinitive
       echo -n -e "- in the form \e[1;4;35mInfinitive\e[0m --------: "
       read  -r input_infinitive
       isCorrectTranslation "$infinitive" "$input_infinitive"
       soundCorrect "$infinitive"  "$source_infinitive"

       # past_simple
       echo -n  -e "- in the form \e[1;4;35mPast Simple\e[0m -------: "
       read  -r input_past_simple
       isCorrectTranslation "$past_simple" "$input_past_simple"
       soundCorrect "$past_simple"  "$source_past_simple"

       # past_participle
       echo -n -e "- in the form \e[1;4;35mPast Participle\e[0m ---: "
       read  -r input_past_participle
       isCorrectTranslation "$past_participle" "$input_past_participle"
       soundCorrect "$past_participle"  "$source_past_participle"
    done
    unset IFS;
}



#############################################
# start
#############################################
isDirExists "$source"
isDirExists "$source_infinitive"
isDirExists "$source_past_simple"
isDirExists "$source_past_participle"
isDirExists "$help_dir"

if [ $# -ge 0 ]
then
  # there are arguments
  # checking all keys
    for key_setting in "$@";
    do
         setSettings "$key_setting"
    done

fi

# start word play

    case $number_programm in
       1)
           programm_one
            ;;
       2)
           programm_two
            ;;
       3)
          programm_three
            ;;
       *)
          programm_one
            ;;
  esac




