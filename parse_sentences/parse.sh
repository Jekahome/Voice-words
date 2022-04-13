#!/bin/bash

# Источник google таблицы
# Файл с данными должен быть .tsv и иметь пустую завешающую строку.


sqlite3=$('which' sqlite3)
DB_FILE="../db/words.db"


function createTables(){
$sqlite3 $DB_FILE  "
        create table IF NOT EXISTS sentences (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                topic_id INTEGER NOT NULL,
                sentence TEXT DEFAULT '""',
                translate TEXT DEFAULT '""',
                FOREIGN KEY(topic_id) REFERENCES topics(id)
                );"

   $sqlite3 $DB_FILE  "
          create table IF NOT EXISTS topics (
                  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                  topic TEXT UNIQUE NOT NULL,
                  translate TEXT DEFAULT '""');"

}

function dropTables(){
   $(sqlite3 $DB_FILE "drop table if exists sentences");
   $(sqlite3 $DB_FILE "drop table if exists topics");
}

function deleteTopicsTables(){
 $(sqlite3 $DB_FILE "delete from topics");
}

function deleteSentencesTables(){
 $(sqlite3 $DB_FILE "delete from sentences");
}

function dump(){
 $(sqlite3 words.db .dump > "dump_words_$(date +"%m-%d-%Y").sql")
# cat dump_words.sql | sqlite3 words.db
}

function parseAll() {
    echo "deleteTopicsTables"
    deleteTopicsTables

    echo "load topics"
    while IFS="	" read -r id topic translate
    do
       $sqlite3 $DB_FILE " insert into topics (id,topic,translate) values  (\"${id}\",\"${topic}\", \"${translate}\");"
    done < "topics.tsv"
    unset IFS;

    echo "deleteSentencesTables"
    deleteSentencesTables

    echo "load sentences"
     while IFS="	" read -r id topic_id sentence translate
    do
      #echo "${sentence}"
       $sqlite3 $DB_FILE " insert into sentences (id,topic_id,sentence,translate) values  (\"${id}\", ${topic_id}, \"${sentence}\", \"${translate}\");"
    done < "sentences.tsv"
    unset IFS;

}

echo "Parsing..."
createTables
parseAll