# A Simple Syslog Server (syslogd)

- Made completely in PowerShell (v2+)
- Portable (contains NSSM binary)
- Can be run as system service (install/remove)
- Can be run on console for syslog messages in realtime
- Drops syslog logfiles per host/day

This has helped me a few times to debug networking issues. Maybe this helps someone, too.

## Install / Use

Change `$LogFolder` to your logfile destination path, otherwise the current directory will be used.

`.\simple-syslog-server.ps1` Starts syslogd with console output (Just run it in your favorite PowerShell Host)

`.\install-service_simple-syslog.cmd` - Installs Windows Service

`.\remove-service_simple-syslog.cmd` - Removes Windows Service
