$private:TypeDefinition = @{

    # ---------------------------------------------------------------------------
    # Enumeration for the types of databases
    # ---------------------------------------------------------------------------
    DBType          = @'
public enum PsDBType
{
    None,
    ADA,
    MSS,
    ORA,
    SYB
}
'@

}


$Parameters = @{
    Language       = 'CSharp'
    WarningAction  = 'SilentlyContinue'
}
$TypeDefinition.Keys | ForEach-Object {
    [void](Add-Type -TypeDefinition $($TypeDefinition.$_) @Parameters)
}
