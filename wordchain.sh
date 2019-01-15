#!/bin/bash

function USER_TURN(){
if [ "$WORD" = "" ]
then
STATUS="# 입력된 값이 없습니다."
ENTER_AI
fi

if [ "$TURN" != "0" ]
then
START_WORD="$(echo ${WORD:0:1})"
AI_REV="$(echo "$AI" | rev)"
AI_WORD="$(echo ${AI_REV:0:1})"
if [ "$START_WORD" != "$AI_WORD" ]
then
STATUS="# $AI_WORD(으)로 시작해야 합니다."
ENTER_AI
fi
fi

if [ "$(grep -w "$WORD" word.dic)" != "" ]
then
STATUS="# 이미 사용한 단어입니다."
ENTER_AI
fi

if [ "$(echo ${WORD:1:1})" = "" ]
then
STATUS="# 두 글자 이상 사용 가능합니다."
ENTER_AI
fi

wget -q -O user.word "https://ko.dict.naver.com/search.nhn?kind=keyword&query="$WORD"&version=1"

grep "fnt15" user.word | sed "s/^.*<strong>//g" | sed "s/<sup>.*//g" | sed "s/<\/strong>//g" > check.word

if [ "$(grep -w "$WORD" check.word)" = "" ]
then
if [ "$ERROR_COUNT" = "2" ]
then
echo "
| 유저 패배 |" >> word.dic
STATUS="- AI 승리 -
! 유저가 패배 하였습니다.
! [!f]를 입력하여 종료하십시오."
WINNER="AI"
fi
STATUS="# 사전에 존재하지 않는 단어 이거나 명사가 아닙니다. (남은 기회: $((3-ERROR_COUNT)))"
ERROR_COUNT=$((ERROR_COUNT+1))
ENTER_AI
elif [ "$(grep "자모 검색결과" user.word)" != "" ]
then
STATUS="# 단어만 사용 가능합니다."
ENTER_AI
fi

ERROR_COUNT=0

TURN=$((TURN+1))

CHAIN_REV="$(echo "$WORD" | rev)"
CHAIN_WORD="$(echo ${CHAIN_REV:0:1})"

rm user.word

AI_TURN
}

function ONLINE_USER_TURN(){
if [ "$WORD" = "" ]
then
STATUS="# 입력된 값이 없습니다."
ERROR_CODE 1 1
ENTER_ONLINE_START_GAME
fi

if [ "$TURN_ONLINE" != "0" ]
then
START_WORD="$(echo ${WORD:0:1})"
AI_REV="$(echo "$AI" | rev)"
AI_WORD="$(echo ${AI_REV:0:1})"
if [ "$START_WORD" != "$WORD_CHAIN_ONLINE" ]
then
STATUS="# $WORD_CHAIN_ONLINE(으)로 시작해야 합니다."
ERROR_CODE 6 1
ENTER_ONLINE_START_GAME
fi
fi

if [ "$(grep -w "$WORD" word_online.dic)" != "" ]
then
STATUS="# 이미 사용한 단어입니다."
ERROR_CODE 2 1
ENTER_ONLINE_START_GAME
fi

if [ "$(echo ${WORD:1:1})" = "" ]
then
STATUS="# 두 글자 이상 사용 가능합니다."
ERROR_CODE 3 1
ENTER_ONLINE_START_GAME
fi

wget -q -O user.word "https://ko.dict.naver.com/search.nhn?kind=keyword&query="$WORD"&version=1"

grep "fnt15" user.word | sed "s/^.*<strong>//g" | sed "s/<sup>.*//g" | sed "s/<\/strong>//g" > check.word

if [ "$(grep -w "$WORD" check.word)" = "" ]
then
if [ "$ERROR_COUNT" = "2" ]
then
echo "
| 유저 패배 |" >> word.dic
STATUS="- AI 승리 -
! 유저가 패배 하였습니다.
! [!f]를 입력하여 종료하십시오."
WINNER="AI"
fi
STATUS="# 사전에 존재하지 않는 단어 이거나 명사가 아닙니다. (남은 기회: $((3-ERROR_COUNT)))"
ERROR_COUNT=$((ERROR_COUNT+1))
ERROR_CODE 4 1
ENTER_ONLINE_START_GAME
elif [ "$(grep "자모 검색결과" user.word)" != "" ]
then
STATUS="# 단어만 사용 가능합니다."
ERROR_CODE 5 1
ENTER_ONLINE_START_GAME
fi

ERROR_COUNT=0

TURN_ONLINE=$((TURN_ONLINE+1))

CHAIN_REV="$(echo "$WORD" | rev)"
CHAIN_WORD="$(echo ${CHAIN_REV:0:1})"

rm *.word
rm *.dic

echo "TURN_ONLINE=$TURN_ONLINE
WORD_ONLINE=$WORD
WORD_CHAIN_ONLINE=$CHAIN_WORD
" > word_online.dic

if [ "$TURN_WHO_ONLINE" = host ]
then
echo "TURN_WHO_ONLINE=user" >> word_online.dic
elif [ "$TURN_WHO_ONLINE" = user ]
then
echo "TURN_WHO_ONLINE=host" >> word_online.dic
fi

TF_SEND word_online.dic room/"$ROOM_NAME"/bg/word_online.dic del
ENTER_ONLINE_START_GAME
}

