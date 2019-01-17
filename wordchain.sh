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
