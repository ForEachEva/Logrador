$SetPublic = @( Get-ChildItem -Path '.\Logrador\Public\*.ps1' -ErrorAction Stop )
$SetPrivate = @( Get-ChildItem -Path '.\Logrador\Private\*.ps1' -ErrorAction Stop )

#Dot source the files
Foreach($import in @($SetPublic + $SetPrivate))
{
    Try
    {
        . $import.FullName
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}
Export-ModuleMember -Function $SetPublic.Basename
