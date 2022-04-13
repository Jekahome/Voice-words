# voice acting of words
Plays sound files using [mplayerhq](http://www.mplayerhq.hu/design7/news.html).

Can randomize the list, limit the number of playable files, change the delay in playback time between files.

Can do recursive traversal of folders (default "words") by selecting files with the extension installed (extension default "mp3").

Can check the translation of the original or the source word, asking for user data.

Important, file name is a reproducible word.

### Example:

    ./words.sh d="The path to your folder with the words"
    
    ./words.sh random=true limit=50 timeout=3 recursion=true extensions=mp3
    
    ./words.sh r=true l=50 t=3 R=true e=mp3
    
    ./words.sh limit=2 timeout=2 dir="words/GroupWords" recursion=false random=true
    
    ./words.sh d="words" r=true
    
    ./words.sh r=true l=5 t=3

### Example is used often:

    ./words.sh  d="words/<SUB_FOLDER>" rct=true
    
    ./words.sh  d="words" R=true rct=true


### Default value:

    - source="Words"  -  folder mp3 files "Words"
    
    - limit  - the number of all files in the folder depending on the recursion flag
    
    - timeout=1 - timeout beetwen sound word, s-seconds, m-minute
    
    - isRandom=true - random list is enabled by default
    
    - fileExtension="mp3" - default extension "mp3"
    
    - isRecursion=false - default recursion disabled
    
    - isCheckTranslation=true - enter translation
    
    - isReverseCheckTranslation=false - enter original translation
    
    - isRandomTranslation=false - enter a translation of the original or source word or do not type anything randomly

### Log error
./sound_words_mplayer_errors.log