function AI_TURN(){
PAGE=1
PRV_WORD=$WORD
unset AI_TURN_END
while [ "$AI_TURN_END" != 1 ]
do
wget -q -O ai.word "https://ko.dict.naver.com/search.nhn?query="$CHAIN_WORD로시작하는단어"&kind=keyword&page=$PAGE&version=1"
if [ "$(grep "검색 결과가 없습니다" ai.word)" != "" ]
then
echo "
| AI 패배 |" >> word.dic
STATUS="- 유저 승리 -
! AI가 패배 하였습니다.
! [!f]를 입력하여 종료하십시오."
WINNER="USER"
break
fi
if [ "$(grep "검색결과를 제공하지 않습니다" ai.word)" != "" ]
then
echo "
| AI 패배 |" >> word.dic
STATUS="- 유저 승리 -
! AI가 패배 하였습니다.
! [!f]를 입력하여 종료하십시오."
WINNER="USER"
break
fi
AI_WORD="$(grep "fnt15" ai.word | sed "s/^.*<strong>//g" | sed "s/<sup>.*//g" | sed "s/<\/strong>//g")"
for AI in ${AI_WORD}
do
if [ "$(grep -w "$AI" word.dic)" = "" ]
then
echo "[$TURN] 제시한 단어: $WORD -> $AI" >> word.dic
AI_TURN_END=1
STATUS="$(cat word.dic | tail -1)"
break
fi
done
PAGE=$((PAGE+1))
done
}

