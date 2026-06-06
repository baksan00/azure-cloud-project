using namespace System.Net

param($Request, $TriggerMetadata)

$body = @{
    message = "Function App sample response"
    source  = "Azure Function HTTP trigger"
    status  = "OK"
} | ConvertTo-Json

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
    Headers = @{
        "Content-Type" = "application/json"
    }
})