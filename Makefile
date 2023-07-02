.DEFAULT: all

.PHONY: ced vdcfast vdcslow clean run all

all: vdcfast vdcslow ced

vdcfast: ced.o fastvdc320.o
	tools/linkb --ofile=vdcfast fastvdc320.o ced.o

vdcslow: ced.o vdc320.o
	tools/linkb --ofile=vdcslow vdc320.o ced.o

ced: ced.o dir.o xec.tok
	tools/linkb --ofile=ced xec.tok ced.o dir.o

xec.tok: xec.bas
	tools/bt --ofile=$@ $<

fastvdc320.o: vdc320.asm
	xa -o $@ -l $*.sym -DFAST=1 -O PETSCII $<

%.o: %.asm
	xa -o $@ -l $*.sym -O PETSCII $<

clean:
	rm -f *.o *.tok *.sym vdcfast vdcslow ced 
	cd test && make clean

run: all
	curl -T vdcfast ftp://bil/Temp/vdcfast.prg
	curl -T vdcslow ftp://bil/Temp/vdcslow.prg
	curl -T ced ftp://bil/Temp/ced.prg
