#!/bin/bash

# For loading irregular verbs and frequency nouns.


# rename files
# find "." -name "*.mp3" -exec rename 's/-us//' {} \;



sqlite3=$('which' sqlite3)
DB_FILE="../db/words.db"

# common_topic_training, - обучение
# common_topic_state, - состояние
# common_topic_fidget, - непоседа
# common_topic_negative, - негатив
# common_topic_senses, - чувства
# common_topic_home, - домашние дела
# common_topic_work, - работа
# const_n_in_3, -  с -N в конце в третьей колонке
# const_ew_in_2_own_in_3, - на -EW во второй колонке и на -OWN в третьей
# const_o_in_2, - с -О- только в Past
# const_o_in_2_3, - с -О- в Past и Past Participle
# const_2_3, - идентичные в Present и Past Patriciple
# const - которые не видоизменяются


function createTables(){
  $sqlite3 $DB_FILE  "
          create table IF NOT EXISTS irregular_verbs (
                  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                  infinitive TEXT UNIQUE NOT NULL,
                  past_simple TEXT DEFAULT '""',
                  past_participle TEXT DEFAULT '""',
                  translate TEXT DEFAULT '""',
                  sentence_infinitive TEXT DEFAULT '""',
                  sentence_past_simple TEXT DEFAULT '""',
                  sentence_past_participle TEXT DEFAULT '""',
                  similarity TEXT  DEFAULT '""');"

  $sqlite3 $DB_FILE  "
          create table IF NOT EXISTS nouns (
                  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                  word TEXT UNIQUE NOT NULL,
                  translate TEXT DEFAULT '""');"
}

function dump(){
 $(sqlite3 words.db .dump > "dump_words_$(date +"%m-%d-%Y").sql")
# cat dump_words.sql | sqlite3 words.db
}

function dropTables(){
   $(sqlite3 $DB_FILE "drop table if exists irregular_verbs");
   $(sqlite3 $DB_FILE "drop table if exists nouns");
}

function deleteTables(){
 $(sqlite3 $DB_FILE "delete from irregular_verbs");
 $(sqlite3 $DB_FILE "delete from nouns");
}



function load_nouns(){
    while IFS="|" read -r translate word
    do
      $sqlite3 $DB_FILE " insert into nouns (word,translate) values  (\"${word}\", \"${translate}\");"
    done < "nouns.csv"
    unset IFS;
}

function load_irregular_verbs(){

  while IFS="|" read -r infinitive past_simple past_participle translate sentence_infinitive sentence_past_simple sentence_past_participle similarity
  do
     $sqlite3 $DB_FILE " insert into irregular_verbs (infinitive,past_simple,past_participle,translate,sentence_infinitive,
     sentence_past_simple,sentence_past_participle,similarity) values
     (\"${infinitive}\",\"${past_simple}\", \"${past_participle}\",
     \"${translate}\", \"${sentence_infinitive}\", \"${sentence_past_simple}\",
     \"${sentence_past_participle}\",\"${similarity}\");"
        # IFS=', ' read -r -a past_simple_array <<< "$past_simple"
        # IFS=', ' read -r -a past_participle_array <<< "$past_participle"
  done < "irregular_verbs_new.csv"
  unset IFS;
}

#############################################
# load
#############################################
#dropTables
createTables
#deleteTables
load_nouns
load_irregular_verbs





