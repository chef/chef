SETLOCAL

> wget.vbs (
echo.url = WScript.Arguments.Named^("url"^)
echo.path = WScript.Arguments.Named^("path"^)
echo.proxy = null
echo.Set objXMLHTTP = CreateObject^("MSXML2.ServerXMLHTTP"^)
echo.Set wshShell = CreateObject^( "WScript.Shell" ^)
echo.Set objUserVariables = wshShell.Environment^("USER"^)
echo.
echo.'http proxy is optional
echo.'attempt to read from HTTP_PROXY env var first
echo.On Error Resume Next
echo.
echo.If NOT ^(objUserVariables^("HTTP_PROXY"^) = ""^) Then
echo.proxy = objUserVariables^("HTTP_PROXY"^)
echo.
echo.'fall back to named arg
echo.ElseIf NOT ^(WScript.Arguments.Named^("proxy"^) = ""^) Then
echo.proxy = WScript.Arguments.Named^("proxy"^)
echo.End If
echo.
echo.If NOT isNull^(proxy^) Then
echo.'setProxy method is only available on ServerXMLHTTP 6.0+
echo.Set objXMLHTTP = CreateObject^("MSXML2.ServerXMLHTTP.6.0"^)
echo.objXMLHTTP.setProxy 2, proxy
echo.End If
echo.
echo.On Error Goto 0
echo.
echo.objXMLHTTP.open "GET", url, false
echo.objXMLHTTP.send^(^)
echo.If objXMLHTTP.Status = 200 Then
echo.Set objADOStream = CreateObject^("ADODB.Stream"^)
echo.objADOStream.Open
echo.objADOStream.Type = 1
echo.objADOStream.Write objXMLHTTP.ResponseBody
echo.objADOStream.Position = 0
echo.Set objFSO = Createobject^("Scripting.FileSystemObject"^)
echo.If objFSO.Fileexists^(path^) Then objFSO.DeleteFile path
echo.Set objFSO = Nothing
echo.objADOStream.SaveToFile path
echo.objADOStream.Close
echo.Set objADOStream = Nothing
echo.End if
echo.Set objXMLHTTP = Nothing
)

rem # XXX: uninstall any left over version, ignore errors
call msiexec /qb /x %TMP%\install.msi

rem # remove the chef package / clobber the files
rmdir /S /Q C:\opscode

rem # remove the old installer, if it exists, ignore errors
del /F /Q %TMP%\install.msi

rem # sleep until omnitruck has updated itself
powershell -command "start-sleep %SLEEP_TIME%"

rem # download the new chef installer
rem # right now we have one build, fake the platform resulution crap
cscript /nologo wget.vbs /url:"http://%OMNITRUCK_BASE_URL%/chef/download?p=windows&pv=2008r2&m=x86_64&v=%INSTALL_CHEF_VERSION%" /path:%TMP%\install.msi


call msiexec INSTALLLOCATION=C:\opscode /qb /i %TMP%\install.msi || GOTO :error

call C:\opscode\chef\bin\chef-client --version || GOTO :error

call msiexec /qb /x %TMP%\install.msi || GOTO :error

GOTO :EOF

:error

SET ERR_LEV=%errorlevel%

ECHO Failed with error level %ERR_LEV%

call msiexec /qb /x %TMP%\install.msi

EXIT /B %ERR_LEV%

ENDLOCAL
