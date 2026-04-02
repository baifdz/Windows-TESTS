$searcher = [adsisearcher]"(displayName=*)" 
$searcher.Filter = "(&(objectCategory=person)(objectClass=user))"
$searcher.FindAll() | Select-Object @{N='User';E={$_.Properties.samaccountname}}
