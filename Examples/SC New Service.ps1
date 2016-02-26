sc.exe delete "MicrosoftDynamicsNAVServer$ITW2009"

sc.exe \\JALW8 create MicrosoftDynamicsNAVServer$ITW2009 binpath= "C:\Program Files (x86)\Microsoft Dynamics NAV\60\Service ITW\Microsoft.Dynamics.Nav.Server.exe $ITW2009" DisplayName= "Microsoft Dynamics NAV Server ITW2009" start= auto type= own obj= "si-data\sql"


