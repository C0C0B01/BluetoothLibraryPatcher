# BluetoothLibraryPatcher
# by 3arthur6

set_vars() {
  model=`grep -o androidboot.em.model=......... /proc/cmdline | tr -d ' ' | cut -d "=" -f2`

  if [ -z $model ] ; then
    abort "- Only for Samsung devices!"
  fi
  if $BOOTMODE ; then
    ui_print "- Magisk Manager installation"
    sys_path="/sbin/.magisk/mirror/system"
  else
    ui_print "- Recovery installation"
    sys_path=`find $ANDROID_ROOT -mindepth 1 -maxdepth 2 -path "*system/build.prop" | xargs dirname`
  fi
  if [ $API == 29 ] ; then
    ui_print "- $model on Android 10 detected"
    library="libbluetooth.so"
    path="$MODPATH/system/lib64/$library"
    if echo $model | grep -Eq 'SM-G9[67][035]0|SM-N9[67][056]0' ; then
      pre_hex="88000054691180522925C81A69000037E0030032"
      post_hex="04000014691180522925C81A69000037E0031F2A"
    else
      pre_hex="C8000034F4031F2AF3031F2AE8030032"
      post_hex="1F2003D5F4031F2AF3031F2AE8031F2A"
    fi
  elif [ $API == 28 ] ; then
    ui_print "- $model on Android Pie detected"
    library="libbluetooth.so"
    path="$MODPATH/system/lib64/$library"
    if echo $model | grep -Eq 'SM-G97[035]0|SM-N97[056]0' ; then
      pre_hex="7F1D0071E91700F9E83C0054"
      post_hex="E0031F2AE91700F9E8010014"
    elif echo $model | grep -Eq 'SM-A600([FGNPTU]|FN|GN|T1)' ; then
      path="$MODPATH/system/lib/$library"
      pre_hex="19B101200028"
      post_hex="00BF00200028"
    elif echo $model | grep -Eq 'SM-A105([FGMN]|FN)' ; then
      path="$MODPATH/system/lib/$library"
      pre_hex="18B101200028"
      post_hex="00BF00200028"
    else
      pre_hex="88000034E803003248070035"
      post_hex="1F2003D5E8031F2A48070035"
    fi
  elif [ $API == 27 ] ; then
    ui_print "- $model on Android Oreo 8.1 detected"
    library="bluetooth.default.so"
    path="$MODPATH/system/lib64/hw/$library"
    path2="$MODPATH/system/lib/hw/$library"
    pre_hex="88000034E803003228050035"
    pre_hex2="0978019009B1012032E07748"
    post_hex="1F2003D5E8031F2A28050035"
    post_hex2="0978019000BF002032E07748"
  elif [ $API == 26 ] ; then
    ui_print "- $model on Android Oreo 8.0 detected"
    library="bluetooth.default.so"
    path="$MODPATH/system/lib64/hw/$library"
    path2="$MODPATH/system/lib/hw/$library"
    pre_hex="88000034E803003228050035"
    pre_hex2="0190087808B1012031E07548"
    post_hex="1F2003D5E8031F2A28050035"
    post_hex2="0190087800BF002031E07548"
  else
    abort "- Only for Android 10, Pie or Oreo!"
  fi
}

extract() {
  if [ $API -ge 28 ] ; then
    mkdir -p $MODPATH/system/lib64
    ui_print "- Copying library from system to module"
    cp -af $sys_path/lib64/$library $path
  else
    mkdir -p $MODPATH/system/lib64/hw $MODPATH/system/lib/hw
    ui_print "- Copying libraries from system to module"
    cp -af $sys_path/lib64/hw/$library $path
    cp -af $sys_path/lib/hw/$library $path2
  fi
}

hex_patch() {
  /data/adb/magisk/magiskboot hexpatch $1 $2 $3 2>&1
}

patch_lib() {
  ui_print "- Patching it"
  if ! echo $(hex_patch $path $pre_hex $post_hex) | grep -Fq "[$pre_hex]->[$post_hex]" ; then
    abort "- Library not supported!"
  fi
  if [ $API -le 27 ] && ! echo $(hex_patch $path2 $pre_hex2 $post_hex2) | grep -Fq "[$pre_hex2]->[$post_hex2]" ; then
    abort "- Library not supported!"
  fi
}

set_vars

extract

patch_lib
