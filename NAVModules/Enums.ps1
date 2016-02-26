Add-Type -TypeDefinition @"
   // very simple enum type
   public enum UpgradeAction
   {
      Split = 1,
      Merge = 2,
      Join = 3
   }
"@