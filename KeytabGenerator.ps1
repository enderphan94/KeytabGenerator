param(
    [string]$sAMAccount,
    [string[]]$SPNsList # SPNs need to be written separately with comma and space space after it ", "
   
)
$SPNsList = $SPNsList -split ", "
# compulsive arguments
$domain =""
$scriptPath ="E:"

# logs initialization
$logPath = $scriptPath + "\logs"
$date = (get-date).ToString('yyyy-MM-dd')
$dateLogTime= "[" + ( get-date ).ToString('yyyy-MM-dd HH:mm:ss') + "]: "
$keytabFile = $scriptPath + "keytab1.keytab"

if( -Not $(Test-Path $logPath) )
{
      New-Item -ItemType Directory $logPath
}

# main functions
function writeLog($log){
    
    $logFile= $logPath + "\log_" + $date + ".txt"

    if($(Test-Path $logFile) -ne "True")
    {
      New-Item -ItemType file $logFile
    }
    add-content $logFile "$log`n"
}

function passGenerator{

    $special = $(33..47|%{[char]$_}) + $(58..64|%{[char]$_}) +$(91..96|%{[char]$_}) + $(123..126|%{[char]$_})|Get-Random -c 2

    $number = 48..57|%{[char]$_}|Get-Random -c 3

    $upCase = 65..90|%{[char]$_}|Get-Random -c 4

    $lowCase = 97..122|%{[char]$_}|Get-Random -c 5

    $pass = $special + $number + $upCase +$lowCase
    
    return $pass -join ""
}

function genKeytab{

    if($(Test-Path $keytabFile)){
        Remove-Item $keytabFile
    }

    if($sAMAccount -and $SPNsList.Length -ne 0){
        
        
        $iniSPN = $SPNsList[0]
        $passwd = $(passGenerator)

        $outCMD = ktpass  -princ  $iniSPN"@"$domain `
                          -mapuser $sAMAccount `
                          -crypto AES256-SHA1 `
                          -ptype KRB5_NT_PRINCIPAL `
                          -pass $passwd `
                          -mapOp add `
                          -out $keytabFile 2>&1
        
        writeLog $($dateLogTime+$outCMD)
        
        for ($i=1; $i -lt $SPNsList.Length;$i++){
            $spn = $SPNsList[$i]      
            $outCMD = ktpass  -princ  $spn"@"$domain `
                              -mapuser $sAMAccount `
                              -crypto AES256-SHA1 `
                              -ptype KRB5_NT_PRINCIPAL `
                              -pass $passwd `
                              -mapOp add `
                              -in $keytabFile `
                              -out $keytabFile 2>&1
            
            writeLog $($dateLogTime+$outCMD)
     
        }        
        
        $Content = Get-Content -Path $keytabFile -Encoding Byte -ErrorAction SilentlyContinue       

        if (!$Content)
        {
            $logMessage = "Error. Failed to retrieve keytab. Keytab was not created"

            WriteLog $($dateLogTime + $logMessage )	
	
            Return $logMessage
        }
        $logMessage = "Keytab for $sAMAccount successfully created"
        WriteLog $($dateLogTime +  $logMessage )	

        Write-Output "`n$logMessage"

    }
}
genKeytab
