@echo off
set PATH=C:\MFS\cc65\bin;%PATH%
ca65 src\main.asm -I src -l listing.txt -o main.o -g || goto end
ld65 -C pacman.cfg -o pacman.nes -m map.txt -vm main.o --dbgfile pacman.nes.dbg
:end
pause
