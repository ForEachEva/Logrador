<#
.Synopsis
Logrador.ps1

.DESCRIPTION
Logrador Logging Class

.PARAMETER Fyll inn params
Specifies the beskrivelse

.INPUTS
None. You cannot pipe objects to Logrador

.OUTPUTS
None.

.EXAMPLE
>$Logrador = [Logrador]::new($([LogradorLogMode]::File,"C:\Logrador\Mylog.log",$null))

.NOTES
Author : Eva totland Øen
Version : 1.0
E-mail: eva.totland.oen@outlook.com
E-mail2: eva.totland.oen@outlook.com
Github   : Foreacheva\Shellfdevelopment

Disclaimer:
This script is provided 'AS IS' with no warranties, confers no rights and
is not supported by the author.

.LINK
https://github.com/ForEachEva/Shellfdevelopment
#>


enum LogradorErrorLevel{
    Default
    Detailed
    Debug
    Minimal
}
# Enum for Logdradors Logmodes
enum LogradorLogMode{
    File
    EventLog
    Both
}

class Logrador { # like a dog, it retrieves what you throw 
    [LogradorLogMode]$LogMode
    [AllowNull()][String]$Path
    [AllowNull()][String]$EventLog
    hidden[hashtable]$Errorlevel
    $LogLevel = [LogradorErrorLevel]::Default
    [switch]$EchoHost
    
