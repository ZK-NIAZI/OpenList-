# Fix Isar namespace issue
$isarPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0+1\android\build.gradle"

Write-Host "Fixing Isar namespace issue..." -ForegroundColor Yellow

if (Test-Path $isarPath) {
    Write-Host "Found Isar build.gradle at: $isarPath" -ForegroundColor Green
    
    # Read current content
    $content = Get-Content $isarPath -Raw
    
    # Check if namespace already exists
    if ($content -match "namespace") {
        Write-Host "✅ Namespace already exists!" -ForegroundColor Green
        exit 0
    }
    
    # Backup original file
    Copy-Item $isarPath "$isarPath.backup" -Force
    Write-Host "Created backup at: $isarPath.backup" -ForegroundColor Cyan
    
    # Find the android block and add namespace
    if ($content -match "android\s*\{") {
        # Add namespace right after "android {"
        $newContent = $content -replace "(android\s*\{)", "`$1`n    namespace 'dev.isar.isar_flutter_libs'"
        Set-Content $isarPath $newContent -NoNewline
        Write-Host "✅ Fixed! Namespace added to Isar build.gradle" -ForegroundColor Green
    } else {
        Write-Host "❌ Could not find android block in build.gradle" -ForegroundColor Red
        Write-Host "Please manually add this at the top of the android block:" -ForegroundColor Yellow
        Write-Host "    namespace 'dev.isar.isar_flutter_libs'" -ForegroundColor White
    }
} else {
    Write-Host "❌ Isar build.gradle not found at: $isarPath" -ForegroundColor Red
    Write-Host "Please check if the path exists" -ForegroundColor Yellow
}

Write-Host "`nNow run: flutter run" -ForegroundColor Cyan
