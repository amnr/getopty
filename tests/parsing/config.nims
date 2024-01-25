# switch "define", "nimPreviewSlimSystem"
switch "define", "nimUnittestColor=on"

switch "path", "$projectDir/../../src"

patchFile "stdlib", "cmdline", "patches/cmdline"
patchFile "stdlib", "os", "patches/cmdline"
