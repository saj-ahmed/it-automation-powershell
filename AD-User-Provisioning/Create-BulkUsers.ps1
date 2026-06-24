<#
.SYNOPSIS
Creates Active Directory user accounts in bulk from a CSV file.

.DESCRIPTION
This script imports user details from a CSV file and creates new Active
Directory accounts using the supplied information. It performs a check
to ensure the account does not already exist before attempting creation.

Designed for service desk, infrastructure and onboarding workflows where
multiple user accounts need to be provisioned quickly and consistently.

.NOTES
Author: Saj Ahmed
Repository: IT Automation PowerShell
Requirements:
- Active Directory PowerShell Module
- Appropriate permissions to create users in AD
- CSV file containing user account information

Example CSV format:

FirstName,LastName,Username,Password,OU
John,Smith,j.smith,P@ssw0rd123,"OU=Users,DC=company,DC=local"
#>

Import-Module ActiveDirectory -ErrorAction Stop

$CsvPath = ".\Users.csv"
$Results = @()

if (-not (Test-Path $CsvPath)) {
    Write-Error "CSV file not found: $CsvPath"
    exit
}

$Users = Import-Csv $CsvPath

foreach ($User in $Users) {

    $DisplayName = "$($User.FirstName) $($User.LastName)"
    $SamAccountName = $User.Username

    Write-Host "Processing user: $DisplayName" -ForegroundColor Cyan

    try {

        $ExistingUser = Get-ADUser `
            -Filter "SamAccountName -eq '$SamAccountName'" `
            -ErrorAction SilentlyContinue

        if ($ExistingUser) {

            Write-Warning "User already exists: $SamAccountName"

            $Results += [PSCustomObject]@{
                User   = $DisplayName
                Status = "Already Exists"
            }

            continue
        }

        $SecurePassword = ConvertTo-SecureString `
            $User.Password `
            -AsPlainText `
            -Force

        New-ADUser `
            -Name $DisplayName `
            -GivenName $User.FirstName `
            -Surname $User.LastName `
            -DisplayName $DisplayName `
            -SamAccountName $SamAccountName `
            -UserPrincipalName "$SamAccountName@company.local" `
            -Path $User.OU `
            -AccountPassword $SecurePassword `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Host "Successfully created: $DisplayName" -ForegroundColor Green

        $Results += [PSCustomObject]@{
            User   = $DisplayName
            Status = "Created"
        }
    }
    catch {

        Write-Warning "Failed to create user: $DisplayName"

        $Results += [PSCustomObject]@{
            User   = $DisplayName
            Status = "Failed"
        }

        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Provisioning complete." -ForegroundColor Green
Write-Host ""

$Results | Format-Table -AutoSize
