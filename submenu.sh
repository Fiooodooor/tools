#/bin/bash

# https://web.archive.org/web/20180130222805/http://pro-toolz.net/data/programming/bash/Bash_fancy_menu.html

# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux/28938235#28938235

SCRIPT_PATH=${BASH_SOURCE:-$0}
SCRIPT_DIR=$(dirname $SCRIPT_PATH)

trap "R;exit" 2

E='echo -e';
e='echo -en';

GET_WRAP_RGB(){
  local RED=${1:-0};local GREEN=${2:-0};local BLUE=${3:-0}
  if [[   "$RED" -gt "255" ]];then   RED=255;elif [[   "$RED" -lt "0" ]];then RED=0; fi
  if [[ "$GREEN" -gt "255" ]];then GREEN=255;elif [[ "$GREEN" -lt "0" ]];then GREEN=0; fi
  if [[  "$BLUE" -gt "255" ]];then  BLUE=255;elif [[  "$BLUE" -lt "0" ]];then BLUE=0; fi
  echo "${RED};${GREEN};${BLUE}"
}
# ANSI Font color decorator
SET_FONT_ASCII(){
  local FT_COLOR=$1
  local DECORATOR=$2
  local BG_COLOR=$3
  if [[ "$#" -eq "1" ]];then echo "\e[3${FT_COLOR}m";
  elif [[ "$#" -eq "2" ]];then echo "\e[3${FT_COLOR};${DECORATOR}m";
  elif [[ "$#" -eq "3" ]];then echo "\e[3${FT_COLOR};4${BG_COLOR};${DECORATOR}m";
  else echo ""; fi
}
# RGB Font color decorator
SET_FONT_RGB(){
  local FT_COLOR=$1
  local DECORATOR=$2
  local BG_COLOR=$3
  if [[ "$#" -eq "4" ]];then FT_COLOR=`GET_WRAP_RGB $1 $2 $3`; DECORATOR=$4; fi
  if [[ "$#" -ge "6" ]];then FT_COLOR=`GET_WRAP_RGB $1 $2 $3`; BG_COLOR=`GET_WRAP_RGB $4 $5 $6`; fi

  if [[ "$#" -eq "1" ]];then echo "\e[38;2;${FT_COLOR}m"
  elif [[ "$#" -eq "2" ]] || [[ "$#" -eq "4" ]];then echo "\e[38;2;${FT_COLOR};${DECORATOR}m"
  elif [[ "$#" -eq "3" ]] || [[ "$#" -eq "7" ]];then echo "\e[38;2;${FT_COLOR};48;2;${BG_COLOR};${DECORATOR}m"
  else echo ""; fi
}

