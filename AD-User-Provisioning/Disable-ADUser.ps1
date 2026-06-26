<#
.SYNOPSIS
Disables an Active Directory user account.

.DESCRIPTION
This script disables one or more Active Directory user accounts.
It can be used for leavers, account suspension, or security incidents.

The script checks if the user exists before attempting to disable the account
and provides feedback on success or failure.

.NOTES
Author: Saj Ahmed
Repository: IT Automation PowerShell
Requirements:
- Active Directory PowerShell Module
- Appropriate permissions to disable AD accounts

#>

Import-Module ActiveDirectory -ErrorAction Stop

$Users = Import-Csv ".\Users.csv"
$Results = @()

foreach ($User in $Users) {

    $SamAccountName = $User.Username

    Write-Host "Processing user: $SamAccountName" -ForegroundColor Cyan

    try {

        $ADUser = Get-ADUser -Identity $SamAccountName -ErrorAction Stop

        if (-not $ADUser) {
            Write-Warning "User not found: $SamAccountName"

            $Results += [PSCustomObject]@{
                User   = $SamAccountName
                Status = "Not Found"
            }

            continue
        }

        Disable-ADAccount -Identity $SamAccountName

        Write-Host "Disabled account: $SamAccountName" -ForegroundColor Green

        $Results += [PSCustomObject]@{
            User   = $SamAccountName
            Status = "Disabled"
        }

    }
    catch {

        Write-Warning "Failed to disable user: $SamAccountName"

        $Results += [PSCustomObject]@{
            User   = $SamAccountName
            Status = "Failed"
        }

        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Operation complete." -ForegroundColor Green
Write-Host ""

$Results | Format-Table -AutoSize
