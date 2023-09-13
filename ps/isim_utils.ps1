#TODO 1: SSL checker

function isim_ws_init{
	[CmdletBinding()]
        param (
			[switch]$SkipTest
		)
	try{
		$GLOBAL:PROPFILEPATH="$PSScriptRoot\isim.properties"
		
		Write-Host
		Write-Host -fore green "--- Starting initialization ---"
		Write-Host

		Write-Host -fore green "`tReading properties"
		read_Properties
		
		isDebugRun
		Write-Host -fore green "`tRuning on debug: $($Global:ISIM_WS_PROPS['DEBUG'])"

		setLogFiles
		debugLog "info" "--- Starting initialization ---"
		
		Write-Host -fore green "`tDebug log: $($GLOBAL:LOGFILE_DEBUG)"
				
		Write-Host -fore green "`tBuilding WSDL URLs"
		build_WSDL
		
		if (! $SkipTest.IsPresent){
			Write-Host -fore green "`tTesting connections"
			Test_Connections
		}

		Write-Host
		Write-Host -fore green "--- Initialization completed ---"
		Write-Host
		
		debugLog "info" "--- Initialization completed ---"
	}catch{
		Write-Host -fore red "$($Error[0])"
	}
}

function read_Properties{
		
		$GLOBAL:ISIM_WS_PROPS=$null
		
		try{
			if (Test-Path -Path $GLOBAL:PROPFILEPATH -PathType Leaf){
				$GLOBAL:ISIM_WS_PROPS = ConvertFrom-StringData (Get-Content $GLOBAL:PROPFILEPATH -raw)
			}else{
				Throw
			}
		}catch{
			Write-Host -fore red "$($Error[0])"
			Write-Host -fore red "`t$($PSItem.InvocationInfo.Scriptname.toString().split("\")[-1]): Error in code line $($PSItem.InvocationInfo.ScriptLineNumber)."
		}

}

function build_WSDL(){
	$GLOBAL:ISIM_URL							=	"https://" + $GLOBAL:ISIM_WS_Props['ISIM_APP'] + ":" + $GLOBAL:ISIM_WS_Props['ISIM_APP_PORT']
	$GLOBAL:ISIM_WSDL_ACCESS					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_ACCESS']
	$GLOBAL:ISIM_WSDL_ACCOUNT					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_ACCOUNT']
	$GLOBAL:ISIM_WSDL_EXTENSION					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_EXTENSION']
	$GLOBAL:ISIM_WSDL_GROUP						=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_GROUP']
	$GLOBAL:ISIM_WSDL_ORGANIZATIONALCONTAINER	=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_ORGANIZATIONALCONTAINER']
	$GLOBAL:ISIM_WSDL_PASSWORD					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_PASSWORD']
	$GLOBAL:ISIM_WSDL_PERSON					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_PERSON']
	$GLOBAL:ISIM_WSDL_PROVISIONING				=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_PROVISIONING']
	$GLOBAL:ISIM_WSDL_REQUEST					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_REQUEST']
	$GLOBAL:ISIM_WSDL_ROLE						=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_ROLE']
	$GLOBAL:ISIM_WSDL_SEARCHDATA				=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_SEARCHDATA']
	$GLOBAL:ISIM_WSDL_SERVICE					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_SERVICE']
	$GLOBAL:ISIM_WSDL_SESSION					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_SESSION']
	$GLOBAL:ISIM_WSDL_SHAREDACCESS				=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_SHAREDACCESS']
	$GLOBAL:ISIM_WSDL_SYSTEMUSE 				=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_SYSTEMUSER']
	$GLOBAL:ISIM_WSDL_TODO						=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_TODO']
	$GLOBAL:ISIM_WSDL_UNAUTH					=	$GLOBAL:ISIM_URL + $GLOBAL:ISIM_WS_Props['WS_WSDL_UNAUTH']
}

function testConnections_Host(){
	param (
        $propValue,
		$propName
    )
	try{
		if ($null -ne $propValue){
			ping -n 1 $propValue > $null
			if ($LASTEXITCODE -eq 0){
				Write-Host -fore green "`t`t${propName}: OK"
			}else{
				Throw "`t`t$($propName): Could not find host $($propValue)"
			}
		}else{
			Write-Host -fore red "`t`t${propName}: Property missing"
			Throw "Property missing"
		}
	}catch{
		Write-Host -fore red "$($Error[0])"
	}

}