function ENTER_AI(){
clear
echo "
===========================================================================
! 상태: $STATUS
==========================================================================="
unset STATUS
read -p "! 단어: " WORD
if [ "$WORD" = "!f" ]
then
echo "
! 총 $TURN턴을 진행하였습니다

- 목록
$(cat word.dic)
패배 단어: $PRV_WORD"
rm *.dic
rm *.word
exit 0
elif [ "$WORD" = "!m" ]
then
wget -q -O mean.word "https://ko.dict.naver.com/search.nhn?kind=keyword&query="$AI"&version=1"
if [ "$(grep "<p>\[명사] " mean.word | head -1 | tr -d "\t" | sed "s/<p>//" | sed "s/<\/p>//")" = "[명사] " ]
then
STATUS="'$AI'의 뜻
[명사] $(grep -w "<em>1.</em>" mean.word | head -1 | tr -d "\t" | cut -f 5 -d ">" | sed "s/<\/span//" | sed "s/\&lt\;/\</g" | sed "s/\&gt\;/\>/g" | sed "s/<strong>//g" | sed "s/<\/strong>//g")"
ENTER_AI
fi
STATUS="'$AI'의 뜻
$(grep "<p>\[명사] " mean.word | head -1 | tr -d "\t" | sed "s/<p>//" | sed "s/<\/p>//" | sed "s/\&lt\;/\</g" | sed "s/\&gt\;/\>/g" | sed "s/<strong>//g" | sed "s/<\/strong>//g")"
ENTER_AI
fi
if [ "$WINNER" = USER ]
then
STATUS="- 유저 승리 -
! AI가 패배 하였습니다.
! [!f]를 입력하여 종료하십시오."
ENTER_AI
elif [ "$WINNER" = AI ]
then
STATUS="- AI 승리 -
! 유저가 패배 하였습니다.
! [!f]를 입력하여 종료하십시오."
WINNER="AI"
ENTER_AI
fi
USER_TURN
ENTER_AI
}

function ENTER_ONLINE(){
clear
read -p "
===========================================================================
! 상태: $STATUS
===========================================================================
- 1. 호스트로 참가
- 2. 유저로 참가
- 3. 초대코드로 참가
===========================================================================
! 선택: " SEL_MENU

case "$SEL_MENU" in

1 )
read -p "
! 방 제목: " ROOM_NAME
read -p "
! 방 비밀번호 (공개방은 공백): " ROOM_PW
echo "! 방 만드는 중..."
INVITE_CODE=$RANDOM
TF_X room/ MKD "$ROOM_NAME"
TF_X room/"$ROOM_NAME"/ MKD bg
TF_X room/"$ROOM_NAME"/ MKD join
TF_X room/"$ROOM_NAME"/ MKD ready
TF_X invite_code/ MKD $INVITE_CODE
echo "$ROOM_PW" > PASSWORD
TF_SEND PASSWORD room/"$ROOM_NAME"/PASSWORD
TF_SEND PASSWORD invite_code/$INVITE_CODE/INVITE_PASSWORD del
echo "$ROOM_NAME" > INVITE_NAME
TF_SEND INVITE_NAME invite_code/$INVITE_CODE/INVITE_NAME del
echo "! 방 접속 중..."
NICK=host
echo "$NICK" > $NICK
TF_SEND $NICK room/"$ROOM_NAME"/join/$NICK del
echo "! 접속 완료"
sleep 1
echo "
===========================================================================
! 내 별명: $NICK
! 방 제목: $ROOM_NAME
! 방 비밀번호: $ROOM_PW
! 초대코드: $INVITE_CODE
===========================================================================
! 유저가 참여하면 자동으로 게임이 시작됩니다.
==========================================================================="
while [ "$(TF_LIST room/"$ROOM_NAME"/join/)" = "host" ]
do
sleep 0.5
done
echo "! 상대가 참여했습니다."
ENTER_ONLINE_START "$ROOM_NAME" host
;;

2 )
while true
do
clear
read -p "
===========================================================================
- 방 목록
$(TF_LIST room/)
===========================================================================
1. 방 참가
엔터. 새로고침
===========================================================================
! 선택: " SEL_JOIN
if [ "$SEL_JOIN" = "1" ]
then
read -p "! 방 제목: " ROOM_NAME
read -p "! 방 비밀번호: " ROOM_PW
echo "! 참가 중..."
if [ "$(TF_FILE room/"$ROOM_NAME"/PASSWORD)" = "$ROOM_PW" ]
then
NICK=user
echo "$NICK" > $NICK
TF_SEND $NICK room/"$ROOM_NAME"/join/$NICK del
break
fi
echo "# 비밀번호 불일치"
sleep 0.5
elif [ "$SEL_JOIN" = "2" ]
then
echo "! 새로 고치는 중..."
fi
done
ENTER_ONLINE_START "$ROOM_NAME" user
;;

3 )
echo
read -p "! 초대코드: " INVITE_CODE
echo "! 접속 중..."
if [ "$(TF_LIST invite_code/ | grep -w $INVITE_CODE)" = "" ]
then
STATUS="# 초대코드가 존재하지 않습니다."
ENTER_ONLINE
fi
ROOM_NAME="$(TF_FILE invite_code/$INVITE_CODE/INVITE_NAME)"
ROOM_PW="$(TF_FILE invite_code/$INVITE_CODE/INVITE_PASSWORD)"
TF_X invite_code/$INVITE_CODE/ DELE INVITE_NAME
TF_X invite_code/$INVITE_CODE/ DELE INVITE_PASSWORD
TF_X invite_code/ RMD $INVITE_CODE
echo "! 참가 중..."
if [ "$(TF_FILE room/"$ROOM_NAME"/PASSWORD)" != "$ROOM_PW" ]
then
STATUS="# 비밀번호 불일치"
fi
NICK=user
echo "$NICK" > $NICK
TF_SEND $NICK room/"$ROOM_NAME"/join/$NICK del
ENTER_ONLINE_START "$ROOM_NAME" user
;;

