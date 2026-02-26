# Fix Isar namespace issue
$isarPath = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev\isar_flutter_libs-3.1.0\android\build.gradle"

if (Test-Path $isarPath) {
    $content = Get-Content $isarPath -Raw
    
    if ($content -notmatch "namespace") {
        # Add namespace after "android {"
        $content = $content -replace "(android\s*\{)", "`$1`n    namespace 'dev.isar.isar_flutter_libs'"
        Set-Content $isarPath $content
        Write-Host "✅ Fixed Isar namespace issue!"
    } else {
        Write-Host "✅ Isar namespace already fixed!"
    }
} else {
    Write-Host "❌ Isar package not found. Run 'flutter pub get' first."
}
