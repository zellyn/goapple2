#!/usr/bin/env bash

DIR1='http://mirrors.apple2.org.za/Apple%20II%20Documentation%20Project/Computers/Apple%20II/Apple%20II/ROM%20Images'
DIR2='http://mirrors.apple2.org.za/Apple%20II%20Documentation%20Project/Computers/Apple%20II/Apple%20II%20plus/ROM%20Images'

rm -f apple2.rom apple2+.rom

D0_2="Apple%20Programmer's%20Aid%20%231%20ROM%20(D000)%20-%20341-0016%20-%202716.bin"
E0_2='Apple%20II%20ROM%20Pages%20E0-E7%20-%20341-0001%20-%20Integer%20BASIC.bin'
E8_2='Apple%20II%20ROM%20Pages%20E8-EF%20-%20341-0002%20-%20Integer%20BASIC.bin'
F0_2='Apple%20II%20ROM%20Pages%20F0-F7%20-%20341-0003%20-%20Integer%20BASIC.bin'
F8_2='Apple%20II%20ROM%20Pages%20F8-FF%20-%20341-0004%20-%20Original%20Monitor.bin'


D0_2P='Apple%20II%20plus%20ROM%20Pages%20D0-D7%20-%20341-0011%20-%20Applesoft%20BASIC.bin'
D8_2P='Apple%20II%20plus%20ROM%20Pages%20D8-DF%20-%20341-0012%20-%20Applesoft%20BASIC.bin'
E0_2P='Apple%20II%20plus%20ROM%20Pages%20E0-E7%20-%20341-0013%20-%20Applesoft%20BASIC.bin'
E8_2P='Apple%20II%20plus%20ROM%20Pages%20E8-EF%20-%20341-0014%20-%20Applesoft%20BASIC.bin'
F0_2P='Apple%20II%20plus%20ROM%20Pages%20F0-F7%20-%20341-0015%20-%20Applesoft%20BASIC.bin'
F8_2P='Apple%20II%20plus%20ROM%20Pages%20F8-FF%20-%20341-0020%20-%20Autostart%20Monitor.bin'

curl $DIR2/$D0_2P > apple2+.rom
curl $DIR2/$D8_2P >> apple2+.rom
curl $DIR2/$E0_2P >> apple2+.rom
curl $DIR2/$E8_2P >> apple2+.rom
curl $DIR2/$F0_2P >> apple2+.rom
curl $DIR2/$F8_2P >> apple2+.rom

curl $DIR1/$D0_2 > apple2.rom
curl $DIR2/$D8_2P >> apple2.rom
curl $DIR1/$E0_2 >> apple2.rom
curl $DIR1/$E8_2 >> apple2.rom
curl $DIR1/$F0_2 >> apple2.rom
curl $DIR1/$F8_2 >> apple2.rom

curl http://mirrors.apple2.org.za/Apple%20II%20Documentation%20Project/Interface%20Cards/Disk%20Drive%20Controllers/Apple%20Disk%20II%20Interface%20Card/ROM%20Images/Apple%20Disk%20II%2016%20Sector%20Interface%20Card%20ROM%20P5%20-%20341-0027.bin >> 'Apple Disk II 16 Sector Interface Card ROM P5 - 341-0027.bin'
