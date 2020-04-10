Param(
    # Type of Cook
    [parameter(Mandatory=$true)]
    [ValidateSet('Brisket','Poultry','Porkbutt','PorkRoast','PrimeRib', 'BeefRibs')]
    [string]$type,

    # Name of Cook
    [Parameter(Mandatory=$false)]
    [string]$cookname,

    # Texas Crutch on this cook
    [Parameter(Mandatory=$true)]
    [ValidateSet($false,$true)]
    [boolean]$texascrutch,

    # weight of the meat
    [Parameter(Mandatory=$false)]
    [double]$lbs
)

# Replace with your Workspace ID
$CustomerId = ""  

# Replace with your Primary Key
$SharedKey = ""


# Specify the name of the record type that you'll be creating
$LogType = "BBQ"

write-host "$texascrutch"

#Assign cook, temp, target temp and name
switch ($type) {
      Brisket {
        $pittemp = "225"
        $target = '205'
        $name = "Brisket"
        $type = "brisket"
      }
      Poultry {
        $pittemp = "295"
        $target = '165'
        $name = "Chicken_Turkey"
        $type = "poultry"
      }
      Porkbutt {
        $pittemp = "225"
        $target = '195'
        $name = "Pulled Pork"
        $type = "porkbutt"
      }
      PorkRoast {
        $pittemp = "300"
        $target = '145'
        $name = "Pork Roast"
        $type = "porkroast"
      }
      PrimeRib {
        $pittemp = "225"
        $target = '135'
        $name = "Prime Rib"
        $type = "primerib"
      }
      BeefRibs {
        $pittemp = "245"
        $target = '200'
        $name = "Beef Ribs"
        $type = "beefribs"
      }
}


#set target pit temp and food target temp
$params = @{ COOK_SET = $pittemp; FOOD1_SET = $target; FOOD1_NAME = $name; COOK_NAME = $cookname;}
invoke-webrequest -uri http://10.10.10.30 -Method Post -Body $params

#monitor and post data
Do {
#get current status
$bbqstatus = Invoke-RestMethod -uri http://10.10.10.30/status.xml
$bbqtargets = Invoke-WebRequest -uri http://10.10.10.30

#build search values
$values = @('_cook_set','_food1_set','_food2_set','_food3_set','cook_name')

#get current targets
$bbqtargets = $bbqtargets.InputFields | where-object {$values -contains $_.name} | Select-Object name, id, value

#get current temp status
$status = $bbqstatus.nutcstatus | Select-Object output_percent, timer_curr, cook_temp, food1_temp, food2_temp, food3_temp

#get Pit target temp from HTML output
$pitTargettemp = $bbqtargets | Where-Object{$_.name -eq '_COOK_SET'}
$pitTargettemp = $pitTargettemp.value

#get food 1 target temp from html output
$food1Targettemp = $bbqtargets | Where-Object{$_.name -eq '_FOOD1_SET'}
$food1Targettemp = $food1Targettemp.value

#get food 2 target temp from html output
$cook = $bbqtargets | Where-Object{$_.name -eq 'COOK_NAME'}
$cook = $cook.value


#convert temps to normal
$pittemp = $status.COOK_TEMP/10
$pitfan_output = $status.OUTPUT_PERCENT
$food1temp = $status.food1_temp/10


#build json output

$json = @"
{    
    "lbs": $lbs,
    "Pit Target Temp": $pitTargettemp,
    "Fan % Output": $pitfan_output,
    "Food 1 Target": $food1targettemp,
    "Pit Temp": $pittemp,
    "Food1 Temp": $food1temp,
    "Cook Name": "$cookname",
    "Food Name": "$name",
    "TexasCrutch": "$TexasCrutch",
}
"@

write-host $json

# Specify a field with the created time for the records
$TimeStampField = get-date
$TimeStampField = $TimeStampField.GetDateTimeFormats(115)

write-host $TimeStampField

# Submit the data to the API endpoint
Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $SharedKey -body $json -logType $LogType -TimeStampField $TimeStampField


write-host "starting sleep"
write-host "Food is currently at $food1temp"
write-host "Pit is currently at $pittemp"

start-sleep -Seconds 60

} Until ($food1temp -ge $food1Targettemp)





































