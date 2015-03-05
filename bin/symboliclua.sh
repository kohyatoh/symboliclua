#!/bin/sh

if [ "$1" = "" ]; then
  echo "usage: $0 <filename>"
  exit 1
fi
FROM=$1
NAME=`basename $FROM`
BASE=`dirname $0`/..
JAR=$BASE/conv/target/symboliclua-conv-0.0.1-SNAPSHOT-jar-with-dependencies.jar


java -cp $JAR net.klazz.symboliclua.conv.Main < $FROM > $BASE/tmp/$NAME
cp $FROM $BASE/tmp/$NAME.bak
cd $BASE/src
lua run.lua ../tmp/$NAME ../tmp/$NAME.bak
