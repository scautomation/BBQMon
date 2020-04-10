# Replace with your Workspace ID
$CustomerId = ""  


# Replace with your Primary Key
$SharedKey = ""


# Specify the name of the record type that you'll be creating
$LogType = "BBQ"




$bbq1 = Import-Csv -path C:\temp\bbqnew2.csv

ForEach($bbq in $bbq1){
    $json = convertto-json $bbq
    write-host $bbq

    # Specify a field with the created time for the records
$TimeStampField = get-date
$TimeStampField = $TimeStampField.GetDateTimeFormats(115)
    
# Submit the data to the API endpoint
Send-OMSAPIIngestionFile -customerId $customerId -sharedKey $SharedKey -body $json -logType $LogType -TimeStampField $TimeStampField

start-sleep -Seconds 60
}