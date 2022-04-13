#!/bin/bash

sqlite3=$('which' sqlite3)
DB_FILE="db/words.db"

topic_id=1
correctTranslation=true
ids=()
idsRepeat=()
repeat=false

function setTopic() {
     local topics_count=0

     read -r -a  topics_count  <<< $(sqlite3 $DB_FILE "select count(id) from topics;");

    if [ "$1" -ge "$topics_count" ];then
      echo "Program numbers must be between 1 and $topics_count"
      exit 1;
    fi

    if [ "$1" -le "0" ];then
       echo "Program numbers must be between 1 and $topics_count"
       exit 1;
    fi

    topic_id="$1"
}

function showTopics() {

      local topics_list
      IFS=',';
      read -r -a topics_list <<< $(sqlite3 $DB_FILE "select group_concat(' id=' || id || ' topic=' || topic || '. ' || translate ) from topics ;");
      unset IFS;

      for item_topic in "${topics_list[@]}";
      do
        echo "${item_topic}"
      done
}

function setSettings(){
    index=`expr index "$1" =`;

    key=${1:0:$index-1}
    value=${1:$index}

    if [ "$key" = "topic" ]
    then
      setTopic "$value"
    elif [ "$key" = "show_topics" ]; then
          showTopics
          exit 1;
    else
      echo "Key not found." 1>&2
      echo "./sentences.sh show_topics=true"
      echo "./sentences.sh topic=1"

	  exit 0
    fi
}

function isCorrectTranslation(){

   if [ "$2" ] && echo "$1" | grep -iqw "$2";
   then
     correctTranslation=true
     return 0;
   else
     correctTranslation=false
     echo -n -e "\e[31mCorrect result should have: \e[0m"
     echo -n -e "\e[31;4m${1}\e[0m\n"
   fi
}

function isThereOneVerb() {

   if [ "$2" ] && echo "$1" | grep -iqw "$2";
   then
     correctTranslation=true
     return 0;
   elif [ "$3" ] &&  echo "$1" | grep -iqw "$3";
   then
     correctTranslation=true
     return 0;
   else
     correctTranslation=false
     echo -n -e "\e[31mCorrect result should have: \e[0m"
     echo -n -e "\e[31;4m${4}\e[0m\n"
   fi
}

function correctShow() {

    local indexSepExt=`expr index "$1" .`;

      if [ "$indexSepExt" -eq "0" ];then
         isCorrectTranslation "$1" "$2"
      else
         isThereOneVerb "$2" "${1:0:$indexSepExt-1}" "${1:$indexSepExt}"  "$1"
      fi
}



function loadIdsSentences() {

      if [ $repeat = true ]; then
          ids=${idsRepeat[*]}
          echo  -e "\e[30;47mRepeating erroneous answers!\e[0m"
      else
          IFS=',';
          read -r -a ids <<< $(sqlite3 $DB_FILE "select group_concat(id) from sentences
          where topic_id=${topic_id};");
          unset IFS;
      fi
}

function programm() {
    loadIdsSentences
    repeat=false

   if  [ -z "$ids" ]
   then
     echo "WTF id's sentences aren't exists"
     exit 1
   fi

   local topic_info=()
   local topic_name
   local topic_translate

   IFS="|"
    read -r -a topic_info  <<< $(sqlite3 $DB_FILE "select topic,translate from topics where id='${topic_id}';");
   unset IFS;
   topic_name="${topic_info[0]}"
   topic_translate="${topic_info[1]}"

    echo -e "\e[30;47mTopic: ${topic_name} (${topic_translate})\e[0m"

   for sentences_id in "${ids[@]}";
    do
         IFS="|"
         read -r -a row  <<< $(sqlite3 $DB_FILE "select sentence,translate from sentences where id='${sentences_id}';");
         unset IFS;
         local sentence="${row[0]}"
         local sentence_translate="${row[1]}"

         #echo  "  Translate ${sentence_translate}: "
         echo -e "   \e[30;47m Enter translate\e[0m\e[1;4;35;47m ${sentence_translate}\e[0m"
         read  -r input_sentence
         correctShow "${sentence}" "${input_sentence}"

         # повтор не верных результатов
         if [ $correctTranslation = false ]; then
          repeat=true
          idsRepeat+=($sentences_id)
         fi
    done

      if [ $repeat = true ]; then
         programm
      fi

}



#############################################
# start
#############################################
if [ $# -ge 0 ]
then
    # there are arguments
    # checking all keys
    for key_setting in "$@";
    do
         setSettings "$key_setting"
    done

fi


programm