PRINT_NTIMES(){
	local N=${1:-80}
	local CHAR="${2:- }"
	for each in $(seq 1 $N) ; do echo -n "${CHAR}"; done
}
CHANGE_LIST(){
  TLIST=($@)
  MSIZE_X=25        # Menu size in rows
  MSIZE_Y=80        # Menu size in chars 
  TLINE="x$(PRINT_NTIMES $((MSIZE_Y-2)))x"
  HLINE=" BASH SELECTION MENU"
  FLINE=" ENTER - SELECT,NEXT"
  MRS=3             # Menu row start char number.
  MRE=3             # Menu row end char number right to left.
  MRL=$((${#TLINE}-MRS-MRE))
  MLS=3             # Menu list start row number.
  MLE=3             # Menu last row number from bottom up.
  MLL=$((MSIZE_X-MLS-MLE)) # Menu list length, nr. of menu/list lines to display.
  MP=1              # Menu Position, position in drawn menu.
  LP=1              # List Position, position in viewed list.
  LL=${#TLIST[@]}   # This List, currently viewed list.
  LS=1              # List Start, first list index to display.
  LE=$MLL           # List End, last list index to display.
}
GET_MIN() {
  echo "$(( "$1" > "$2" ? "$2" : "$1" ))"
}
CHANGE_POSITION(){
  local MIN=$(GET_MIN "$MLL" "$LL")
  if [[ "$cur" == "up"   ]];then ((MP--));((LP--));fi
  if [[ "$cur" == "dn"   ]];then ((MP++));((LP++));fi
  if [[ "$MP" -lt "1"    ]];then ((LS--));MP=1;fi
  if [[ "$MP" -gt "$MIN" ]];then ((LS++));MP="${MIN}";fi
  if [[ "$LP" -lt "1"    ]];then LP=1;LS=1;LE="${MIN}";fi
  if [[ "$LP" -gt "$LL"  ]];then LP="${LL}";LE="${LL}";LS=$((LE-MLL+1));fi
  if [[ "$LS" -lt "1"    ]];then LS=1;fi
}
DRAW_SAFE(){
  GOTO_XY "${2}" "${1}"
  local TEXT="${3:0:$((MRL-put_x))}"
  local ECHO_VER="${4:-$e}"
  $ECHO_VER "${TEXT}${TLINE:$MRS:$((MRL-${#TEXT}))}"
}
DRAW_LIST(){
  UNMARK
  for each in $(seq 0 $MLL);do
    DRAW_SAFE "$((MLS+each))" "$MRS" "${TLIST[$((LS+each-1))]}"
  done
  MARK
  GOTO_XY "$MRS" $((MLS+MP-1)); $e "${TLIST[$((LP-1))]}";
}
INPUT(){
  ESC=$(echo -en "\033") 
  read -s -n3 key 2>/dev/null >&2          # read quietly three characters of served input
  if [ "$key" = "$ESC[A" ];then echo up; # if A is the result, print up
  elif [ "$key" = "$ESC[B" ];then echo dn; #    B                      dn
  elif [ "$key" = "$ESC[C" ];then echo ri; #    C                      ri
  elif [ "$key" = "$ESC[D" ];then echo le; #    D                      le
  elif [ "$key" = "" ];then echo '';
  else echo dn; fi
}
GOTO_XY(){
  local SCREEN_X=${1:-"1"}
  local SCREEN_Y=${2:-"1"}
  $e "\e[${SCREEN_Y};${SCREEN_X}H";
}
CLEAR_SCREEN(){ 
  $e "\ec"
}
HIDE_CURSOR(){ 
  $e "\e[?25l"
}
SHOW_CURSOR(){ 
  $e "\e[?12l\e[?25h"
}
# switch to 'garbage' mode to be able to draw
SET_DRAW_MODE(){
  $e "\e%@\e(0"
}
# return to normal (reset)     
SET_WRITE_MODE(){
  $e "\e(B" 
}
# draw text as selected (reverse colors)
MARK(){
  $e "\e[7m"
}
# return to normal text color (undo reverse colors)
UNMARK(){ 
  $e "\e[27m"
}  
DRAW_BODY(){ 
  SET_DRAW_MODE
  for each in $(seq 1 $MSIZE_X);do
    $E "$TLINE"
  done
  SET_WRITE_MODE;
}
DRAW_HEADER(){
  MARK
  GOTO_XY 2 1
  $E "${HLINE}$(PRINT_NTIMES $((MSIZE_Y-2-${#HLINE})))"
  UNMARK
}
DRAW_FOOTER(){ 
  MARK
  GOTO_XY 2 $MSIZE_X
  printf "${FLINE}$(PRINT_NTIMES $((MSIZE_Y-2-${#FLINE})))"
  UNMARK
}
INIT(){
  local THIS_LIST=()
  if [[ $# == 1 ]]; then local THIS_LIST=($(eval "echo \${"${1}"[@]}"));
  else local THIS_LIST=($@); fi
  HIDE_CURSOR
  CHANGE_LIST "${THIS_LIST[@]}"
  CLR_SET_COLOR
  DRAW_BODY
  DRAW_HEADER
  DRAW_FOOTER
  DRAW_LIST
}
CLR_SET_COLOR(){ 
  CLEAR_SCREEN
  stty
  sane
  $e "\ec$(SET_FONT_RGB 60 120 255 1)\e[J"
}
MENU(){ for each in $(seq 1 $ML);do M${each};done;}
SC(){ DRAW_LIST;MARK;cur=`INPUT`;}
ES(){ MARK;$e "ENTER = main menu ";read;INIT MAIN_MENU;}

MAIN_MENU=("MENU_ENTRY_1 MENU_ENTRY_2 MENU_ENTRY_3 MENU_ENTRY_4 MENU_ENTRY_5 MENU_ENTRY_6 MENU_ENTRY_7 MENU_ENTRY_8")
INIT MAIN_MENU
while [[ "$O" != " " ]];do
case $MP in
    1) S=M1;SC;if [[ $cur == "" ]];then R;$e "\n$(ifconfig )\n";ES;fi;;
    2) S=M2;SC;if [[ $cur == "" ]];then R;$e "\n$(df -h    )\n";ES;fi;;
    3) S=M3;SC;if [[ $cur == "" ]];then R;$e "\n$(route -n )\n";ES;fi;;
    4) S=M4;SC;if [[ $cur == "" ]];then R;$e "\n$(date     )\n";ES;fi;;
    5) S=M5;SC;if [[ $cur == "" ]];then R;$e "\n$($e by oTo)\n";ES;fi;;
    6) S=M6;SC;if [[ $cur == "" ]];then R;$e "\n$(w        )\n";ES;fi;;
    7) S=M7;SC;if [[ $cur == "" ]];then R;exit 0;fi;;
    *) SC;;
