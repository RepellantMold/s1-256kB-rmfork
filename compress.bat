rem compress kosinski files
for %%f in ("256x256 Mappings\*.unc") do koscmp "%%f" "256x256 Mappings\%%~nf.kos"
for %%f in ("kosdata\*.unc") do koscmp "%%f" "kosdata\%%~nf.kos"
for %%f in ("Graphics - Compressed\Decompressed\*.bin") do nemcmp "%%f" "Graphics - Compressed\%%~nf.nem"
for %%f in ("16x16 Mappings\*.bin") do enicmp "%%f" "16x16 Mappings\%%~nf.eni"
for %%f in ("Tilemaps\*.bin") do enicmp "%%f" "Tilemaps\%%~nf.eni"
for %%f in ("Special Stage Layouts\*.unc") do koscmp "%%f" "Special Stage Layouts\%%~nf.kos"