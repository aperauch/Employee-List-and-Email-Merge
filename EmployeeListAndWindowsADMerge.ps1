Import-module ActiveDirectory

#Insert Variables
$csvFileToImport = "Employee List.csv"

#Get all names and email addresses for accounts that are enabled and in the LDAP string.
$ADUsers = get-aduser -Filter {Enabled -eq "True"} -SearchBase "CN=Users,DC=sub-domainexamle,DC=domainexample,DC=com" -Properties name, displayname, mail, CN | Select GivenName, Surname, mail

#Define hash-table variable to store firstname plus lastname and email address as key-value pairs.
$mailNamePairs = @{}

foreach ($user in $ADUsers) {
    if (![string]::IsNullOrEmpty($user.mail) -and ![string]::IsNullOrWhiteSpace($user.mail)) {
        if(![string]::IsNullOrEmpty($user.GivenName) -and ![string]::IsNullOrWhiteSpace($user.GivenName) -and ![string]::IsNullOrEmpty($user.Surname) -and ![string]::IsNullOrWhiteSpace($user.Surname)) {
            $key = $user.GivenName + " " + $user.Surname
            $value = $user.mail

            if ($mailNamePairs.ContainsKey($key)) {
                Write-Host "Key exists already: $key"
            }
            else {
                $mailNamePairs.Add($key, $value)
            }
        }
    }  
}

#Import the given CSV file containg employee names.
$CSVUsers = Import-Csv $csvFileToImport

#Merge first and last name into a single string and add to array variable
$employeeNames = @()
foreach ($obj in $CSVUsers) {
    $employeeNames += $obj.FirstName + " " + $obj.LastName
}

#Match employee names taken from AD with employee names listed in a CSV file.  
$matched = @{}
$unmatched = @()
foreach ($name in $employeeNames) {
        if ($mailNamePairs.ContainsKey($name)) {
            $matched.Add($name,$mailNamePairs[$name])
            $mailNamePairs.Remove($name)
        }
        else {
            $unmatched += $name
        }
}

Write-Host "***************Matched******************"

$matched.GetEnumerator() | Sort-Object Name

Write-Host "***************Unmatched From CSV******************"

$unmatched | Sort-Object

Write-Host "***************Unmatched From AD******************"

$mailNamePairs.GetEnumerator() | Sort-Object Value
