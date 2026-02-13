# upload_assets.ps1
# Uploads sprite sheet PNGs to Roblox via Open Cloud Assets API
# Usage: .\scripts\upload_assets.ps1 -ApiKey "your-api-key-here"

param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [string]$CreatorId = "6121847161",
    [string]$CreatorType = "User"
)

$assetsDir = Join-Path $PSScriptRoot "..\assets\images\spritemaps"
$endpoint = "https://apis.roblox.com/assets/v1/assets"

$files = @(
    @{ Path = "redoctopus.png";  DisplayName = "RedOctopus Sprite";  Description = "Red Octopus sprite sheet for Mia Kingtide game" },
    @{ Path = "seahorse.png";    DisplayName = "Seahorse Sprite";    Description = "Seahorse sprite sheet for Mia Kingtide game" },
    @{ Path = "treefish.png";    DisplayName = "Treefish Sprite";    Description = "Treefish sprite sheet for Mia Kingtide game" }
)

$results = @{}

foreach ($file in $files) {
    $filePath = Join-Path $assetsDir $file.Path
    
    if (-not (Test-Path $filePath)) {
        Write-Host "ERROR: File not found: $filePath" -ForegroundColor Red
        continue
    }

    Write-Host "`nUploading $($file.Path)..." -ForegroundColor Cyan

    $requestJson = '{"assetType":"Decal","displayName":"' + $file.DisplayName + '","description":"' + $file.Description + '","creationContext":{"creator":{"userId":"' + $CreatorId + '"}}}'
    
    $tempJson = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempJson, $requestJson)

    try {
        $response = curl.exe -s -X POST $endpoint `
            -H "x-api-key: $ApiKey" `
            -F "request=<$tempJson;type=application/json" `
            -F "fileContent=@$filePath;type=image/png"

        $parsed = $response | ConvertFrom-Json

        if ($parsed.assetId) {
            $assetId = $parsed.assetId
            Write-Host "  SUCCESS: rbxassetid://$assetId" -ForegroundColor Green
            $results[$file.Path] = $assetId
        } elseif ($parsed.path) {
            # Async operation - need to poll
            $operationPath = $parsed.path
            Write-Host "  Operation started: $operationPath" -ForegroundColor Yellow
            Write-Host "  Polling for completion..." -ForegroundColor Yellow
            
            $maxAttempts = 10
            for ($i = 0; $i -lt $maxAttempts; $i++) {
                Start-Sleep -Seconds 3
                $pollResponse = curl.exe -s "https://apis.roblox.com/assets/v1/$operationPath" `
                    -H "x-api-key: $ApiKey"
                $pollParsed = $pollResponse | ConvertFrom-Json
                
                if ($pollParsed.done -eq $true) {
                    if ($pollParsed.response.assetId) {
                        $assetId = $pollParsed.response.assetId
                        Write-Host "  SUCCESS: rbxassetid://$assetId" -ForegroundColor Green
                        $results[$file.Path] = $assetId
                    } else {
                        Write-Host "  Completed but no assetId found:" -ForegroundColor Yellow
                        Write-Host "  $pollResponse" -ForegroundColor Yellow
                        # Try to extract from response
                        if ($pollParsed.response.decalAssetId) {
                            $assetId = $pollParsed.response.decalAssetId
                            Write-Host "  Decal asset ID: rbxassetid://$assetId" -ForegroundColor Green
                            $results[$file.Path] = $assetId
                        }
                    }
                    break
                }
                Write-Host "  Still processing... (attempt $($i+1)/$maxAttempts)" -ForegroundColor Gray
            }
            
            if (-not $results.ContainsKey($file.Path)) {
                Write-Host "  TIMEOUT: Operation did not complete. Check manually." -ForegroundColor Red
                Write-Host "  $pollResponse" -ForegroundColor Gray
            }
        } else {
            Write-Host "  UNEXPECTED RESPONSE:" -ForegroundColor Red
            Write-Host "  $response" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RESULTS SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($results.Count -gt 0) {
    foreach ($key in $results.Keys) {
        Write-Host "$key => rbxassetid://$($results[$key])" -ForegroundColor Green
    }
    
    Write-Host "`nFor CreatureDefinitions / JournalController:" -ForegroundColor Yellow
    if ($results.ContainsKey("redoctopus.png")) { Write-Host "  redoctopus = `"rbxassetid://$($results['redoctopus.png'])`"" }
    if ($results.ContainsKey("seahorse.png"))   { Write-Host "  seahorse   = `"rbxassetid://$($results['seahorse.png'])`"" }
    if ($results.ContainsKey("treefish.png"))   { Write-Host "  treefish   = `"rbxassetid://$($results['treefish.png'])`"" }
} else {
    Write-Host "No assets were successfully uploaded." -ForegroundColor Red
}
