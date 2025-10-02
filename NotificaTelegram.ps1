# Author: Andre Torres
# To fill the parameters BotKey, ChatId & GroupId, refer to https://github.com/jacauc/WinLoginAudit

$BotKey = "XXX"
$ChatId = "YYY"
$GroupId = "ZZZ"
$LogFile = "C:\Tools\Scripts\logs.txt"

$EventRecordID = $args[0]
$EventRecordID | Out-File -FilePath $LogFile -Append

$Report = Get-WinEvent -LogName "ForwardedEvents" -FilterXPath "*[System[EventRecordID=$EventRecordID]]"

$Xml = [xml]$Report.ToXml()
$EventID = $Xml.Event.System.EventID
$Message = $Xml.Event.RenderingInfo.Message
$Time = $Xml.Event.System.TimeCreated.SystemTime
$Computer = $Xml.Event.System.Computer

try
{
    $Response = Invoke-WebRequest -UseBasicParsing -Uri "https://api.telegram.org/bot$BotKey/sendMessage?chat_id=$GroupId&parse_mode=Markdown&text=⚠*ALERTA DE LOGS - WEF*⚠ %0AOrigem: *$Computer* %0AData/hora: $Time %0AEventID: $EventID %0A$Message"
    $Response | Out-File -FilePath $LogFile -Append
}
catch [Exception]
        {
            $exception = $_.Exception.ToString().Split(".")[2]
            $exception| Out-File -FilePath $LogFile -Append
        }