function testConnections_Secure(){
	#TODO 1: SSL checker
		# ServerCertificateValidationCallback = true
		# This property allows to run non-secure
		# Purpose:
		#  If SSL not trusted, bypass it
	param (
		$WSDL
    )

	try{
		[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

		$GLOBAL:ISIM_VERSION=(New-WebServiceProxy -Uri ${WSDL} -ErrorAction STOP).getItimVersionInfo().version
		Write-Host -fore yellow "`t`tSSL Connection: OK (bypassed)"

	}catch [System.Management.Automation.MethodInvocationException]{
		Throw "``ttCould not establish trust relationship for the SSL/TLS secure channel"
		Write-Host -fore red "$($Error[0])"
	}
}

function test_Connections{

	try{
		Write-Host -fore green "`t`tSSL Enabled =" $GLOBAL:ISIM_WS_PROPS['SSL']

		TestConnections_Host $GLOBAL:ISIM_WS_Props['ISIM_VA'] "ISIM VA"
		TestConnections_Host $GLOBAL:ISIM_WS_Props['ISIM_APP'] "ISIM APP"

		if ([System.Convert]::ToBoolean($GLOBAL:ISIM_WS_PROPS['SSL'])){
			TestConnections_Secure $GLOBAL:ISIM_WSDL_SESSION
		}

		Write-Host -fore green "`t`tAll connections tested on ISIM v.$GLOBAL:ISIM_VERSION"

	}catch{
		Write-Host -fore red "$($Error[0])"
	}

}

function printFunctionInfo($invocationName){
	
	$ParameterList = (Get-Command -Name $invocationName).Parameters;
	debugLog "info" "printFunctionInfo:	+ $invocationName - Input Info:"
	
	foreach ($key in $ParameterList.keys){
		$var = Get-Variable -Name $key -ErrorAction SilentlyContinue;
		if($var){
			debugLog "info" "printFunctionInfo:	++  $($var.name): $($var.value)"
		}
	}
}

function readDataFromCSV{
	[CmdletBinding()]
	param (
		[Parameter(position=1)]
		[String] $Delimeter = ";",
		[Parameter(Mandatory, position=2)]
			[ValidateScript({
				if(-Not ($_ | Test-Path) ){
					throw "File or folder does not exist"
				}
				if(-Not ($_ | Test-Path -PathType Leaf) ){
					throw "The Path argument must be a file. Folder paths are not allowed."
				}
				if($_ -notmatch "(\.csv)"){
					throw "The file specified in the path argument must be either of type csv"
				}
				return $true 
			})]
		[System.IO.FileInfo] $file
	)

	debugLog "info" "readDataFromCSV:	+ Reading CSV file: $file"
	debugLog "info" "readDataFromCSV:	+ CSV file delimeter: $delimeter"
	
	return Import-Csv $file -Delimiter $delimeter
}

function isDebugRun(){
	try {
		$Global:ISIM_WS_PROPS['DEBUG'] = [System.Convert]::ToBoolean($Global:ISIM_WS_PROPS['DEBUG'])
	} catch [FormatException] {
		$Global:ISIM_WS_PROPS['DEBUG'] = $false
	}
}

function timeStamp() { (Get-Date).toString("yyyy.MM.dd-HH.mm.ss") }

function debugLog(){
	[CmdletBinding()]
        param (
			[Parameter(Mandatory, position=0)]
			[ValidateSet(
				"info", "error", "warning", "debug", "trace"
			)]
            $cat,
			[Parameter(Mandatory, position=1)]
			[string]	$msg
		)

	$logFile = $GLOBAL:LOGFILE_DEBUG
	# $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$LogMessage = "$(timeStamp) - " + "[" + $cat.ToUpper() + "]" + "	" + $msg
	
	Add-content $LogFile -value $LogMessage
	
	if ($Global:ISIM_WS_PROPS['DEBUG']){
		Write-host -fore Yellow "DEBUG:	$LogMessage"
	}
	
}

function setLogFiles(){
	# $logStamp = (Get-Date).toString("yyyy.MM.dd-HH.mm.ss")

	$logPath_debug = $Global:ISIM_WS_PROPS['LOGPATH_DEBUG']
	# $logFile = $logPath_debug + "/" + $logStamp + "-" + "debugLog" + ".log"
	$logFile = $logPath_debug + "/" + $(timeStamp) + "-" + "debugLog" + ".log"

	$GLOBAL:LOGFILE_DEBUG=$logFile

	debugLog "info" "--- Debug file created ---"
}