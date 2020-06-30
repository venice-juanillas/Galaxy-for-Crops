@echo off

set TOP=.
set LIB_JARS=%TOP%\lib

set CP=%TOP%\sTASSEL.jar
for %%i in (%LIB_JARS%\*.jar) do call "%TOP%\cp.bat" %%i
echo %CP%

java -classpath "%CP%" -Xms512m -Xmx1536m %*
