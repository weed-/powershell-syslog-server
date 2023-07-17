@echo off
REM /*
REM     Removes the Windows service "simple-syslog-server"
REM     with NSSM
REM
REM     - Run 'as administrator' from explorer or shell
REM */

sc stop simple-syslog-server
%~dp0nssm.exe remove simple-syslog-server
