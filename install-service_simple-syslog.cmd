@echo off
REM /*
REM     Installs Windows service "simple-syslog-server"
REM     with NSSM from current directory
REM
REM     - Run 'as administrator' from explorer or shell
REM */

%~dp0nssm.exe install simple-syslog-server Powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0simple-syslog-server.ps1"
%~dp0nssm.exe set simple-syslog-server Description Simple Syslog Server ^(PowerShell^)
