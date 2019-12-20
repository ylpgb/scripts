# Setup environment

# points to the installation directory
_SOLGENEOS_HOME="/usr/sw/solgeneos"

# points to the configuration directory
CONFIG_DIR=$_SOLGENEOS_HOME/config

# points to JVM installation
_JAVA_HOME=/usr/sw/java

# defined classpath and main class
MAIN_CLASS=com.solacesystems.solgeneos.solgeneosagent.util.SolGeneosCmdLineCipherTool

# java options
SOLACE_OPTS="-Xms128m -Xmx128m -DconfigPath=$CONFIG_DIR"

# program name
PROG_NAME=SolGeneosCmdLineCipherTool

#classpath function
lcp() {
  # if the directory is empty, then it will return the input string
  if [ -f "$1" ] ; then
    if [ -z "$LOCALCLASSPATH" ] ; then
      LOCALCLASSPATH="$1"
    else
      LOCALCLASSPATH="$1":"$LOCALCLASSPATH"
    fi
  fi
}

# set environment
setenv() {
    if [ -n "${SOLGENEOS_HOME}" ] ; then
      _SOLGENEOS_HOME=$SOLGENEOS_HOME
    fi

    if [ -n "${JAVA_HOME}" ] ; then
      _JAVA_HOME=$JAVA_HOME
    fi

    # reset LOCALCLASSPATH
    LOCALCLASSPATH=""
	# add in the required dependency of  *.jar files
	for i in $_SOLGENEOS_HOME/currentload/lib/*.jar
	do
	  lcp $i
	done

	# enable logging by adding log4j lib and log4j.properties to classpath
	for i in $_SOLGENEOS_HOME/currentload/lib/optional/*.jar
	do
	  lcp $i
	done
	LOCALCLASSPATH="$CONFIG_DIR":"$LOCALCLASSPATH"

}

setenv

cd $_SOLGENEOS_HOME

$_JAVA_HOME/bin/java -cp $LOCALCLASSPATH $SOLACE_OPTS $MAIN_CLASS $@
