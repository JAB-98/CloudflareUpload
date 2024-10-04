#Bace uri for cloudflare api
$baceurl = "https://api.cloudflare.com/client/v4/"
#Get auth tocken from args passed in from running script
$Authorization = $args[0]
#Set key here if you want to run as task
#$Authorization = "Bearer "

#clear vars for sript
$Domains = $null
$Zone = $null
#see if auth tocken set
if ($null -eq $Authorization) {
    #wait for user to make sure the auth tocken is corrct
    do {
        Write-Host "Please enter Cloudflare API Code (e.g. Bearer YTS): " -NoNewline
        #get tocken from input
        $Authorization = Read-Host
        write-host "Is this correct '$($Authorization)' (Y/N): " -nonewline
        #check to make sure the user entered correct value
    } while ((Read-Host).ToLower() -ne "y")
}
if ("zones" -notin (Get-ChildItem).name) {
    #make folder for files
    mkdir zones | Out-Null
}
#counter
$i = 1
#start getting all domains in account
do {
    #api call to cloudflare
    $DomainsTemp = Invoke-webrequest -Uri "$($baceurl)zones?page=$($i)" -Method Get -Headers @{"Authorization" = $Authorization } | ConvertFrom-Json
    #if first page set the results to list
    if ($null -eq $Domains) {
        $Domains = $DomainsTemp.result
    }
    else {
        #go through each result and add to esiting list of domains
        foreach ($currentItemName in $DomainsTemp.result) {
            $Domains += $currentItemName
        }
    }
    #incress counter
    $i++
    #see if all api calls are completed
} while ($DomainsTemp.result_info.page -lt $DomainsTemp.result_info.total_pages)
#go through each domain
foreach ($currentItemName in $Domains) {
    #clear zone from last domain
    $zone = $null
    #reset counter for new domain
    $i = 1
    #go through each page of the zone api call
    do {
        #get zone page from cloudflare api
        $ZoneTeamp = Invoke-webrequest -Uri "$($baceurl)zones/$($currentItemName.id)/dns_records?page=$($i)" -Method Get -Headers @{"Authorization" = $Authorization } | ConvertFrom-Json
        #if first page set results to zone list
        if ($null -eq $Zone) {
            $Zone = $ZoneTeamp.result
        }
        #add resst of page to list
        else {
            foreach ($_ in $ZoneTeamp.result) {
                $Zone += $_
            }
        }
        #incress count
        $i++
        #see if there are any pages left
    } while ($ZoneTeamp.result_info.page -lt $ZoneTeamp.result_info.total_pages)
    #zone complete
    Write-Host "$($currentItemName.name) Has exported to zone file" -ForegroundColor Green
    #export to zone file
    $zone | Select-Object name, type, content | ConvertTo-Csv -Delimiter `t -UseQuotes Never -NoHeader | Set-Content -Path "zones\$($currentItemName.name).zone"
    #export to json file
    $zone | ConvertTo-Json | Set-Content -Path "zones\$($currentItemName.name).json"
}
