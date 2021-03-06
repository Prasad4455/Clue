param([string] $Force = 'false')
# This code is Copyright (c) 2016 Microsoft Corporation.
#
# All rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
#  INCLUDING BUT NOT LIMITED To THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
#  PARTICULAR PURPOSE.'
#
# IN NO EVENT SHALL MICROSOFT AND/OR ITS RESPECTIVE SUPPLIERS BE LIABLE FOR ANY SPECIAL, INDIRECT OR 
#  CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
#  WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION 
#  WITH THE USE OR PERFORMANCE OF THIS CODE OR INFORMATION.

$Error.Clear()
Remove-Module * -Force
Import-Module .\Modules\General.psm1 -Force
Import-Module .\Modules\Xml.psm1 -Force
Import-Module .\Modules\FileSystem.psm1 -Force
Import-Module .\Modules\TaskScheduler.psm1 -Force

[string] $Log = '.\Test-UserInitiated.log'

[bool] $Force = [System.Convert]::ToBoolean($Force)
Write-Log ('[Test-UserInitiated] Start') -Log $Log
[string] $sTextFilePath = $(Get-Content env:PUBLIC) + '\Documents\ClueUserInitiated.txt'
Write-Log ('[Test-UserInitiated] sTextFilePath: ' + $sTextFilePath) -Log $Log

if ($Force -eq $true)
{
    Write-Log ('[Test-UserInitiated] Forced!') -Log $Log
    Start-Ps2ScheduledTask -ScheduledTaskFolderPath '\Microsoft\Windows\Clue' -TaskName 'Invoke-Rule' -Arguments '-RuleName UserInitiated' -Log $Log
    Test-Error -Err $Error -Log $Log
    Exit;
}

[string] $DesktopBatchFile = $(Get-Content env:PUBLIC) + '\Desktop\ClueUserInitiated.bat'
Write-Log ('Desktop batch file: ' + $DesktopBatchFile) -Log $Log
Add-content -Path $DesktopBatchFile -value ('@echo off') -Encoding Ascii
Add-content -Path $DesktopBatchFile -value ('echo UserInitiated >> ' + $sTextFilePath) -Encoding Ascii
Add-content -Path $DesktopBatchFile -value ('echo =========== USER INITIATED ===================') -Encoding Ascii
Add-content -Path $DesktopBatchFile -value ('echo This may take a minute or two...') -Encoding Ascii
Add-content -Path $DesktopBatchFile -value ('echo You may close this command prompt at any time.') -Encoding Ascii
Add-content -Path $DesktopBatchFile -value ('echo ==============================================') -Encoding Ascii
Add-content -Path $DesktopBatchFile -value ('pause') -Encoding Ascii

[bool] $IsModified = $false

#///////////
#// Main //
#/////////

Start-TruncateLog -FilePath $Log -Log $Log
[datetime] $dtLastLogTruncate = (Get-Date)

New-Item -Path $sTextFilePath -ItemType File
'' > $sTextFilePath
Test-Error -Err $Error -Log $Log
Write-Log ('[Test-UserInitiated] Cleared the ClueUserInitiated.txt file.') -Log $Log
Write-Log ('[Test-UserInitiated] Starting infinite loop.') -Log $Log

Do
{
    if ((Test-Path -Path $sTextFilePath) -eq $false)
    {
        '' > $sTextFilePath
        Write-Log ('[Test-UserInitiated] UserInitiated file created: ' + $sTextFilePath) -Log $Log
        Test-Error -Err $Error -Log $Log
    }

    if (Test-Path -Path $sTextFilePath)
    {
        if ((Get-Content -Path $sTextFilePath) -ne '')
        {
            Write-Log ('[Test-UserInitiated] Start-Ps2ScheduledTask: Start') -Log $Log
            Start-Ps2ScheduledTask -ScheduledTaskFolderPath '\Microsoft\Windows\Clue' -TaskName 'Invoke-Rule' -Arguments '-RuleName Test-UserInitiated' -Log $Log
            Write-Log ('[Test-UserInitiated] Start-Ps2ScheduledTask: End') -Log $Log
            Test-Error -Err $Error -Log $Log
            '' > $sTextFilePath
            Test-Error -Err $Error -Log $Log
        }
    }

    [int] $RandomMinutes = Get-Random -Minimum 100 -Maximum 200
    if ((New-TimeSpan -Start $dtLastLogTruncate -End (Get-Date)).TotalMinutes -gt $RandomMinutes)
    {
        Write-Log ('[Start-TruncateLog]') -Log $Log
        Start-TruncateLog -FilePath $Log
        [datetime] $dtLastLogTruncate = (Get-Date)
    }

    Start-Sleep -Seconds 3
} until ($true -eq $false)