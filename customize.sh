# BluetoothLibraryPatcher
# by 3arthur6

check() {
  samsung=`grep -Eqw "androidboot.odin_download|androidboot.warranty_bit|sec_debug" /proc/cmdline && echo 'true' || echo 'false'`
  if $BOOTMODE ; then
    ui_print "- Magisk Manager installation"
    sys=`magisk --path`/.magisk/mirror/system
  else
    ui_print "- Recovery installation"
    sys=`dirname $(find / -mindepth 2 -maxdepth 3 -path "*system/build.prop"|head -1)`
  fi
  if ! $samsung ; then
    ui_print "- Only for Samsung devices!"
    abort
  elif ! `grep -qw ro.build.type=user $sys/build.prop` ; then
    ui_print "- Only for Samsung stock based roms!"
    ui_print "- Not relevant for aosp roms!"
    abort
  elif [[ $API -lt 24 ]] ; then
    ui_print "- Only for Android 7.0 (Nougat) and above"
    abort
  fi
}

search() {
  ui_print "- Searching for relevant hex byte sequence"
  lib=`find $sys/lib*|grep -E "\/(libbluetooth|bluetooth\.default)\.so$"|tail -n 1`
  unzip -q $ZIPFILE hexpatch.sh -d $TMPDIR
  chmod 755 $TMPDIR/hexpatch.sh
  # Executed through bash for array handling
  unzip -p $ZIPFILE bash.tar.xz|tar x -J -C $TMPDIR bash
  chmod 755 $TMPDIR/bash
  export TMPDIR API IS64BIT lib
  $TMPDIR/bash $TMPDIR/hexpatch.sh
}

extract() {
  if [ ! -f $lib ] ; then
    ui_print "- Library not found!"
    abort
  else
    ui_print "- Copying library from system to module"
    mod_path=$MODPATH/`echo $lib|grep -o system.*`
    mkdir -p `dirname $mod_path`
    cp -af $lib $mod_path
  fi
}

patchlib() {
  ui_print "- Applying patch"
  pre=`grep pre_hex $TMPDIR/tmp|cut -d '=' -f2`
  post=`grep post_hex $TMPDIR/tmp|cut -d '=' -f2`
  if [[ $pre == already ]] ; then
    ui_print "- Library already (system-ly) patched!"
    abort
  elif [[ ! -z $pre ]] && `/data/adb/magisk/magiskboot hexpatch $mod_path $pre $post` ; then
    ui_print "- Successfully patched!"
  else
    ui_print "- Library not supported!"
    echo -e "BOOTMODE=$BOOTMODE\nAPI=$API\nIS64BIT=$IS64BIT\nlib=$lib" >> $TMPDIR/tmp
    cp -f $lib $TMPDIR
    tar c -f /sdcard/BluetoothLibPatcher-files.tar -C $TMPDIR `ls $TMPDIR|sed -E '/bash|hexpatch\.sh/d'`
    ui_print  " "
    ui_print "- To get support upload BluetoothLibPatcher-files.tar"
    ui_print "  created in your internal storage to github issue or XDA thread"
    ui_print  " "
    ui_print  "- Opening support webpage in 5 seconds"
    (sleep 5 && am start -a android.intent.action.VIEW -d https://github.com/3arthur6/BluetoothLibraryPatcher/blob/master/SUPPORT.md >/dev/null) &
    rm -rf $MODPATH
    abort
  fi
}

otasurvival() {
  ui_print "- Creating OTA survival service"
  cp -f $ZIPFILE $MODPATH/module.zip
  sed -i "s|previouslibmd5sum_tmp|previouslibmd5sum=`md5sum $lib|cut -d ' ' -f1`|" $MODPATH/service.sh
}

patchmanifest() {
  if [[ $MAGISK_VER == *-delta ]] && [[ -d `magisk --path`/.magisk/mirror/early-mount ]] ; then
    ui_print "- Magisk Delta fork detected"
    ui_print "- Applying gear watch fix"
    mkdir -p `magisk --path`/.magisk/mirror/early-mount/system/vendor/vintf/manifest
    for i in `grep -lr 'security.wsm' /vendor/etc/vintf`
    do
      if [[ ! -z $i ]] ; then
        rm -f `magisk --path`/.magisk/mirror/early-mount/system$i
        cp -af $i `magisk --path`/.magisk/mirror/early-mount/system$i
        sed -i $((`awk '/security.wsm/ {print FNR}' $i`-1)),/<\/hal>/d `magisk --path`/.magisk/mirror/early-mount/system$i
      fi
    done
  fi
}

check
search
extract
patchlib
otasurvival
patchmanifest
