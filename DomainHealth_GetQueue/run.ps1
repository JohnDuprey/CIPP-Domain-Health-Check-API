param($name)

$Items = (Get-ChildItem '.\Cache_DomainHealthQueue\*.json').Name

if (($Items | Measure-Object).Count -gt 0) {
    $Items
}
else { $false }