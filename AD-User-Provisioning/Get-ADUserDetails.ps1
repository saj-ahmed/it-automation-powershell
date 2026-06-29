<#
.SYNOPSIS
Retrieves Active Directory user details.

.DESCRIPTION
This script queries Active Directory for a specified user and returns
key account information such as display name, email, account status,
last logon (where available), and group membership.

Useful for service desk troubleshooting, onboarding checks, and general
user account investigations.

.NOTES
Author: Saj Ahmed
Repository: IT Automation PowerShell
Requirements:
- Active Directory PowerShell Module
- Read permissions on Active Directory objects

#>

Import-Module ActiveDirectory -ErrorAction Stop

$Users = Import-Csv ".\Users.csv"
$Results = @()

foreach ($User in $Users) {

    $SamAccountName = $User.Username

    Write-Host "Retrieving details for: $SamAccountName" -ForegroundColor Cyan

    try {

        $ADUser = Get-ADUser -Identity $SamAccountName -Properties *

        if (-not $ADUser) {
            Write-Warning "User not found: $SamAccountName"

            $Results += [PSCustomObject]@{
                User   = $SamAccountName
                Status = "Not Found"
            }

            continue
        }

        $UserGroups = Get-ADPrincipalGroupMembership $ADUser |
                      Select-Object -ExpandProperty Name

        $Results += [PSCustomObject]@{
            Username        = $ADUser.SamAccountName
            DisplayName     = $ADUser.Name
            Email           = $ADUser.EmailAddress
            Enabled         = $ADUser.Enabled
            LastLogonDate   = $ADUser.LastLogonDate
            Groups          = ($UserGroups -join ", ")
            Status          = "Retrieved"
        }

        Write-Host "Retrieved: $SamAccountName" -ForegroundColor Green

    }
    catch {

        Write-Warning "Failed to retrieve user: $SamAccountName"

        $Results += [PSCustomObject]@{
            User   = $SamAccountName
            Status = "Failed"
        }

        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Lookup complete." -ForegroundColor Green
Write-Host ""

$Results | Format-Table -AutoSize
