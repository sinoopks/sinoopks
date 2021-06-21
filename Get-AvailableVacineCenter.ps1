<#
The script check and alert with a sound if any vacination centers available for booking.
Compatible with powershell version 5 or above.
might need to run Set-ExecutionPolicy -ExecutionPolicy Bypass incase script execution is blocked by default.
API documentation https://apisetu.gov.in/public/marketplace/api/cowin
Sin 19-06-2021
#> 

Function Play-Sound {
    1..2 | % {
        $PlayWav = New-Object System.Media.SoundPlayer

        $PlayWav.SoundLocation = 'C:\Windows\Media\Alarm01.wav'

        $PlayWav.playsync()
    }
}

Function Get-AvailableVaccineCenter {

    Param(
        [Parameter(Mandatory = $true)]
        [String]
        $State,

        [Parameter(Mandatory = $true)]
        [String]
        $District,

        [Parameter(Mandatory = $true)]
        [String]
        $RetrySeconds,

        [Parameter(Mandatory = $false)]
        [String]
        $Date
    )

    #State and district lookup
    $States = Invoke-WebRequest https://cdn-api.co-vin.in/api/v2/admin/location/states
    $AllStates = ConvertFrom-Json $States.Content | Select -ExpandProperty states
    $StateID = $AllStates | where { $_.state_name -like $State } | select -ExpandProperty state_id

    $Districts = Invoke-WebRequest "https://cdn-api.co-vin.in/api/v2/admin/location/districts/$StateID"
    $AllDistricts = ConvertFrom-Json $Districts.Content | Select -ExpandProperty districts
    $DistrictID = $AllDistricts | where { $_.district_name -like $District } | select -ExpandProperty district_id

    do {
        $tomorrow = (Get-Date).AddDays(1).ToString('dd-MM-yyyy')
        $Districtview = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/findByDistrict?district_id=$DistrictID&date=$tomorrow"

        $Responce = Invoke-WebRequest $Districtview
        if ($Responce.StatusCode -eq 200) {
            $AllCenters = ConvertFrom-Json $Responce.Content | select -ExpandProperty sessions | Where { $_.available_capacity -ne 0 }

            If ($AllCenters.name) {
                $AllCenters | select Name,pincode, available_capacity, min_age_limit, vaccine,fee_type
                
                Play-Sound
            }
            else { Write-Host "No centers available in $District" -ForegroundColor Yellow }
        }
        else {
            Write-Host "Something whent wrong with API call" -ForegroundColor Red

        }

        sleep -Seconds $RetrySeconds

    }while ($stop = 1)

}



Get-AvailableVaccineCenter -State Kerala -District Thrissur -RetrySeconds 30 -Date tomorrow