esac;
CHANGE_POSITION
done



#
# https://stackoverflow.com/a/28938235/12289068
#
# +------------+----------+---------+-------+------------------+------------------------------+--------------------------------------+
# | color-mode | octal    | hex     | bash  | description      | example (= in octal)         | NOTE                                 |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# |          0 | \033[0m  | \x1b[0m | \e[0m | reset any affect | echo -e "\033[0m"            | 0m equals to m                       |
# |          1 | \033[1m  |         |       | light (= bright) | echo -e "\033[1m####\033[m"  | -                                    |
# |          2 | \033[2m  |         |       | dark (= fade)    | echo -e "\033[2m####\033[m"  | -                                    |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# |  text-mode | ~        |         |       | ~                | ~                            | ~                                    |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# |          3 | \033[3m  |         |       | italic           | echo -e "\033[3m####\033[m"  |                                      |
# |          4 | \033[4m  |         |       | underline        | echo -e "\033[4m####\033[m"  |                                      |
# |          5 | \033[5m  |         |       | blink (slow)     | echo -e "\033[3m####\033[m"  |                                      |
# |          6 | \033[6m  |         |       | blink (fast)     | ?                            | not wildly support                   |
# |          7 | \003[7m  |         |       | reverse          | echo -e "\033[7m####\033[m"  | it affects the background/foreground |
# |          8 | \033[8m  |         |       | hide             | echo -e "\033[8m####\033[m"  | it affects the background/foreground |
# |          9 | \033[9m  |         |       | cross            | echo -e "\033[9m####\033[m"  |                                      |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# | foreground | ~        |         |       | ~                | ~                            | ~                                    |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# |         30 | \033[30m |         |       | black            | echo -e "\033[30m####\033[m" |                                      |
# |         31 | \033[31m |         |       | red              | echo -e "\033[31m####\033[m" |                                      |
# |         32 | \033[32m |         |       | green            | echo -e "\033[32m####\033[m" |                                      |
# |         33 | \033[33m |         |       | yellow           | echo -e "\033[33m####\033[m" |                                      |
# |         34 | \033[34m |         |       | blue             | echo -e "\033[34m####\033[m" |                                      |
# |         35 | \033[35m |         |       | purple           | echo -e "\033[35m####\033[m" | real name: magenta = reddish-purple  |
# |         36 | \033[36m |         |       | cyan             | echo -e "\033[36m####\033[m" |                                      |
# |         37 | \033[37m |         |       | white            | echo -e "\033[37m####\033[m" |                                      |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# |         38 | 8/24     |                    This is for special use of 8-bit or 24-bit                                            |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# | background | ~        |         |       | ~                | ~                            | ~                                    |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# |         40 | \033[40m |         |       | black            | echo -e "\033[40m####\033[m" |                                      |
# |         41 | \033[41m |         |       | red              | echo -e "\033[41m####\033[m" |                                      |
# |         42 | \033[42m |         |       | green            | echo -e "\033[42m####\033[m" |                                      |
# |         43 | \033[43m |         |       | yellow           | echo -e "\033[43m####\033[m" |                                      |
# |         44 | \033[44m |         |       | blue             | echo -e "\033[44m####\033[m" |                                      |
# |         45 | \033[45m |         |       | purple           | echo -e "\033[45m####\033[m" | real name: magenta = reddish-purple  |
# |         46 | \033[46m |         |       | cyan             | echo -e "\033[46m####\033[m" |                                      |
# |         47 | \033[47m |         |       | white            | echo -e "\033[47m####\033[m" |                                      |
# |------------+----------+---------+-------+------------------+------------------------------+--------------------------------------|
# |         48 | 8/24     |                    This is for special use of 8-bit or 24-bit                                            |
# +------------+----------+---------+-------+------------------+------------------------------+--------------------------------------+