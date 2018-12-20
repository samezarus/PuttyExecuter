clear

# Скрипт(powershell) для пакетного выполнения скрипта(sh) через putty.exe на NIX-машинах

$UserName = 'root'
$Password = 'xxxxxx'
$SshPort  = '22'

$IpFile = $PSScriptRoot + '\ip.txt'
$putty  = $PSScriptRoot + '\putty.exe'
$script = $PSScriptRoot + '\script.sh'

$DialogForm = 'PuTTY Security Alert'

$signature = @" 
[DllImport("user32.dll", EntryPoint="FindWindow", SetLastError = true)] 
public static extern IntPtr FindWindowByCaption(IntPtr ZeroOnly, string lpWindowName); 
[DllImport("user32.dll", SetLastError=true)] 
[return: MarshalAs(UnmanagedType.Bool)] 
public static extern bool SetForegroundWindow(IntPtr hWnd); 
"@ 

$Window    = Add-Type -memberDefinition $signature -name 'Window' -namespace Win32Functions -passThru 
$comobject = New-Object -com wscript.shell 



# ---------------------------------------------

$IpList = Get-Content -Path $IpFile    
foreach ($ip in $IpList)
{
    if ((Test-Connection -computer $ip -quiet) -eq $True)
    {
        'Хост "'+$ip+'" в сети'
        $t = New-Object Net.Sockets.TcpClient
        $t.Connect($ip, $SshPort)
        if($t.Connected)
        {
            'Доступен порт: '+$SshPort  
            & $putty $UserName@$ip $SshPort -pw $Password -m $script

            $hwd = $Window::FindWindowByCaption([IntPtr]::Zero, $DialogForm) 
            if ($hwd -and $hwd -ne 0) # Ищем диалоговое окно, если putty просит обновить сертификат
            { 
                $Window::SetForegroundWindow($hwd) 
                $hwd
                $comobject.SendKeys('{Tab}')
                $comobject.SendKeys('{Enter}')  
            }  

            'Скрип выполне'
        }
        else
        {
            'Не доступен порт: '+$SshPort
        }
    }
    else
    {
        'Хост "'+$ip+'" не в сети'
    }
    '-------------------------------'
} 
