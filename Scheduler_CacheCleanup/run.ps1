using namespace System.Net

param($Timer)

# Remove orphaned cache files
if (Test-Path .\Cache_DomainHealth) {
    Get-ChildItem .\Cache_DomainHealth | ForEach-Object {
        if ($_.CreationTime -le (Get-Date).AddMinutes(-10)) {
            $_ | Remove-Item -Force
        }
    }
}