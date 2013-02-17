FPC     = fpc
FPC_MAC = /usr/local/lib/fpc/2.4.0/ppc386
FLAGS   = -Mdelphi -O3 -XX -CX -Rintel -WG
INCLUDE = 
OUTPUT  = ./
DESTDIR = /usr
TMP     = -FUtmp
TARGET  = ../joim.elf
TARGETW = ../joim_FPC.exe
TARGETM = ./../joim.app/Contents/MacOS/joim

clean:	
	rm -f tmp/*.p
	rm -f tmp/*.s
	rm -f tmp/*.ppu
	rm -f tmp/*.o
	rm -f tmp/*.a
	
clean_mac:	
	
nix:	clean
	$(FPC) joim.dpr $(INCLUDE) -FE$(OUTPUT) $(TMP) $(FLAGS) -o$(TARGET) -TLINUX
	strip $(OUTPUT)$(TARGET) --strip-unneeded -R .comment -R .note

mac:	clean_mac
	$(FPC) joim.dpr $(INCLUDE) -FE$(OUTPUT) $(TMP) $(FLAGS) -o$(TARGETM) -TDARWIN
	strip $(OUTPUT)$(TARGETM)	

win:	clean
	$(FPC) joim.dpr $(INCLUDE) $(TMP) $(FLAGS) -o$(TARGETW) -TWIN32 -dDEBUG
	
