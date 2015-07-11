# teiten

## Create disc image

```

du -sk Teiten.app
hdiutil create -size 20m -type UDIF -fs HFS+ -volname "Teiten" -layout NONE TeitenTmp.dmg
hdid TeitenTmp.dmg
ditto -rsrcFork Teiten.app /Volumes/Teiten/Teiten.app

```

## Set a background image of the installer

```

mkdir /Volumes/Teiten/.background
cp InstallerBackground.png /Volumes/Teiten/.background/

```

## Set a bihavior in running disk image

```
echo '
   tell application "Finder"
     tell disk "Teiten"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 885, 430}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set background picture of theViewOptions to file ".background:'InstallerBackground.png'"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "Teiten" of container window to {100, 100}
           set position of item "Applications" of container window to {375, 100}
           update without registering applications
           delay 5
           close
     end tell
   end tell
' | osascript
```


```
hdiutil eject disk4
hdiutil convert -format UDZO -o Teiten.dmg TeitenTmp.dmg
```
