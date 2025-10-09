# Smoke test for inline-plantuml filter
# Runs Quarto render with INLINE_PLANTUML_DEBUG=1 and checks for the dump file.
$env:INLINE_PLANTUML_DEBUG = '1'
try {
    Write-Host "Running: quarto render tests/test-inline-plantuml.qmd --to html --log-level debug"
    quarto render tests/test-inline-plantuml.qmd --to html --log-level debug
    $dump = Join-Path -Path (Get-Location) -ChildPath ".quarto/inline-plantuml-dump-FINDME.puml"
    if (Test-Path $dump) {
        Write-Host "FOUND DUMP: $dump"
        Get-Content $dump -TotalCount 40 | ForEach-Object { Write-Host $_ }
        exit 0
    } else {
        Write-Host "DUMP NOT FOUND: $dump" -ForegroundColor Red
        exit 2
    }
} finally {
    Remove-Item Env:\INLINE_PLANTUML_DEBUG -ErrorAction SilentlyContinue
}