* )
STATUS="# 알수없는 요청입니다."
ENTER_ONLINE
;;

esac
}

function ENTER_ONLINE_START(){
clear
read -p "
! 게임을 시작합니다 [방 제목: $1]
! 내 닉네임: $NICK

- 끝말잇기 규칙
! 두 글자 이상인 명사만 입력 가능합니다.
! 두음 법칙은 적용되지 않습니다.
! 같은 단어는 사용이 금지됩니다.
! 국어사전에 존재하는 단어만 사용이 가능합니다.
! 호스트가 먼저 시작합니다.
! [!m]을 입력시 상대가 제시한 단어의 뜻이 출력됩니다.
! [!f]을 입력시 종료되고 경기내용이 출력됩니다.

! 준비 하시겠습니까? [엔터]: " READY

echo "ready" > ready_$2
TF_SEND ready_$2 room/"$1"/ready/ready_$2 del
READY_WAIT=0

echo "! 상대를 기다리는 중입니다."

while [ "$READY_WAIT" != 1 ]
do
if [ "$2" = host ]
then
if [ "$(TF_LIST room/"$1"/ready/ | grep -w "ready_user")" = "ready_user" ]
then
READY_WAIT=1
fi
elif [ "$2" = user ]
then
if [ "$(TF_LIST room/"$1"/ready/ | grep -w "ready_host")" = "ready_host" ]
then
READY_WAIT=1
fi
fi
done

echo "TURN_ONLINE=0
TURN_WHO_ONLINE=host
STATUS_PAR=0
ERROR_CODE_INFO=0" > word_online.dic
TF_SEND word_online.dic room/"$1"/bg/word_online.dic del

ENTER_ONLINE_START_GAME
}

function ENTER_ONLINE_START_GAME(){
clear

case $NICK in

host )
echo "
===========================================================================
! 유저가 완료하기를 기다리는 중 입니다.
==========================================================================="
while true
do
TF_FILE room/"$ROOM_NAME"/bg/word_online.dic > word_online.dic
source word_online.dic
if [ "$TURN_WHO_ONLINE" = host ]
then
break
fi
if [ "$ERROR_CODE_INFO" = "1" ]
then
ERROR_MESSAGE
fi
done
clear
echo "
===========================================================================
! 상태: $STATUS
! 제시한 단어: $WORD_ONLINE
==========================================================================="
unset STATUS
read -p "! 단어: " WORD
if [ "$WORD" = "!m" ]
then
wget -q -O mean.word "https://ko.dict.naver.com/search.nhn?kind=keyword&query="$WORD_ONLINE"&version=1"
if [ "$(grep "<p>\[명사] " mean.word | head -1 | tr -d "\t" | sed "s/<p>//" | sed "s/<\/p>//")" = "[명사] " ]
then
STATUS="'$WORD_ONLINE'의 뜻
[명사] $(grep -w "<em>1.</em>" mean.word | head -1 | tr -d "\t" | cut -f 5 -d ">" | sed "s/<\/span//" | sed "s/\&lt\;/\</g" | sed "s/\&gt\;/\>/g" | sed "s/<strong>//g" | sed "s/<\/strong>//g")"
ENTER_ONLINE_START_GAME
fi
STATUS="'$WORD_ONLINE'의 뜻
$(grep "<p>\[명사] " mean.word | head -1 | tr -d "\t" | sed "s/<p>//" | sed "s/<\/p>//" | sed "s/\&lt\;/\</g" | sed "s/\&gt\;/\>/g" | sed "s/<strong>//g" | sed "s/<\/strong>//g")"
ENTER_ONLINE_START_GAME
fi
ONLINE_USER_TURN
;;

user )
echo "
===========================================================================
! 호스트가 완료하기를 기다리는 중 입니다.
==========================================================================="
while true
do
TF_FILE room/"$ROOM_NAME"/bg/word_online.dic > word_online.dic
source word_online.dic
if [ "$TURN_WHO_ONLINE" = user ]
then
break
fi
if [ "$ERROR_CODE_INFO" = "1" ]
then
ERROR_MESSAGE
fi
done
clear
echo "
===========================================================================
! 상태: $STATUS
! 제시한 단어: $WORD_ONLINE
==========================================================================="
unset STATUS
read -p "! 단어: " WORD
if [ "$WORD" = "!m" ]
then
wget -q -O mean.word "https://ko.dict.naver.com/search.nhn?kind=keyword&query="$WORD_ONLINE"&version=1"
if [ "$(grep "<p>\[명사] " mean.word | head -1 | tr -d "\t" | sed "s/<p>//" | sed "s/<\/p>//")" = "[명사] " ]
then
STATUS="'$WORD_ONLINE'의 뜻
[명사] $(grep -w "<em>1.</em>" mean.word | head -1 | tr -d "\t" | cut -f 5 -d ">" | sed "s/<\/span//" | sed "s/\&lt\;/\</g" | sed "s/\&gt\;/\>/g" | sed "s/<strong>//g" | sed "s/<\/strong>//g")"
ENTER_ONLINE_START_GAME
fi
STATUS="'$WORD_ONLINE'의 뜻
$(grep "<p>\[명사] " mean.word | head -1 | tr -d "\t" | sed "s/<p>//" | sed "s/<\/p>//" | sed "s/\&lt\;/\</g" | sed "s/\&gt\;/\>/g" | sed "s/<strong>//g" | sed "s/<\/strong>//g")"
ENTER_ONLINE_START_GAME
fi
ONLINE_USER_TURN
;;

esac
}