    # Constructors
    Logrador([System.Enum]$LogMode,[string]$LogFilepath,[string]$EventLogName){
        $this.LogMode = $LogMode
        $this.Path = $logfilepath
        $this.EventLog = $EventLogName               
    }
    # Hidden method used by all Write-methods to output to log / echo to host. 
    # hidden[void] AppendLog([string[]]$Message,[String]$Category){
    #     Write-Output "[$(get-date -UFormat "%D %T")][$Category]: $Message" | Out-file -LiteralPath $this.Path -Append 
    #     If($this.EchoHost.IsPresent){
    #         switch ($Category) {
    #             "Error" { Write-Host -ForegroundColor Red "[$Category]: $Message" }
    #             "Warning" { Write-Host -ForegroundColor Yellow "[$Category]: $Message" }
    #             "Information" { Write-Host -ForegroundColor Cyan "[$Category]: $Message" }
    #             Default { Write-Host -ForegroundColor White "[$Category]: $Message"}
    #         }
    #     }
    # }
    hidden[void] AppendLog([string[]]$Message,[System.Diagnostics.EventLogEntryType]$EventType){
        If($([LogradorLogMode]::File,[LogradorLogMode]::Both) -contains $this.LogMode){
            #$this.WriteFileLog
            Write-Output "[$(get-date -UFormat "%D %T")][$EventType]: $Message" | Out-file -LiteralPath $this.Path -Append 
            If($this.EchoHost.IsPresent){
                switch ($EventType) {
                    "Error" { Write-Host -ForegroundColor Red "[$EventType]: $Message" }
                    "Warning" { Write-Host -ForegroundColor Yellow "[$EventType]: $Message" }
                    "Information" { Write-Host -ForegroundColor Cyan "[$EventType]: $Message" }
                    Default { Write-Host -ForegroundColor White "[$EventType]: $Message"}
                }
            }
        }
        If($([LogradorLogMode]::EventLog,[LogradorLogMode]::Both) -contains $this.LogMode){
            # static void WriteEntry(string source, string message)
            # static void WriteEntry(string source, string message, System.Diagnostics.EventLogEntryType type)
            # static void WriteEntry(string source, string message, System.Diagnostics.EventLogEntryType type, int eventID)
            $this.WriteEventLog
        }
    }
    [void] WriteInfo([String]$Message){
        $Type = [System.Diagnostics.EventLogEntryType]::Information
        $this.AppendLog($Message,$Type)
    }
    [void] WriteWarning([String]$Message){
        $Type = [System.Diagnostics.EventLogEntryType]::Warning
        $this.AppendLog($Message,$Type)
    }
    [void] WriteError([String[]]$Message){
        $Type = [System.Diagnostics.EventLogEntryType]::Error
        $this.AppendLog($Message,$Type)
    }
    [void] GetLogModeOptions(){
        Write-Host "enum LogradorLogMode valid values:"
        [enum]::GetValues([LogradorLogmode]) | Out-Host
        #return $([LogradorLogMode])
    }
    [void] SetLogMode([LogradorErrorLevel]$LogMode){
        $this.LogMode = $LogMode
    }
    [void] GetErrorLevelOptions(){
        [enum]::GetValues([LogradorErrorLevel]) | Out-Host 
    }
    [void] GetConfig (){
        $($this | Format-Table | Out-String) | %{Write-Host -ForegroundColor Cyan -Object $_}
        If($null -eq $this.Errorlevel){
            Write-Host -ForegroundColor Yellow "ErrorLevel not configured!"
        }
        Else{
            Write-Host "ErrorLevel set to '$($this.LogLevel)':"
            $($this.Errorlevel | Out-String) | %{Write-Host -ForegroundColor Cyan -Object $_ }
            If($this.LogLevel -eq [LogradorErrorLevel]::Debug){
                Write-Host -ForegroundColor Yellow "Warning: Debug-mode enumerates and outputs *all* error-object properties (Detailed + all other properties)."
            }
        }
    }
    [void] SetDefaultErrorLevel(){
        $this.LogLevel = [LogradorErrorLevel]::Default
        $this.LockErrorLevel($this.LogLevel)
        Write-Host -ForegroundColor Green "[Logrador feedback]: LogLevel set to $($this.LogLevel)"
    }
    [void] SetDetailedErrorLevel(){
        $this.LogLevel = [LogradorErrorLevel]::Detailed
        $this.LockErrorLevel($this.LogLevel)
        Write-Host -ForegroundColor Green "[Logrador feedback]: LogLevel set to $($this.LogLevel)"
    }
    [void] SetDebugErrorLevel(){
        $this.LogLevel = [LogradorErrorLevel]::Debug
        $this.LockErrorLevel($this.LogLevel)
        Write-Host -ForegroundColor Green "[Logrador feedback]: LogLevel set to $($this.LogLevel)"
    }
    [void] SetMinimalErrorLevel(){
        $this.LogLevel = [LogradorErrorLevel]::Minimal
        $this.LockErrorLevel($this.LogLevel)
        Write-Host -ForegroundColor Green "[Logrador feedback]: LogLevel set to $($this.LogLevel)"
    }
    [void] SetErrorLevel([LogradorErrorLevel]$ErrorLevel){
        $this.LogLevel = $ErrorLevel
        $this.LockErrorLevel($this.LogLevel)
        Write-Host -ForegroundColor Green "[Logrador feedback]: LogLevel set to $($this.LogLevel)"
    }
    hidden[void] LockErrorLevel([LogradorErrorLevel]$key){
        $LockMap = @{
            [LogradorErrorLevel]::Default = $("Exception","CategoryInfo","FullyQualifiedErrorId","InvocationInfo","Message")
            [LogradorErrorLevel]::Detailed = $("Exception","TargetObject","CategoryInfo","FullyQualifiedErrorId","ErrorDetails","InvocationInfo","Message","ScriptStacktrace","PipelineIterationInfo")
            [LogradorErrorLevel]::Debug = "*"
            [LogradorErrorLevel]::Minimal = $("Exception","Message")
        }
        $ErrorPropertyMap = @{
            "Exception" = $false
            "Message" = $false
            "TargetObject" = $false
            "CategoryInfo" = $false
            "FullyQualifiedErrorId" = $false
            "ErrorDetails" = $false
            "InvocationInfo" = $false
            "ScriptStackTrace" = $false
            "PipelineIterationInfo" = $false
            "SerializeExtendedInfo" = $false
        }
        $AllKeyList = $ErrorPropertyMap.Keys.ForEach({$_.ToString()})
        If($key -eq [LogradorErrorLevel]::Debug){
            $AllKeyList | %{ $ErrorPropertyMap[$_] = $true}
        }
        Else{
            $OpenKeyList = $LockMap[$key]
            $AllKeyList | %{
                If($OpenKeyList -contains $_){
                    $ErrorPropertyMap[$_] = $true
                }
                Else{
                    $ErrorPropertyMap[$_] = $false
                }
            }
        }
        $this.Errorlevel = $ErrorPropertyMap.Clone()
    }
    [void] WriteErrorObject([Object]$ErrorObject){
        If($this.LogLevel -and $null -eq $this.Errorlevel){
            Write-Host -ForegroundColor Green "[Logrador feedback]: LogLevel set to $($this.LogLevel)"
            $this."Set$($this.LogLevel)ErrorLevel"()
        }
        If($null -eq $this.Errorlevel){
            Write-Host -ForegroundColor Green "[Logrador feedback]: LogLevel set to Default;(SetDefaultErrorLevel())"
            $this.SetDefaultErrorLevel()
        }
        function Get-ObjectValues {
            param (
                [Object]$InputObject,
                [String[]]$GetSelectedProperties
            )
            [string[]]$CollatedMessages = $null
            foreach($prop in $GetSelectedProperties){
                If($ErrorObject.PSObject.Properties.Name -contains $prop){
                    [string[]]$CollatedMessages+= "----- $prop property data:"
                    If(!$([string]::IsNullOrWhiteSpace($($ErrorObject.$prop | Out-String)))){
                        [string[]]$CollatedMessages+= $($ErrorObject.$prop | Out-String)
                    }
                    Else{
                        If($this.LogLevel -eq [LogradorErrorLevel]::Debug){
                            [string[]]$CollatedMessages+= "<empty>"
                        }
                    }
                }
                Else{
                    $this.WriteInfo("[Logrador feedback]: Property $prop not found!")
                }
            }
            return $CollatedMessages
        }
        $SelectedProperties = $this.Errorlevel.GetEnumerator() | %{ If($_.Value -eq $true){return $_.Key}}
        If($this.LogLevel -eq [LogradorErrorLevel]::Debug){
            $this.WriteWarning("[Logrador feedback]: Is in debug-mode!")
            $this.WriteWarning("[Logrador feedback]: No object-property filter was supplied. Enumerating and adding all properties!")
            $Methods = $ErrorObject.psobject.Methods.GetEnumerator().Name #enumerate methods to ensure we don't output method values /ET
            $SelectedProperties = $($ErrorObject.psobject.Properties | Where-Object -Property "Name" -NotIn $Methods).Name #filter away potential method values /ET (this can happen if you pass an errorobject.propertys'.property and automatically enumerate it. This can also result in null output)
            $this.WriteInfo("[Logrador feedback]: Found $($SelectedProperties.Count) to parse")
        }
        # filter the object /ET
        $StringOutput = Get-ObjectValues -InputObject $ErrorObject -GetSelectedProperties $SelectedProperties
        If($null -eq $StringOutput){
            $this.WriteError("[Logrador feedback]: Filter returned 0 items! Check your filter-settings!")
        }
        Else{
            $this.WriteInfo("[Logrador feedback]: Filter contains $($StringOutput.Count) item(s)")
        }
        # Check for BaseException Method /ET
        $BaseException = $null
        If($($ErrorObject.PSObject.Methods.GetEnumerator().Name) -contains 'GetBaseException'){
            $BaseException = $ErrorObject.GetBaseException()
            $this.WriteError("[Logrador feedback]: Object has GetBaseException() Method, adding it..") 
        }
        # Adding BaseException output to filtered StringOutput /ET
        $StringOutput+=$BaseException
        # Output the filtered content to loggfile /ET
        foreach($Output in $StringOutput){
            $Output = $Output -split ('\r') #split multistrings on carriage-return /ET
            Write-Verbose "Message Count: $($Output.Count)"
            Write-Verbose "Message Length $($Output.Length)"
            foreach($line in $Output){
                If([string]::IsNullOrWhiteSpace($line)){
                    Write-Verbose "String is Null or Whitespace. Skip"
                    continue
                }
                $this.WriteError($line.Trim()) # remove leading & trailing whitespaces and output it to logfile. /ET
            }
        }
    }
    [void]GetEventLog(){
        #$EventLog = Get-WinE
        If([string]::IsNullOrWhiteSpace($this.EventLog)){
            Write-Host -ForegroundColor Yellow "EventLog not configured!"
        }
        Else{
            $EventLogSession = [System.Diagnostics.Eventing.Reader.EventLogSession]::new()
            $EventLogHandler = [System.Diagnostics.Eventing.Reader.EventLogConfiguration]::new('Logrador',$EventLogSession)
            $($EventLogHandler | Out-String) | %{Write-Host -ForegroundColor Cyan -Object $_ }
            $PathType = [System.Diagnostics.Eventing.Reader.PathType]::LogName
            $EventLogSession.GetLogInformation('Logrador',$PathType)
            #[System.Diagnostics.Eventing.EventProvider]::new(
            $Instance = [System.Diagnostics.EventInstance]::new([long]2000,[int]100,[System.Diagnostics.EventLogEntryType]::Error)
            [System.Diagnostics.EventLog]::WriteEvent('Logrador',$Instance,$($error[0] | Out-String))
            [System.Diagnostics.EventLog]::WriteEntry('Logrador','Test WriteEntry')
        }
    }
}
