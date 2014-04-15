#!/bin/bash

cp ../fsbl/Release/fsbl.elf .
cp ../SDK_Export/hw/system.bit .
#cp ../udp_echo/Release/udp_echo.elf .
cp ../tcp_echo/Release/tcp_echo.elf .

bootgen -image bootimage.bif -o i boot.bin -w on

rm fsbl.elf system.bit tcp_echo.elf #udp_echo.elf 