function ERROR_CODE(){
echo "TURN_ONLINE=$TURN_ONLINE
WORD_ONLINE=$WORD_ONLINE
WORD_CHAIN_ONLINE=$WORD_CHAIN_ONLINE
TURN_WHO_ONLINE=$TURN_WHO_ONLINE
STATUS_PAR=$1
ERROR_CODE_INFO=$2" > word_online.dic

TF_SEND word_online.dic room/"$ROOM_NAME"/bg/word_online.dic del
}

function ERROR_MESSAGE(){
ERROR_CODE 0 0

if [ "$STATUS_PAR" = "0" ]
then
echo "! 상태: 플레이 중
==========================================================================="
elif [ "$STATUS_PAR" = "1" ]
then
echo "! 상태: 공백 입력
==========================================================================="
elif [ "$STATUS_PAR" = "2" ]
then
echo "! 상태: 단어 중복 사용
==========================================================================="
elif [ "$STATUS_PAR" = "3" ]
then
echo "! 상태: 한 글자 사용
==========================================================================="
elif [ "$STATUS_PAR" = "4" ]
then
echo "! 상태: 사전에 존재하지 않는 단어 사용
==========================================================================="
elif [ "$STATUS_PAR" = "5" ]
then
echo "! 상태: 단어 미사용
==========================================================================="
elif [ "$STATUS_PAR" = "6" ]
then
echo "! 상태: 시작 단어 오류
==========================================================================="
fi
}

function TF_FILE(){
curl -s -u mokky:mokky04120 ftp://mokky.dothome.co.kr/html/wordchain/$1
}

function TF_LIST(){
curl -s -l -u mokky:mokky04120 ftp://mokky.dothome.co.kr/html/wordchain/$1
}

function TF_SEND(){
curl -s -T $1 -u mokky:mokky04120 ftp://mokky.dothome.co.kr/html/wordchain/$2
if [ "$3" = del ]
then
rm $1
fi
}

function TF_X(){
curl -s -u mokky:mokky04120 ftp://mokky.dothome.co.kr/html/wordchain/$1 -X "$2 $3"
}

TURN=0

case $1 in

online )
STATUS="온라인 매치"
ENTER_ONLINE
;;

ai )
echo "" > word.dic
STATUS=" - 끝말잇기 규칙 -
! 두 글자 이상인 명사만 입력 가능합니다.
! 두음 법칙은 적용되지 않습니다.
! 같은 단어는 사용이 금지됩니다.
! 국어사전에 존재하는 단어만 사용이 가능합니다.
! 턴이 길어질수록 단어 길이가 길어집니다.
! 유저가 먼저 시작합니다.
! [!m]을 입력시 AI가 제시한 단어의 뜻이 출력됩니다.
! [!f]을 입력시 종료되고 경기내용이 출력됩니다."
ENTER_AI
;;

* )
echo "사용법: wordchain [-online / -ai]
	online: 온라인 경기
	ai: AI 경기"
;;

esac
