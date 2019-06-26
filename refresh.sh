#!/bin/bash
# This script will copy ferret scripts, velocity templates, html, and javascript to tomcat
# so you don't have to redeploy. Change the following 2 paramters to reflect your installation. By default, it assumes the current directory name matches teh webapp name, and tomcat exists at ../tomcat

LAS_NAME=$(pwd | rev | awk -F \/ '{print $1}' | rev)
echo LAS_NAME is
echo $LAS_NAME
#CATALINA_HOME=../tomcat
echo CATALINA_HOME is
echo $CATALINA_HOME
cp -Ruv WebContent/* $CATALINA_HOME/webapps/$LAS_NAME/
cp -Ruv JavaSource/resources/* $CATALINA_HOME/webapps/$LAS_NAME/WEB-INF/classes/resources/
