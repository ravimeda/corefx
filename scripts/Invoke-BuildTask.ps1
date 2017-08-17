﻿<#
.SYNOPSIS
    Runs the given command.
.PARAMETER Command
    Command to run. String passed as the command should include the arguments.
.PARAMETER RetryCount
    Number of times to retry the command until the command run successfully.
    If not specified, then command is retried a maximum of 5 times. 
.PARAMETER WaitFactor
    A multiplier that determine  the time (seconds) to wait between retries. Wait time is WaitFactor times the retry attempt.
    If not specified, then WaitFactor is 6.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Command,
    [int]$RetryCount=5,
    [int]$WaitFactor=6
)

if ($RetryCount -le 0 -or $WaitFactor -le 0)
{
    Write-Error "RetryCount and WaitFactor have to be greater than 0."
    return
}

Write-Host "Attempting to invoke `"$Command`" with RetryCount $RetryCount and WaitFactor $WaitFactor."
$attempt = 1;
$oldEap = $ErrorActionPreference

do
{
    try
    {
        $ErrorActionPreference = "Stop"
        Invoke-Expression -Command "$Command" -ErrorVariable errVar

        if ([string]::IsNullOrWhiteSpace($errVar))
        {
            Write-Host "Command executed successfully."
            return
        }
    }
    finally
    {
        $ErrorActionPreference = $oldEap;
    }

    $attempt++
    if ($attempt -le $RetryCount)
    {
        $waitTime = $WaitFactor * $attempt
        Write-Host "Waiting for $waitTime seconds before retry. Attempt $attempt of $RetryCount."
        sleep -Seconds ($waitTime)
    }
    else
    {
        Write-Error "Command `"$Command`" failed."
        return $?
    }
} while($true)
