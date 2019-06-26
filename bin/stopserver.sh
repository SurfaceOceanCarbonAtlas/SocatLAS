#!/bin/sh
JAVA_HOME="/usr/local/jdk1.5.0_01"
CLASSPATH=
export JAVA_HOME CLASSPATH
echo "This will stop your tomcat container 
running at /usr/local/www/html/TOMCAT_DEMO/tomcat.  
It will kill all of the servlets running under that Tomcat container.
Do you want to continue? [no]" 
read ANS
if [ "${ANS}" = "y"  ]; then
   exec /usr/local/www/html/TOMCAT_DEMO/tomcat/bin/catalina.sh stop
elif [ "${ANS}" = "yes" ]; then
   exec /usr/local/www/html/TOMCAT_DEMO/tomcat/bin/catalina.sh stop
else
   echo "Tomcat container running at /usr/local/www/html/TOMCAT_DEMO/tomcat  
was not stopped!  Use the manager interface or an existing script to stop
this tomcat container."
fi
