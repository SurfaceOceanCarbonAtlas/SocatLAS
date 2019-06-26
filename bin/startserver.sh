#!/bin/sh
JAVA_HOME="/usr/local/jdk1.5.0_01"
JAVA_OPTS="-Djava.awt.headless=true"
CATALINA_PID="/usr/local/www/html/TOMCAT_DEMO/tomcat/webapps/UI_PID"
CLASSPATH=
export JAVA_HOME JAVA_OPTS CLASSPATH CATALINA_PID
echo "This will start your tomcat container 
running at /usr/local/www/html/TOMCAT_DEMO/tomcat
Do you want to continue? [no]" 
read ANS
if [ "${ANS}" = "y"  ]; then
   rm -rf /usr/local/www/html/TOMCAT_DEMO/tomcat/work/Catalina/localhost/las
   exec /usr/local/www/html/TOMCAT_DEMO/tomcat/bin/catalina.sh start
elif [ "${ANS}" = "yes" ]; then
   rm -rf /usr/local/www/html/TOMCAT_DEMO/tomcat/work/Catalina/localhost/las
   exec /usr/local/www/html/TOMCAT_DEMO/tomcat/bin/catalina.sh start
else
   echo "Tomcat container at /usr/local/www/html/TOMCAT_DEMO/tomcat was not started!  Use the
manager interface or an existing script to add the LAS servlet
to this tomcat container."
fi
