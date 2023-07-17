#requires -version 2
<#
.SYNOPSIS
  A very simple and not-so-powerful syslog server (simple syslogd) in PowerShell
.DESCRIPTION
  This small syslog server can be run from command line or as a service. It can be used to collect syslogs from almost any networking device.
  Change $LogFolder to your logfile destination path. Logs will be created/rotated on daily basis.

  Run the Server on console (Windows Terminal recommended)
  .\simple-syslog-server.ps1 

  Install as a service (run "as admin")
  .\install-service_simple-syslog.cmd

  Remove service (run "as admin")
  .\remove-service_simple-syslog.cmd
.PARAMETER <Parameter_Name>
  None
.INPUTS
  None
.OUTPUTS
  Daily log files stored in $LogFolder
.NOTES
  Version:        0.6
  Author:         b.stromberg@data-systems.de
  Creation Date:  06-2023
  Purpose/Change: Initial commit
.EXAMPLE
  .\simple-syslog-server.ps1
#>

# ------ Config
$LogFolder = ""                         # Syslog file path ("c:\syslog")
$SysLogPort = 514                       # Syslogd Port (default: 514)
$Buffer = New-Object Byte[] 1024        # Max SysLog message (line) size (default: 1024)
$EnableMessageValidation = $True        # Enable PRI (Priority Facility) through header validation


# Defaults $LogFolder to $PSScriptRoot if not set
if (-not($LogFolder) )
{
    $LogFolder = $PSScriptRoot
} 

# readable datestamps (like 01-02-2025-11:42:00)
$today=(Get-Date -Format "dd")+"-"+(Get-Date -Format "MM")+"-"+(Get-Date -Format "yyyy")+"-"+(Get-Date -Format "HH:mm:ss")

# Syslog-Facility Objects table (Facility Severity Grid)
Add-Type -TypeDefinition @"
       public enum Syslog_Facility
       {
               kern,
               user,
               mail,
               system,
               security,
               syslog,
               lpr,
               news,
               uucp,
               clock,
               authpriv,
               ftp,
               ntp,
               logaudit,
               logalert,
               cron,
               local0,
               local1,
               local2,
               local3,
               local4,
               local5,
               local6,
               local7,
       }
"@

# Syslos-PRI Definitions
Add-Type -TypeDefinition @"
       public enum Syslog_Severity
       {
               Emergency,
               Alert,
               Critical,
               Error,
               Warning,
               Notice,
               Informational,
               Debug
       }
"@

# Syslog Socket + Endpoint
Function Start-SysLog
{
  $Socket = CreateSocket
  StartReceive $Socket
}
Function CreateSocket
{
  $Socket = New-Object Net.Sockets.Socket(
    [Net.Sockets.AddressFamily]::Internetwork,
    [Net.Sockets.SocketType]::Dgram,
    [Net.Sockets.ProtocolType]::Udp)

  $ServerIPEndPoint = New-Object Net.IPEndPoint(
    [Net.IPAddress]::Any,
    $SysLogPort)

  $Socket.Bind($ServerIPEndPoint)
  Return $Socket
}

Function StartReceive([Net.Sockets.Socket]$Socket)
{
  # Placeholder for incoming packet source
  $SenderIPEndPoint = New-Object Net.IPEndPoint([Net.IPAddress]::Any, 0)
  $SenderEndPoint = [Net.EndPoint]$SenderIPEndPoint

  $ServerRunning = $True
  While ($ServerRunning -eq $True)
  {
    $BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$SenderEndPoint)
    $Message = $Buffer[0..$($BytesReceived - 1)]

    # Bytestring --> Parse Ascii --> Priority
    $MessageString = [Text.Encoding]::ASCII.GetString($Message)
    $Priority = [Int]($MessageString -Replace "<|>.*")  

    [int]$FacilityInt = [Math]::truncate([decimal]($Priority / 8))
    $Facility = [Enum]::ToObject([Syslog_Facility], $FacilityInt)
    [int]$SeverityInt = $Priority - ($FacilityInt * 8 )
    $Severity = [Enum]::ToObject([Syslog_Severity], $SeverityInt)

    # Get FQDN or simple Hostname
    $HostName =  $SenderEndPoint.Address.IPAddressToString

    if($Facility -eq "System")
    {
        $MessageString = $today.ToString() + " <SCOM:$Severity> $(Get-Date -Format "MMM dd @ hh:mmtt") $MessageString"
    }
    else
    {
        $MessageString = $today.ToString() + " $MessageString" 
    }

    # Prettify console output
    #   Fore = Text
    #   Back = Background
    switch($Severity)
    {
        Emergency     {$Fore = 'White';  $Back = 'Red'}
        Alert         {$Fore = 'White';  $Back = 'Yellow'}
        Error         {$Fore = 'Red';    $Back = 'Black'}
        Critical      {$Fore = 'Red';    $Back = 'Black'}
        Warning       {$Fore = 'Yellow'; $Back = 'Black'}
        Notice        {$Fore = 'White';  $Back = 'Black'}
        Informational {$Fore = 'Green';  $Back = 'Black'}
        Debug         {$Fore = 'Black';  $Back = 'white'}
        default       {$Fore = 'White';  $Back = 'Black'}
    }
    Write-Host $MessageString -ForegroundColor $Fore -BackgroundColor $Back

    # Write Logfile (eg "c:\syslogd\hostname-yyy.mm.dd.log")
    $DateStamp = (Get-Date).ToString("yyyy.MM.dd")
    $LogFile = "$LogFolder$HostName-$DateStamp.log"
    $MessageString >> $LogFile
    }
}

# Engage!
Start-SysLog