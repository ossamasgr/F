param(
    [Parameter(Mandatory=$true)]
    [string] 
    $User,

    [Parameter(Mandatory=$true)]
    [string] 
    $Password,

    [Parameter(Mandatory=$true)]
    [string] 
    $ComputerName,

    [Parameter(Mandatory=$true)]
    [string] 
    $scripturl
)

$scripturl = 'https://raw.githubusercontent.com/ossamasgr/F/main/script.sh'
$Command = "fetch $scripturl; sh script.sh"
$secpasswd = ConvertTo-SecureString $Password -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential($User, $secpasswd)

echo 'logging...'
$SessionID = New-SSHSession -ComputerName $ComputerName -AcceptKey -Credential $Credentials 
echo 'Exucuting...'
$Query = (Invoke-SshCommand -SSHSession $SessionID  -Command $Command).Output
echo $Query
Remove-SSHSession -Name $SessionID | Out-Null
