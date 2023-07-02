.DEFAULT: vdc320

.PHONY: vdc320 clean run

vdc320: vdctest.o vdcbmp.2000
	../tools/linkb --ofile=vdc320 vdctest.o vdcbmp.2000

%.o: %.asm
	xa -o $@ -l $*.sym $<

clean:
	rm -f vdc320 *.o *.sym

run: vdc320
	curl -T vdc320 ftp://bil/Temp/vdc320.prg
