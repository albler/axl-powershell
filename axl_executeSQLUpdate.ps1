[CmdletBinding()]param (
   [Parameter(Mandatory=$true)][string]$axlhost,
   [Parameter(Mandatory=$true)][string]$user,
   [Parameter(Mandatory=$true)][String]$password,
   [Parameter(Mandatory=$true)][String]$number,
   [Parameter(Mandatory=$true)][AllowEmptyString()][String]$destination
)
. .\include\xml_pretty_print.ps1
. .\include\output_error.ps1

# To skip checking AXL SSL certificate, uncomment the below block.
#     Otherwise to verify a self-signed CUCM certificate, download
#     the CUCM Tomcat certificate in .der format and install into the 
#     Trusted Root Certificates store using certlm
. .\include\trust_all_policy.ps1

# The elements below 

$body = @'
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://www.cisco.com/AXL/API/14.0">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:executeSQLUpdate sequence="1">
         <sql>update callforwarddynamic set cfadestination='{0}' where fknumplan=(Select pkid from numplan where dnorpattern='{1}')</sql>
      </ns:executeSQLUpdate>
   </soapenv:Body>
</soapenv:Envelope>
'@ -f $destination, $number

$url = "https://"+$axlhost+":8443/axl/"
$pass = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object Management.Automation.PSCredential ($user, $pass)
$headers = @{
   'SOAPAction' = '"CUCM:DB ver=14.0 executeSQLUpdate"'
   'Content-Type' = 'text/xml'
}

try {
   $Result = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Credential $cred -Body $body
}
catch {
   Write-Host "`r`n<ExecuteSQLUpdate>: FAILED"
   output_error
   Exit
}

$xml = Format-XML($result)

Write-Host "`r`n<ExecuteSQLUpdate>: SUCCESS`r`nResponse:"
Write-Host $xml+"`r`n"