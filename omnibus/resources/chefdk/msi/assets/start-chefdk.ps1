Try {
    $conemulocation = "$env:programfiles\ConEmu\Conemu64.exe"
    # We don't want the current path to affect which "chef shell-init powershell" we run, so we need to set the PATH to include the current omnibus.
    $chefdk_bin = (split-path $MyInvocation.MyCommand.Definition -Parent)
    $chefdkinit = '"$env:PATH = ''' + $chefdk_bin + ';'' + $env:PATH; $env:CHEFDK_ENV_FIX = 1; chef shell-init powershell | out-string | iex; Import-Module chef -DisableNameChecking"'
    $chefdkgreeting = "echo 'PowerShell $($PSVersionTable.psversion.tostring()) ($([System.Environment]::OSVersion.VersionString))';write-host -foregroundcolor darkyellow 'Ohai, welcome to ChefDK!`n'"
    $chefdkcommand = "$chefdkinit;$chefdkgreeting"
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    $titleprefix = ""
    if($principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        $titleprefix = "Administrator: "
    }

    $chefdktitle = "$($titleprefix)ChefDK ($env:username)"

    if ( test-path $conemulocation )
    {
        start-process $conemulocation -argumentlist '/title',"`"$chefdktitle`"",'/cmd','powershell.exe','-noexit','-command',$chefdkcommand
    }
    else
    {
        start-process powershell.exe -argumentlist '-noexit','-command',"$chefdkcommand; (get-host).ui.rawui.windowtitle = '$chefdktitle'"
    }
}
Catch
{
    sleep 10
    Throw
}
