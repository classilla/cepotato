1 rem ***********************
2 rem *                     *
3 rem *    computereyes     *
4 rem *   executive v1.2    *
5 rem *                     *
6 rem *   copyright 1984    *
7 rem * digital vision inc. *
8 rem *                     *
9 rem ***********************
10 :
11 rem revision history:
12 rem   1.0 original          9/84
13 rem   1.1 older c64 text    11/84
14 rem       display
15 rem   1.2 fast cat          3/85
30 :
50 if peek(49152) = 76 then 60
55 load "cedriver",8,1
60 if peek(52480) =173 then 110
70 load"directory.exe",8,1
110 mf=mf+1
120 on mf goto 140,650,2500,3750
140 nc = 14: dim l$(nc),m$(nc),t$(22)
143 data h,elp,a,djust sync,b,rightness
145 data n,ormal capture,4,-level capture,8,-level capture
146 data v,iew current image,s,ave to disk,l,oad from disk,c,atalog
147 data e,xit,"","",u,npacked,p,acked
150 for i = 1 to nc: read l$(i): read m$(i): next
160 na = 49152
170 g4=na+3:sy=na+6:it=na+9:co=na+12:g8=na+15:ac=na+18:pk=na+21:up=na+24
180 sv=na+27:br=na+30:fo=na+33
200 rem *** main menu ***
205 poke 53281,0: poke 53280,0: poke 646,1
210 for i = 1 to 16: get z$: next
220 mf=1
230 print"{S}      computereyes (tm) executive"
240 printtab(15)"version 1.1"
250 print:print"             copyright 1984"
260 print"           digital vision, inc."
280 print:printtab(10)"select from main menu:":print
290 gosub 900
310 if z<1 or z>nc-2 then 200
320 on z goto 500,1000,1200,1500,2000,2200,2500,3000,3500,4000,4500
350 goto 200
500 rem *** help ***
510 print"{S}    computereyes on-line assistance"
540 print
550 printtab(10)"select from help menu:":print
560 printtab(10)"(return for main menu)":print
590 gosub 900
600 if z<1 or z>nc-2 then 200
610 print"{Sqqqqqqqqqqqqqqqqqqqqqq}":mf=1:sys fo
620 load "help."+l$(z),8,1
650 gosub 19400: goto 500
900 rem menu common subroutine
910 for i = 1 to 6
920 print"   {r}"l$(i)"{R}"m$(i);
930 printtab(19)"{r}"l$(i+6)"{R}"m$(i+6)
940 next: print: printtab(10)"selection";:gosub19500
990 print: return
1000 rem *** sync ***
1010 print"adjust sync control in direction"
1020 print"displayed at the bottom of the screen"
1030 print"until 'in sync' is displayed."
1040 print:print"type any key to continue ..."
1060 sys sy
1090 goto200
1200 rem *** brightness ***
1210 sys br
1220 goto 1530
1500 rem *** normal capture ***
1520 sys na
1530 get z$: if z$ = "" then 1530
1540 poke 53272,peek(53272) and 247
1550 poke 53265, peek(53265) and 223
1590 goto200
2000 rem *** four-level capture ***
2020 sys g4
2040 goto1530
2200 rem *** eight-level capture ***
2220 sys g8
2240 goto1530
2500 rem *** view current image ***
2505 sys co
2510 poke 53272,peek(53272) or 8
2520 poke 53265,peek(53265) or 32
2530 goto 1530
3000 rem *** save ***
3010 gosub 3300
3015 if f$ = "" then 200
3017 if pf=2 then f$ = "pac."+f$
3020 f$ = "@0:"+f$
3030 open 15,8,15,"i0"
3040 open 8,8,8,f$+",p,w"
3050 gosub 19700: if z=1 then 3190
3060 close 8: close 15
3080 on pf goto 3100,3200,3800
3090 goto200
3100 gosub 3950
3110 sys 65496
3180 open 15,8,15,"i0":gosub 19700
3190 close 8: close 15: goto 200
3200 sys pk
3210 gosub 3950
3215 z = peek(253) + 1 + peek(254)*256
3220 poke 782,z/256: poke 781,z-256*peek(782)
3230 poke 252,64
3240 sys 65496
3290 goto 3180
3300 rem save/load common
3305 f$ = ""
3310 print"{r}p{R}acked  -or-  {r}u{R}npacked";
3320 gosub19500:pf = z-nc+2:if pf<>1 and pf<>2 then return
3330 input"file name";f$
3340 if f$ = "?" then f$ = "": gosub 4010: print: goto 3330
3390 return
3500 rem *** load ***
3510 pf = 0: gosub 3300
3515 if f$ = "" then 200
3517 if pf=2 then f$ = "pac."+f$
3520 open 15,8,15,"i0"
3530 open 8,8,8,f$+",p,r"
3540 gosub 19700: if z=1 then 3190
3580 on pf goto 3600,3700
3590 goto 200
3600 gosub 3950
3610 poke 780,0: poke 781,0: poke 782,32: sys 65493
3650 gosub 19700: close 8: close 15
3660 if z=1 then 200
3690 goto 2500
3700 gosub 3950
3710 poke 780,0: poke 781,0: poke 782,64: sys 65493
3750 sys up
3790 goto 3650
3950 for i = 1 to len(f$): poke 52991+i,asc(mid$(f$,i,1)): next: poke i,0
3960 poke 780,8: poke 781,8: poke 782,0: sys 65466
3970 poke 780,len(f$): poke 781,0: poke 782,207: sys 65469
3980 poke 251,0: poke 252,32: poke 780,251: poke 781,64: poke 782,63
3990 return
4000 rem *** catalog ***
4005 gosub 4010: goto 200
4010 print"{S}";:poke830,asc("p"):sys52480:gosub19400:return
4500 rem *** exit ***
4510 print"{S}type {r}run{R} to re-enter the executive."
4520 poke 49152,0
4590 end
19400 print:print"type any key to continue";
19410 gosub 19600
19420 print" ": return
19500 rem get selection by letter
19510 gosub 19600
19520 for i = 1 to nc: if z$ = l$(i) then z = i: printz$m$(i): return
19550 next: z = 0: return
19600 print": ";: poke 204,0
19610 get z$: poke 207,0: if z$ = "" then 19610
19620 poke 204,1: return
19700 input#15,en,er$,tr,se
19710 z=0:if en=0 then return
19720 z=1: print: printer$".{g}": goto 19400
