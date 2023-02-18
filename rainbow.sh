#/bin/bash

GET_WRAP_RGB(){
  local RED=${1:-0};local GREEN=${2:-0};local BLUE=${3:-0}
  if [[   "$RED" -gt "255" ]];then   RED=255;elif [[   "$RED" -lt "0" ]];then RED=0; fi
  if [[ "$GREEN" -gt "255" ]];then GREEN=255;elif [[ "$GREEN" -lt "0" ]];then GREEN=0; fi
  if [[  "$BLUE" -gt "255" ]];then  BLUE=255;elif [[  "$BLUE" -lt "0" ]];then BLUE=0; fi
  echo "${RED};${GREEN};${BLUE}"
}

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

GOTO_XY(){
  local SCREEN_X=${1:-"1"}
  local SCREEN_Y=${2:-"1"}
  echo -e "\e[${SCREEN_Y};${SCREEN_X}H";
}

clear
STEP=1
VAL=5
for itx in $(seq 0 25 255); do
  for ity in $(seq 0 25 255); do
    for itz in $(seq 0 25 255); do
	  GOTO_XY 30 $((VAL))
      echo -en "$(SET_FONT_RGB $(GET_WRAP_RGB $itx $ity $itz) 1)ABCDEFG_RGB $(GET_WRAP_RGB $itx $ity $itz)"
	  VAL=$((VAL+STEP))
    done
	STEP=$((STEP*-1));
  done
done
