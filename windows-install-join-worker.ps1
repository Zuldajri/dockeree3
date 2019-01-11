[CmdletBinding()]

# Modify the $DockerEngineURI with the latest link from https://dockermsft.blob.core.windows.net/dockercontainer/DockerMsftIndex.json

Param(
  [switch] $SkipEngineUpgrade,
  [string] $ArtifactPath = ".",
  [string] $DockerEngineURI = "https://dockermsft.blob.core.windows.net/dockercontainer/docker-18-09-1.zip",
  [string] $USERNAME,
  [string] $PASSWORD,
  [string] $UCPURI,
  [string] $DTRURI,
  [string] $SWARMMGRIP
)

#Variables
$Date = Get-Date -Format "yyyy-MM-dd HHmmss"
$DockerPath = "C:\Program Files\Docker"
$DockerDataPath = "C:\ProgramData\Docker"
$UserDesktopPath = "C:\Users\Default\Desktop"


function Install-LatestDockerEngine () {

    #Get Docker Engine from Master Builds
    Stop-Service docker
    Invoke-WebRequest -UseBasicparsing -Uri $DockerEngineURI -OutFile docker.zip

    #Get Docker Engine
    Expand-Archive docker.zip -DestinationPath $Env:ProgramFiles -Force
    $env:path += ";$env:ProgramFiles\docker"

    dockerd --register-service
    Start-Service docker

}



function Join-Swarm ()
{

    # UCP Rest API detail is here : https://docs.docker.com/datacenter/ucp/2.2/reference/api/#/

    # Get the required images to configure the local engine

    docker image pull docker/ucp-agent-win:3.1.0
    docker image pull docker/ucp-dsinfo-win:3.1.0

    # Execute the local node configuration

    docker container run --rm docker/ucp-agent-win:3.1.0 windows-script | powershell -noprofile -noninteractive -command 'Invoke-Expression -Command $input'

    # Deactivate HTTPS cert check to allow REST access to UCP with self signed cert

    Write-Host "Deactivating Cert validation"
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Login to UCP to get an authentication token

    Write-Host "Authenticating against UCP"
    $postParams = @{username="$USERNAME";password="$PASSWORD"}
    $JSON = $postParams | convertto-json
    $result = Invoke-WebRequest -UseBasicparsing -Uri https://$UCPURI/auth/login -Method POST -Body $JSON | ConvertFrom-Json
    $Token=$result.auth_token

    # Retrieve the SWARM information to get the join token for workers

    Write-Host "Get Swarm Information"
    $header =  @{Authorization="Bearer $Token"}
    $swarm_info = Invoke-WebRequest -UseBasicparsing -Uri https://$UCPURI/swarm -Method GET -Headers $header | ConvertFrom-Json
    $WORKER_Join_Token = $swarm_info.JoinTokens.Worker

    # Join the node to UCP

    Write-Host "Join the worker to UCP"
    docker swarm join --token $WORKER_Join_Token $SWARMMGRIP

}


function Customize-User-Desktop ()
{
#Install-Module -Name Image2Docker -RequiredVersion 1.8.2 -Force
#Import-Module -Name Image2Docker -RequiredVersion 1.8.2 -Force

# Download the DTR certificate to install it and trust it (to allow docker login commands)

    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

if($netAssembly)
{
    $bindingFlags = [Reflection.BindingFlags] "Static,GetProperty,NonPublic"
    $settingsType = $netAssembly.GetType("System.Net.Configuration.SettingsSectionInternal")

    $instance = $settingsType.InvokeMember("Section", $bindingFlags, $null, $null, @())

    if($instance)
    {
        $bindingFlags = "NonPublic","Instance"
        $useUnsafeHeaderParsingField = $settingsType.GetField("useUnsafeHeaderParsing", $bindingFlags)

        if($useUnsafeHeaderParsingField)
        {
          $useUnsafeHeaderParsingField.SetValue($instance, $true)
        }
    }
}

    $webClient = new-object System.Net.WebClient
    $webClient.DownloadFile( "https://$DTRURI/ca", "$UserDesktopPath\dtrca.crt" )

    Import-Certificate "$UserDesktopPath\dtrca.crt" -CertStoreLocation Cert:\LocalMachine\AuthRoot

    # Copy some additionnal files in the user desktop

    Copy-Item ".\copy_certs.ps1" "$UserDesktopPath\copy_certs.ps1" -Force
    Copy-Item ".\MTA-Commands.txt" "$UserDesktopPath\MTA-Commands.txt" -Force


#    Move-Item ".\ws2016.vhd" "$UserDesktopPath\ws2016.vhd" -Force
}


function Install-Keyboards ()
{
     New-Item -Path "$UserDesktopPath\keyboard-french-mac" -ItemType Directory -Force
     Expand-Archive -Path keyboard-french-mac.zip -DestinationPath "$UserDesktopPath\keyboard-french-mac" -Force
     Start-Process -FilePath "$UserDesktopPath\keyboard-french-mac\setup.exe" -ArgumentList "/a"
}


#Start Script

$ErrorActionPreference = "Stop"

try
{
    Start-Transcript -path "$UserDesktopPath\configure-worker $Date.log" -append

    Set-ExecutionPolicy Unrestricted -Force

    Write-Host "ArtifactPath = $ArtifactPath"
    Write-Host "DockerEngineURI = $DockerEngineURI"
    Write-Host "USERNAME = $USERNAME"
    Write-Host "UCPURI = $UCPURI"
    Write-Host "DTRURI = $DTRURI"
    Write-Host "SWARMMGRIP = $SWARMMGRIP"

    Write-Host "Install additional Keyboards"
    Install-Keyboards

    Write-Host "Upgrading Docker Engine"
    Install-LatestDockerEngine

    Write-Host "Join the Swarm cluster"
    Join-Swarm

    Write-Host "Customize the user desktop"
    Customize-User-Desktop

    Stop-Transcript
}
catch
{
    Write-Error $_
}
