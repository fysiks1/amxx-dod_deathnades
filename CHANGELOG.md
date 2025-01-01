# Revision History:

## 2.3H (2009-10-14)
Fix/Work-around for bug in 'dodfun' module 1.80+ that causes nades to glow the wrong colors (incorrect thrown nade values returned by grenade_throw function).

## 2.2H (2009-10-08)
Fixed nades being removed when touched but not picked up
Option to Glow dropped nades OR live nades (OR both)
Option to Glow nades with team colors or same color (yellow) for both

## 2.1H (2009-03-12)
Added option to 'glow' dropped grenades
Nades dropped with random velocity
Changed grenade classname for compatibility with other plugins
Discontinued non-HamSandwich version updates
Note: This version introduced a minor bug that removed dropped nades
when they were touched by a player carring the max number of nades.

## 2.0H (2008-06-03)
Utilizes HamSandwich for Touch and Think routines
Requires Amxmodx 1.8+ and Hamsandwich module

## 2.0 (2008-06-03)
Corrrected weapons misreporting in DeathMsg
Fixed switching to picked-up nade if using a knife or spade
Cleanup nades if ctrl changed to 0 in the middle of a round
Many code efficiency improvements (see comments in sma)

## 1.85 (2007-06-02)
Added server-side variable named DOD_Deathnades to track plugin usage via Game-Monitor
Changed CVAR dod_deathnades_life to default to 20 seconds
Changed CVAR dod_deathnades_use to default to 0

## 1.8 (2007-05-06)
Added a routine to clear dropped grenades at the end of a round

## 1.7 (2007-04-27)
Fix for servers running LINUX

## 1.6 (2007-04-25)
Original release
