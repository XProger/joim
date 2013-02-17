cd H:\Projects\joim\src

del /s *.~*
del /s *.dcu
del /s *.dsk
del /s *.dsm
del /s *.rsm
del /s *.ddp
del /s *.o
del /s *.a
del /s *.s
del /s *.ppu
del /s *.bak
del /s *.tmp

fpc joim.dpr -Mdelphi -Rintel -WG -B -O3 -XX -FCtmp -FUtmp -Fu..\ -o..\joim_FPC.exe 
pause