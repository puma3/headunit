#!/bin/sh
# tweaks.sh - MZD-AIO-TI Version 2.8.3
# Special thanks to Siutsch for collecting all the tweaks and for the original AIO
# Big Thanks to Modfreakz, khantaena, Xep, ID7, Doog, Diginix, oz_paulb, VIC_BAM85, & lmagder
# For more information visit https://mazdatweaks.com
# Enjoy, Trezdog44 - Trevelopment.com
# (C) 2019 Trevor G Martin

# Time
hwclock --hctosys

# AIO Variables
AIO_VER=2.8.3
AIO_DATE=2018.11.21
# Android Auto Headunit App Version
AA_VER=1.10+
# Video Player Version
VP_VER=3.7
# Speedometer Version
SPD_VER=5.8
# AIO Tweaks App Version
AIO_TWKS_VER=0.9
# CASDK Version
CASDK_VER=0.0.5
# Variable paths to common locations for better code readability
# additionalApps.json
ADDITIONAL_APPS_JSON="/jci/opera/opera_dir/userjs/additionalApps.json"
# stage_wifi.sh
STAGE_WIFI="/jci/scripts/stage_wifi.sh"
# location of SD card
MZD_APP_SD="/tmp/mnt/sd_nav"
# CASDK Apps location
MZD_APP_DIR="/tmp/mnt/resources/aio/mzd-casdk/apps"
# Install location for native AIO apps
AIO_APP_DIR="/jci/gui/apps"
# New location for backup ".org" files (v70+)
NEW_BKUP_DIR="/tmp/mnt/resources/dev/org_files"

KEEPBKUPS=0
TESTBKUPS=1
SKIPCONFIRM=1
APPS2RESOURCES=0

timestamp()
{
  date +"%D %T"
}
get_cmu_sw_version()
{
  _ver=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')
  _patch=$(grep "^JCI_SW_VER_PATCH=" /jci/version.ini | sed 's/^.*\"\([^\"]*\)\"$/\1/')
  _flavor=$(grep "^JCI_SW_FLAVOR=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/')

  if [ ! -z "${_flavor}" ]; then
    echo "${_ver}${_patch}-${_flavor}"
  else
    echo "${_ver}${_patch}"
  fi
}
get_cmu_ver()
{
  _ver=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 1)
  echo ${_ver}
}
log_message()
{
  echo "$*" 1>&2
  echo "$*" >> "${MYDIR}/AIO_log.txt"
  /bin/fsync "${MYDIR}/AIO_log.txt"
}
aio_info()
{
  if [ $KEEPBKUPS -eq 1 ]
  then
    # echo "$*" 1>&2
    echo "$*" >> "${MYDIR}/AIO_info.json"
    /bin/fsync "${MYDIR}/AIO_info.json"
  fi
}
# CASDK functions
get_casdk_mode()
{
  if [ -e /jci/casdk/casdk.aio ]
  then
    source /jci/casdk/casdk.aio
    CASDK_MODE=1
  else
    _CASDK_VER=0
    CASDK_MODE=0
  fi
}
add_casdk_app()
{
  CASDK_APP=${2}
  if [ ${1} -eq 1 ] && [ -e ${MYDIR}/casdk/apps/app.${CASDK_APP} ]
  then
    sed -i /${CASDK_APP}/d ${MZD_APPS_JS}
    cp -a ${MYDIR}/casdk/apps/app.${CASDK_APP} ${MZD_APP_DIR}
    echo "  \"app.${CASDK_APP}\"," >> ${MZD_APPS_JS}
    show_message "INSTALL ${CASDK_APP} ..."
    CASDK_APP="${CASDK_APP}         "
    log_message "===                 Installed CASDK App: ${CASDK_APP:0:10}                   ==="
  fi
}
remove_casdk_app()
{
  CASDK_APP=${2}
  if [ ${1} -eq 1 ] && grep -Fq ${CASDK_APP} ${MZD_APPS_JS}
  then
    sed -i /${CASDK_APP}/d ${MZD_APPS_JS}
    show_message "UNINSTALL ${CASDK_APP} ..."
    CASDK_APP="${CASDK_APP}         "
    log_message "===                Uninstalled CASDK App: ${CASDK_APP:0:10}                  ==="
  fi
}
# Compatibility check falls into 7 groups:
# 70.00.100+ ($COMPAT_GROUP=7 *Temporary, until tested*)
# 70.00.XXX ($COMPAT_GROUP=6)
# 59.00.5XX ($COMPAT_GROUP=5)
# 59.00.4XX ($COMPAT_GROUP=4)
# 59.00.3XX ($COMPAT_GROUP=3)
# 58.00.XXX ($COMPAT_GROUP=2)
# 55.00.XXX - 56.00.XXX ($COMPAT_GROUP=1)
compatibility_check()
{
  _VER=$(get_cmu_ver)
  _VER_EXT=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 3)
  _VER_MID=$(grep "^JCI_SW_VER=" /jci/version.ini | sed 's/^.*_\([^_]*\)\"$/\1/' | cut -d '.' -f 2)
  if [ $_VER_MID -ne "00" ] # Only development versions have numbers other than '00' in the middle
  then
    echo 0 && return
  fi
  if [ $_VER -eq 55 ] || [ $_VER -eq 56 ]
  then
    echo 1 && return
  elif [ $_VER -eq 58 ]
  then
    echo 2 && return
  elif [ $_VER -eq 59 ]
  then
    if [ $_VER_EXT -lt 400 ] # v59.00.300-400
    then
      echo 3 && return
    elif [ $_VER_EXT -lt 500 ] # v59.00.400-500
    then
      echo 4 && return
    else
      echo 5 && return # 59.00.502+ is another level because it is not compatible with USB Audio Mod
    fi
  elif [ $_VER -eq 70 ]
  then
    if [ $_VER_EXT -le 100 ]
    then
      echo 6 && return # v70.00.100 For Integrity check
    else
      echo 7 && return # Past v70.00.100 is unknown and cannot be trusted
    fi
  else
    echo 0
  fi
}
remove_aio_css()
{
  sed -i "/.. MZD-AIO-TI *${2} *CSS ../,/.. END AIO *${2} *CSS ../d" "${1}"
  INPUT="${1##*/}               "
  log_message "===               Removed CSS From ${INPUT:0:20}               ==="
}
remove_aio_js()
{
  sed -i "/.. MZD-AIO-TI.${2}.JS ../,/.. END AIO.${2}.JS ../d" "${1}"
  INPUT=${1##*/}
  log_message "===            Removed ${2:0:11} JavaScript From ${INPUT:0:13}    ==="
}
rootfs_full_message()
{
  show_message "DANGER!! ROOTFS IS 100% FULL!\nRUN FULL SYSTEM RESTORE OR UNINSTALL TWEAKS\nTO RECOVER SPACE AND RELOCATE FILES"
  sleep 15
  log_message "ROOTFS IS 100% FULL - RUN FULL SYSTEM RESTORE TO RECOVER SPACE AND RELOCATE FILES - CHOOSE \"APPS TO RESOURCES\" OPTION WHEN INSTALLING TWEAKS TO AVOID RUNNING OUT OF SPACE"
  show_message_OK "DANGER!! ROOTFS IS 100% FULL!\nCONTINUING THE INSTALLATION COULD BE DANGEROUS!\nCONTINUE?"
  APPS2RESOURCES=1
}
# checks for remaining space
space_check()
{
  DATA_PERSIST=$(df -h | (grep 'data_persist' || echo 0) | awk '{ print $5 " " $1 }')
  _ROOTFS=$(df -h | (grep 'rootfs' || echo 0) | awk '{ print $5 " " $1 }')
  _RESOURCES=$(df -h | (grep 'resources' || echo 0) | awk '{ print $5 " " $1 }')
  USED=$(echo $DATA_PERSIST | awk '{ print $1}' | cut -d'%' -f1  )
  USED_ROOTFS=$(echo $_ROOTFS | awk '{ print $1}' | cut -d'%' -f1  )
  USED_RESOURCES=$(echo $_RESOURCES | awk '{ print $1}' | cut -d'%' -f1  )
  if [ $APPS2RESOURCES -ne 1 ]
  then
    if [ $USED_ROOTFS -gt 94 ]
    then
      log_message "=============== WARNING: ROOT FILESYSTEM OVER ${USED_ROOTFS}% FULL!! ================"
      APPS2RESOURCES=1
      TESTBKUPS=1
      KEEPBKUPS=1
      [ $COMPAT_GROUP -eq 6 ] && v70_integrity_check
    fi
    if [ $APPS2RESOURCES -eq 1 ]
    then
      AIO_APP_DIR="/tmp/mnt/resources/aio/apps"
      [ -e ${AIO_APP_DIR} ] || mkdir -p ${AIO_APP_DIR}
      [ -e ${NEW_BKUP_DIR} ] || mkdir -p ${NEW_BKUP_DIR}
      log_message "================= App Install Location set to resources ================="
    fi
  elif [ $USED_ROOTFS -gt 95 ]
  then
    log_message "======================== rootfs ${USED_ROOTFS}% used ================================"
  fi
  _ROOTFS=$(df -h | (grep 'rootfs' || echo 0) | awk '{ print $5 " " $1 }')
  USED_ROOTFS=$(echo $_ROOTFS | awk '{ print $1}' | cut -d'%' -f1  )
  if [ $USED_ROOTFS -ge 100 ]
  then
    rootfs_full_message
  fi
}
# Make a ".org" backup
# pass the full file path
# If creating backup fails the installation is aborted
backup_org()
{
  space_check
  FILE="${1}"
  BACKUP_FILE="${1}.org"
  FILENAME=$(basename -- "$FILE")
  FEXT="${FILENAME##*.}"
  FNAME="${FILENAME%.*}"
  NEW_BKUP_FILE="${NEW_BKUP_DIR}/${FILENAME}.org"
  # Test backup "before" copy
  if [ $TESTBKUPS -eq 1 ] && [ ! -e "${MYDIR}/bakups/test/${FNAME}_before.${FEXT}" ]
  then
    cp "${FILE}" "${MYDIR}/bakups/test/${FNAME}_before.${FEXT}"
  fi
  # New backup exists, return
  [ -e "${NEW_BKUP_FILE}" ] && return 0
  if [ ! -e "${BACKUP_FILE}" ]
  then
    if [ $COMPAT_GROUP -gt 5 ] && [ $APPS2RESOURCES -eq 1 ]
    then
      # new location for storing .org files for v70+
      [ -e "${NEW_BKUP_DIR}" ] || mkdir -p "${NEW_BKUP_DIR}"
      BACKUP_FILE="${NEW_BKUP_FILE}"
    fi
    cp -a "${FILE}" "${BACKUP_FILE}" && log_message "***\___  Created Backup of ${FILENAME} to ${BACKUP_FILE}  ___/***"
  fi
  # Make sure the backup is not an empty file
  [ ! -s "${BACKUP_FILE}" ] && v70_integrity_check
  # Keep backup copy
  if [ $KEEPBKUPS -eq 1 ] && [ ! -e "${MYDIR}/bakups/${FILENAME}.org" ]
  then
    cp "${BACKUP_FILE}" "${MYDIR}/bakups/"
    aio_info \"${FILENAME}\",
  fi
}
# Restore file from the ".org" backup
# pass the full file path (without ".org")
# return 1 if no ".org" file exists, 0 if it does
restore_org()
{
  FILE="${1}"
  BACKUP_FILE="${1}.org"
  FILENAME=$(basename -- "$FILE")
  FEXT="${FILENAME##*.}"
  FNAME="${FILENAME%.*}"
  NEW_BKUP_FILE="${NEW_BKUP_DIR}/${FILENAME}.org"
  # Test backups "before-restore" copy
  if [ $TESTBKUPS -eq 1 ] && [ ! -e "${MYDIR}/bakups/test/${FNAME}_before-restore.${FEXT}" ]
  then
    cp "${FILE}" "${MYDIR}/bakups/test/${FNAME}_before-restore.${FEXT}"
  fi
  if [ -e "${BACKUP_FILE}" ]
  then
    if [ -s "${BACKUP_FILE}" ]
    then
      cp -a "${BACKUP_FILE}" "${FILE}" && log_message "***+++ Restored ${FILENAME} From Backup ${BACKUP_FILE} +++***"
      if [ $KEEPBKUPS -eq 1 ] && [ ! -e "${MYDIR}/bakups/${FILENAME}.org" ]
      then
        cp "${BACKUP_FILE}" "${MYDIR}/bakups/"
        aio_info \"${FILENAME}\",
      fi
    else
      # backup file is blank so run v70_integrity check
      log_message "!!!*** WARNING: BACKUP FILE ${BACKUP_FILE} WAS BLANK!!! ***!!!"
      v70_integrity_check || return 1
    fi
    return 0
  else
    # new secondary location for storing .org files for v70+
    if [ -s "${NEW_BKUP_FILE}" ]
    then
      cp -a "${NEW_BKUP_FILE}" "${FILE}" && log_message "+++ Restored ${FILENAME} From Backup ${NEW_BKUP_FILE} +++"
      return 0
    fi
    return 1
  fi
}
# v70 integrity check will check all .org files in the /jci folder
# the files are either moved to the new backup location in /resources
# or deleted if a new backup exists or the file is blank
# if the file is blank a fallback file (from v70.00.100) is saved to the new backup location
# NO SYSTEM FILES ARE RESTORED WITH THIS FUNCION ONLY BACKUP ".org" FILES
v70_integrity_check()
{
  # if not v70.00.000 - 100 return
  log_message "*************************************************************************"
  log_message "********************** v70 INTEGRITY CHECK BEGIN ************************"
  if [ $COMPAT_GROUP -ne 6 ] || [ ! -d "${MYDIR}/config_org/v70/" ]
  then
    [ $COMPAT_GROUP -ne 6 ] && log_message "**************************** NOT V70 SKIPPING ***************************" \
    || log_message "*********************** FALBACK FILES UNAVAILABLE ***********************"
    return 1
  fi
  [ -e ${NEW_BKUP_DIR} ] || mkdir -p ${NEW_BKUP_DIR}
  orgs=$(find /jci -type f -name "*.org")
  for i in $orgs; do
    ORG_FILE="$i"
    FILENAME=$(basename -- $ORG_FILE)
    [ "${FILENAME}" = "sm.conf.org" ] || [ "${FILENAME}" = "fps.js.org" ] && continue
    FILESIZE=$(stat -c%s $ORG_FILE || echo 0)
    FALLBK="${MYDIR}/config_org/v70/${FILENAME}"
    [ -e ${FALLBK} ] || continue
    FALBKSIZ=$(stat -c%s $FALLBK || echo 0)
    NEWBKUP="${NEW_BKUP_DIR}/${FILENAME}"
    [ -e ${NEWBKUP} ] && NEWSIZE=$(stat -c%s $NEWBKUP) || NEWSIZE=0
    # log_message "${FILENAME}: $FILESIZE, ${FALLBK}: $FALBKSIZ, ${NEWBKUP}: $NEWSIZE"
    sleep 1
    # New backup exists & is different from the jci backup file
    if [ -s "${NEWBKUP}" ] && [ $NEWSIZE -ne $FILESIZE ]
    then
      # New backup different from fallback
      if [ $NEWSIZE -ne $FALBKSIZ ]
      then
        cp -a "${FALLBK}" "${NEWBKUP}"
        log_message "***+++ Restored Backup ${NEWBKUP} From Fallback +++***"
      fi
      # backup exists in new locaion already delete extra bkup
      rm -f $ORG_FILE
      log_message "***--- Backup in New Location ${NEWBKUP}... Removing ${ORG_FILE} ---***"
    # No new backup or same as jci .org and dont match fallback
    elif [ $FILESIZE -ne $FALBKSIZ ]
    then
      # backup is invalid size
      cp -a "${FALLBK}" "${NEWBKUP}" && rm -f "${ORG_FILE}"
      log_message "***+++ Repaired Invalid Backup ${FILENAME} +++***"
    elif [ "${FILENAME}" != "opera.ini.org" ]
    then
      # move backup file to new location (all backups will be moved except opera.ini and sm.conf)
      mv "${ORG_FILE}" "${NEWBKUP}"
      log_message "***+++ Moved Backup ${FILENAME} to New Location ${NEWBKUP} +++***"
    else
      continue
    fi
  done
  log_message "*************************************************************************"
  log_message "$(df -h)"
  log_message "******************* v70 INTEGRITY CHECK COMPLETE ************************"
  log_message "*************************************************************************"
  return 0
}
show_message()
{
  sleep 5
  killall -q jci-dialog
  #	log_message "= POPUP: $* "
  /jci/tools/jci-dialog --info --title="MZD-AIO-TI  v.${AIO_VER}" --text="$*" --no-cancel &
}
show_message_OK()
{
  sleep 4
  killall -q jci-dialog
  #	log_message "= POPUP: $* "
  /jci/tools/jci-dialog --confirm --title="MZD-AIO-TI | CONTINUE INSTALLATION?" --text="$*" --ok-label="YES - GO ON" --cancel-label="NO - ABORT"
  if [ $? != 1 ]
  then
    killall -q jci-dialog
    return
  else
    log_message "************************ INSTALLATION ABORTED ***************************"
    show_message "INSTALLATION ABORTED! PLEASE UNPLUG USB DRIVE"
    sleep 10
    killall -q jci-dialog
    exit 0
  fi
}
# create additionalApps.json file from scratch if the file does not exist
create_app_json()
{
  if [ ! -e ${ADDITIONAL_APPS_JSON} ]
  then
    echo "[" > ${ADDITIONAL_APPS_JSON}
    echo "]" >> ${ADDITIONAL_APPS_JSON}
    chmod 755 ${ADDITIONAL_APPS_JSON}
    log_message "===                   Created additionalApps.json                     ==="
  fi
}
addon_common()
{
  # Copies the content of the addon-common folder
  if [ $APPS2RESOURCES -eq 1 ]
  then
    # symlink to resources
    if [ ! -e /tmp/mnt/resources/aio/addon-common ]
    then
      [ -e /tmp/mnt/resources/aio ] || mkdir /tmp/mnt/resources/aio
      cp -a ${MYDIR}/config/jci/gui/addon-common /tmp/mnt/resources/aio
      chmod 755 -R /tmp/mnt/resources/aio
      log_message "===            Copied addon-common folder to resources                ==="
    fi
    if [ ! -L /jci/gui/addon-common ]
    then
      rm -rf /jci/gui/addon-common
      ln -sf /tmp/mnt/resources/aio/addon-common /jci/gui/addon-common
      log_message "===         Created Symlink to resources for addon-common             ==="
    fi
  else
    if [ -L /jci/gui/addon-common ]
    then
      rm -rf /jci/gui/addon-common
      rm -rf /tmp/mnt/resources/aio/addon-common
      log_message "===         Removed Symlink to resources for addon-common             ==="
    fi
    if [ ! -e /jci/gui/addon-common/websocketd ] || [ ! -e /jci/gui/addon-common/jquery.min.js ]
    then
      cp -a ${MYDIR}/config/jci/gui/addon-common/ /jci/gui/
      chmod 755 -R /jci/gui/addon-common/
      log_message "===                   Copied addon-common folder                      ==="
    fi
  fi
}
info_log()
{
  INFOLOG="${MYDIR}/bakups/info.log"
  rm -f $INFOLOG
  show_version.sh > $INFOLOG
  echo "INFO LOG: ${INFOLOG} $(timestamp)" >> $INFOLOG
  echo "> df -h" >> $INFOLOG
  df -h >> $INFOLOG
  echo "> cat /proc/mounts" >> $INFOLOG
  cat /proc/mounts >> $INFOLOG
  echo "> cat /proc/meminfo" >> $INFOLOG
  cat /proc/meminfo >> $INFOLOG
  echo "> ps" >> $INFOLOG
  ps >> $INFOLOG
  echo "> dmesg" >> $INFOLOG
  dmesg >> $INFOLOG
  # echo "> netstat -a" >> $INFOLOG
  # netstat -a >> $INFOLOG
  # echo "> du -h /jci" >> $INFOLOG
  # du -h /jci >> $INFOLOG
  # echo "> du -h /tmp/mnt/resources" >> $INFOLOG
  # du -h /tmp/mnt/resources >> $INFOLOG
  echo "END INFO LOG: $(timestamp)" >> $INFOLOG
}
# script by vic_bam85
add_app_json()
{
  # check if entry in additionalApps.json still exists, if so nothing is to do
  count=$(grep -c '{ "name": "'"${1}"'"' ${ADDITIONAL_APPS_JSON})
  if [ $count -eq 0 ]
  then
    # try to use node if it exists
    if which node > /dev/null && which add_app_json.js > /dev/null
    then
      add_app_json.js ${ADDITIONAL_APPS_JSON} "${1}" "${2}" "${3}" >> ${MYDIR}/node.log 2>&1
      log_message "===                node add_app_json.js ${2:0:10}                    ==="
    elif [ -e ${MYDIR}/config/bin/node ] && [ -e ${MYDIR}/config/bin/add_app_json.js ]
    then
      ${MYDIR}/config/bin/node ${MYDIR}/config/bin/add_app_json.js ${ADDITIONAL_APPS_JSON} "${1}" "${2}" "${3}" >> ${MYDIR}/node.log 2>&1
      log_message "===   ${MYDIR}/config/bin/node add_app_json.js ${2:0:10}        ==="
    else
      log_message "===  ${2:0:10} not found in additionalApps.json, first installation  ==="
      mv ${ADDITIONAL_APPS_JSON} ${ADDITIONAL_APPS_JSON}.old
      sleep 2
      # delete last line with "]" from additionalApps.json
      grep -v "]" ${ADDITIONAL_APPS_JSON}.old > ${ADDITIONAL_APPS_JSON}
      sleep 2
      cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-2._delete_last_line.json"
      # check, if other entrys exists
      count=$(grep -c '}' ${ADDITIONAL_APPS_JSON})
      if [ $count -ne 0 ]
      then
        # if so, add "," to the end of last line to additionalApps.json
        echo "$(cat ${ADDITIONAL_APPS_JSON})", > ${ADDITIONAL_APPS_JSON}
        sleep 2
        cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-3._add_comma_to_last_line.json"
        log_message "===           Found existing entrys in additionalApps.json            ==="
      fi
      # add app entry and "]" again to last line of additionalApps.json
      log_message "===        Add ${2:0:10} to last line of additionalApps.json         ==="
      echo '  { "name": "'"${1}"'", "label": "'"${2}"'" }' >> ${ADDITIONAL_APPS_JSON}
      sleep 2
      if [ "${3}" != "" ]
      then
        sed -i 's/"label": "'"${2}"'" \}/"label": "'"${2}"'", "preload": "'"${3}"'" \}/g' ${ADDITIONAL_APPS_JSON}
      fi
      cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-4._add_entry_to_last_line.json"
      echo "]" >> ${ADDITIONAL_APPS_JSON}
      sleep 2
      rm -f ${ADDITIONAL_APPS_JSON}.old
    fi
    cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-5._after.json"
    if [ -e /jci/opera/opera_dir/userjs/nativeApps.js ]
    then
      echo "additionalApps = $(cat ${ADDITIONAL_APPS_JSON})" > /jci/opera/opera_dir/userjs/nativeApps.js
      log_message "===                    Updated nativeApps.js                          ==="
    fi
  else
    log_message "===         ${2:0:10} already exists in additionalApps.json          ==="
  fi
}
# script by vic_bam85
remove_app_json()
{
  if which node > /dev/null && which remove_app_json.js > /dev/null
  then
    remove_app_json.js ${ADDITIONAL_APPS_JSON} "${1}" >> ${MYDIR}/node.log 2>&1
    log_message "===              node remove_app_json.js ${1:1:10}                   ==="
  elif [ -e ${MYDIR}/config/bin/node ] && [ -e ${MYDIR}/config/bin/remove_app_json.js ]
  then
    ${MYDIR}/config/bin/node ${MYDIR}/config/bin/remove_app_json.js ${ADDITIONAL_APPS_JSON} "${1}" >> ${MYDIR}/node.log 2>&1
    log_message "===    ${MYDIR}/config/bin/node remove_app_json.js ${1:1:10}    ==="
  else
    # check if app entry in additionalApps.json still exists, if so, then it will be deleted
    count=$(grep -c '{ "name": "'"${1}"'"' ${ADDITIONAL_APPS_JSON})
    if [ "$count" -gt "0" ]
    then
      log_message "====   Remove ${count} entry(s) of ${1:0:10} found in additionalApps.json   ==="
      mv ${ADDITIONAL_APPS_JSON} ${ADDITIONAL_APPS_JSON}.old
      # delete last line with "]" from additionalApps.json
      grep -v "]" ${ADDITIONAL_APPS_JSON}.old > ${ADDITIONAL_APPS_JSON}
      sleep 2
      cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-2._delete_last_line.json"
      # delete all app entrys from additionalApps.json
      sed -i "/${1}/d" ${ADDITIONAL_APPS_JSON}
      sleep 2
      json="$(cat ${ADDITIONAL_APPS_JSON})"
      # check if last sign is comma
      rownend=$(echo -n $json | tail -c 1)
      if [ "$rownend" = "," ]
      then
        # if so, remove "," from back end
        echo ${json%,*} > ${ADDITIONAL_APPS_JSON}
        sleep 2
        log_message "===  Found comma at last line of additionalApps.json and deleted it   ==="
      fi
      cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-3._delete_app_entry.json"
      # add "]" again to last line of additionalApps.json
      echo "]" >> ${ADDITIONAL_APPS_JSON}
      sleep 2
      first=$(head -c 1 ${ADDITIONAL_APPS_JSON})
      if [ "$first" != "[" ]
      then
        sed -i "1s/^/[\n/" ${ADDITIONAL_APPS_JSON}
        log_message "===             Fixed first line of additionalApps.json               ==="
      else
        sed -i "1s/\[/\[\n/" ${ADDITIONAL_APPS_JSON}
      fi
      rm -f ${ADDITIONAL_APPS_JSON}.old
    else
      log_message "===            ${1:1:10} not found in additionalApps.json            ==="
    fi
  fi
  cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps${1}-4._after.json"
  if [ -e /jci/opera/opera_dir/userjs/nativeApps.js ]
  then
    echo "additionalApps = $(cat ${ADDITIONAL_APPS_JSON})" > /jci/opera/opera_dir/userjs/nativeApps.js
    log_message "===                    Updated nativeApps.js                          ==="
  fi
}
# disable watchdog and allow write access
echo 1 > /sys/class/gpio/Watchdog\ Disable/value
mount -o rw,remount /

MYDIR=$(dirname "$(readlink -f "$0")")
mount -o rw,remount ${MYDIR}

CMU_VER=$(get_cmu_ver)
CMU_SW_VER=$(get_cmu_sw_version)
COMPAT_GROUP=$(compatibility_check)
get_casdk_mode
info_log

# save logs
mkdir -p "${MYDIR}/bakups/test/"
logfile="${MYDIR}/bakups/AIO_log.log"
if [ -f "${MYDIR}/AIO_log.txt" ]; then
  if [ ! -f "${MYDIR}/bakups/count.txt" ]; then
    echo 0 > "${MYDIR}/bakups/count.txt"
  fi
  logcount=$(cat ${MYDIR}/bakups/count.txt)
  #mv "${MYDIR}/AIO_log.txt" "${MYDIR}/bakups/AIO_log-${logcount}.txt"
  logfile="${MYDIR}/bakups/AIO_log-${logcount}.log"
  echo $((logcount+1)) > "${MYDIR}/bakups/count.txt"
  rm -f "${MYDIR}/AIO_log.txt"
fi
rm -f "${MYDIR}/AIO_info.json"
# experimental new log will expose
# all the errors in my scripts ^_^
exec > $logfile 2>&1
log_message "========================================================================="
log_message "=======================   START LOGGING TWEAKS...  ======================"
log_message "======================= AIO v.${AIO_VER}  -  ${AIO_DATE} ======================"
log_message "=$(/jci/scripts/show_version.sh)"
log_message "======================= CMU_SW_VER = ${CMU_SW_VER} ======================"
log_message "=======================  COMPATIBILITY_GROUP  = ${COMPAT_GROUP} ======================="
#log_message "======================== CMU_VER = ${CMU_VER} ====================="
if [ $CASDK_MODE -eq 1 ]; then
  log_message "============================  CASDK MODE  ==============================="
  WELCOME_MSG="====== MZD-AIO-TI ${AIO_VER} ======\n\n===**** CASDK MODE ****===="
else
  log_message ""
  WELCOME_MSG="==== MZD-AIO-TI  ${AIO_VER} ====="
fi
log_message "=======================   MYDIR = ${MYDIR}    ======================"
log_message "==================      DATE = $(timestamp)        ================="

show_message "${WELCOME_MSG}"

aio_info '{"info":{'
aio_info \"CMU_SW_VER\": \"${CMU_SW_VER}\",
aio_info \"AIO_VER\": \"${AIO_VER}\",
aio_info \"USB_PATH\": \"${MYDIR}\",
aio_info \"KEEPBKUPS\": \"${KEEPBKUPS}\"
aio_info '},'
# first test, if copy from MZD to usb drive is working to test correct mount point
cp /jci/sm/sm.conf "${MYDIR}"
if [ -e "${MYDIR}/sm.conf" ]
then
  log_message "===         Copytest to sd card successful, mount point is OK         ==="
  log_message " "
  rm -f "${MYDIR}/sm.conf"
else
  log_message "===     Copytest to sd card not successful, mount point not found!    ==="
  /jci/tools/jci-dialog --title="ERROR!" --text="Mount point not found, have to reboot again" --ok-label='OK' --no-cancel &
  sleep 5
  reboot
fi
if [ $COMPAT_GROUP -eq 0 ] && [ $CMU_VER -lt 55 ]
then
  show_message "PLEASE UPDATE YOUR CMU FW TO VERSION 55 OR HIGHER\nYOUR FIRMWARE VERSION: ${CMU_SW_VER}\n\nUPDATE TO VERSION 55+ TO USE AIO"
  mv ${MYDIR}/tweaks.sh ${MYDIR}/_tweaks.sh
  show_message "INSTALLATION ABORTED REMOVE USB DRIVE NOW" && sleep 5
  log_message "************************* INSTALLATION ABORTED **************************" && reboot
  exit 1
fi
# Compatibility Check

if [ $COMPAT_GROUP -gt 6 ]
then
  sleep 2
  show_message_OK "WARNING! VERSION ${CMU_SW_VER} DETECTED\nAIO COMPATIBILITY HAS ONLY BEEN TESTED UP TO V70.00.100\nIF YOU ARE RUNNING A LATER FW VERSION\nUSE EXTREME CAUTION!!"
elif [ $COMPAT_GROUP -ne 0 ]
then
  if [ $SKIPCONFIRM -eq 1 ]
  then
    show_message "MZD-AIO-TI v.${AIO_VER}\nDetected compatible version ${CMU_SW_VER}\nContinuing Installation..."
    sleep 5
  else
    show_message_OK "MZD-AIO-TI v.${AIO_VER}\nDetected compatible version ${CMU_SW_VER}\n\n To continue installation choose YES\n To abort choose NO"
  fi
  log_message "=======        Detected compatible version ${CMU_SW_VER}          ======="
else
  # Removing the comment (#) from the following line will allow MZD-AIO-TI to run with unknown fw versions ** ONLY MODIFY IF YOU KNOW WHAT YOU ARE DOING **
  # show_message_OK "Detected previously unknown version ${CMU_SW_VER}!\n\n To continue anyway choose YES\n To abort choose NO"
  log_message "Detected previously unknown version ${CMU_SW_VER}!"
  show_message "Sorry, your CMU Version is not compatible with MZD-AIO-TI\nE-mail aio@mazdatweaks.com with your\nCMU version: ${CMU_SW_VER} for more information"
  sleep 10
  show_message "UNPLUG USB DRIVE NOW"
  sleep 15
  killall -q jci-dialog
  # To run unknown FW you need to comment out or remove the following 2 lines
  mount -o ro,remount /
  exit 0
fi
# a window will appear for 4 seconds to show the beginning of installation
show_message "START OF TWEAK INSTALLATION\nMZD-AIO-TI v.${AIO_VER} By: Trezdog44 & Siutsch\n(This and the following message popup windows\n DO NOT have to be confirmed with OK)\nLets Go!"
log_message " "
log_message "======***********    BEGIN PRE-INSTALL OPERATIONS ...    **********======"
mount -o rw,remount /tmp/mnt/resources/
log_message "================== Remounted /tmp/mnt/resources ========================="

# disable watchdogs in /jci/sm/sm.conf to avoid boot loops if something goes wrong
if [ ! -e /jci/sm/sm.conf.org ]
then
  cp -a /jci/sm/sm.conf /jci/sm/sm.conf.org
  log_message "===============  Backup of /jci/sm/sm.conf to sm.conf.org  =============="
else
  log_message "================== Backup of sm.conf.org already there! ================="
fi
if ! grep -Fq 'watchdog_enable="false"' /jci/sm/sm.conf || ! grep -Fq 'args="-u /jci/gui/index.html --noWatchdogs"' /jci/sm/sm.conf
then
  sed -i 's/watchdog_enable="true"/watchdog_enable="false"/g' /jci/sm/sm.conf
  sed -i 's|args="-u /jci/gui/index.html"|args="-u /jci/gui/index.html --noWatchdogs"|g' /jci/sm/sm.conf
  log_message "===============  Watchdog In sm.conf Permanently Disabled! =============="
else
  log_message "=====================  Watchdog Already Disabled! ======================="
fi
if [ ! -s /jci/opera/opera_home/opera.ini ] && [ -e ${MYDIR}/config_org/v70/opera.ini.org ]
then
  cp -a ${MYDIR}/config_org/v70/opera.ini.org /jci/opera/opera_home/opera.ini
  log_message "======********** DANGER opera.ini WAS MISSING!! REPAIRED **********======"
fi
# -- Enable userjs and allow file XMLHttpRequest in /jci/opera/opera_home/opera.ini - backup first - then edit
if [ ! -s /jci/opera/opera_home/opera.ini.org ]
then
  cp -a /jci/opera/opera_home/opera.ini /jci/opera/opera_home/opera.ini.org
  log_message "======== Backup /jci/opera/opera_home/opera.ini to opera.ini.org ========"
else
  # checks to make sure opera.ini is not an empty file
  [ -s /jci/opera/opera_home/opera.ini ] || cp /jci/opera/opera_home/opera.ini.org /jci/opera/opera_home/opera.ini
  log_message "================== Backup of opera.ini already there! ==================="
fi
if ! grep -Fq 'User JavaScript=1' /jci/opera/opera_home/opera.ini
then
  sed -i 's/User JavaScript=0/User JavaScript=1/g' /jci/opera/opera_home/opera.ini
fi
count=$(grep -c "Allow File XMLHttpRequest=" /jci/opera/opera_home/opera.ini)
skip_opera=$(grep -c "Allow File XMLHttpRequest=1" /jci/opera/opera_home/opera.ini)
if [ $skip_opera -eq 0 ]
then
  if [ $count -eq 0 ]
  then
    sed -i '/User JavaScript=.*/a Allow File XMLHttpRequest=1' /jci/opera/opera_home/opera.ini
  else
    sed -i 's/Allow File XMLHttpRequest=.*/Allow File XMLHttpRequest=1/g' /jci/opera/opera_home/opera.ini
  fi
  log_message "============== Enabled Userjs & Allowed File Xmlhttprequest ============="
  log_message "==================  In /jci/opera/opera_home/opera.ini =================="
else
  log_message "============== Userjs & File Xmlhttprequest Already Enabled ============="
fi
if [ -e /jci/opera/opera_dir/userjs/fps.js ]
then
  mv /jci/opera/opera_dir/userjs/fps.js /jci/opera/opera_dir/userjs/fps.js.org
  log_message "======== Moved /jci/opera/opera_dir/userjs/fps.js to fps.js.org ========="
fi

# Fix missing /tmp/mnt/data_persist/dev/bin/ if needed
if [ ! -e /tmp/mnt/data_persist/dev/bin/ ]
then
  mkdir -p /tmp/mnt/data_persist/dev/bin/
  log_message "======== Restored Missing Folder /tmp/mnt/data_persist/dev/bin/ ========="
fi
if [ -e ${ADDITIONAL_APPS_JSON} ] && grep -Fq ,, ${ADDITIONAL_APPS_JSON}
then
  # remove double commas
  sed -i 's/,,/,/g' ${ADDITIONAL_APPS_JSON}
  log_message "================ Fixed Issue with additionalApps.json ==================="
fi

space_check
log_message "======================= data_persist ${USED}% used ==========================="
log_message "======================== rootfs ${USED_ROOTFS}% used ================================"
log_message "====================== resources ${USED_RESOURCES}% used ==============================="

if [ $USED -ge 80 ]
then
  rm -f /tmp/mnt/data_persist/log/dumps/*.bz2
  log_message "================== Over 80% Used Delete Dump Files  ====================="
fi
if [ $APPS2RESOURCES -eq 1 ]
then
  AIO_APP_DIR="/tmp/mnt/resources/aio/apps"
  [ -e ${AIO_APP_DIR} ] || mkdir -p ${AIO_APP_DIR}
  [ -e ${NEW_BKUP_DIR} ] || mkdir -p ${NEW_BKUP_DIR}
  log_message "=============== App Install Locatiation set to resources ================"
fi
# start JSON array of backups
if [ $KEEPBKUPS -eq 1 ]
then
  aio_info '"Backups": ['
fi
log_message "=========************ END PRE-INSTALL OPERATIONS ***************========="
log_message " "

# Install Android Auto Headunit App
space_check
show_message "INSTALL ANDROID AUTO HEADUNIT APP v${AA_VER} ..."
log_message "====************  INSTALL ANDROID AUTO HEADUNIT APP v${AA_VER}...*********===="
TESTBKUPS=1
if [ $TESTBKUPS -eq 1 ]
then
  cp ${STAGE_WIFI} "${MYDIR}/bakups/test/stage_wifi_androidauto-before.sh"
  cp /jci/sm/sm.conf "${MYDIR}/bakups/test/sm_androidauto-before.conf"
  [ -f ${ADDITIONAL_APPS_JSON} ] && cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps_androidauto-1_before.json"
fi

### kills all WebSocket daemons
killall -q -9 headunit
pkill websocketd

rm -fr /jci/gui/apps/_androidauto
rm -fr /tmp/mnt/resources/aio/apps/_androidauto
rm -fr /tmp/mnt/data_persist/dev/androidauto
rm -fr /tmp/mnt/data_persist/dev/bin/headunit*
rm -f /tmp/mnt/data_persist/dev/bin/aaserver
rm -f /tmp/mnt/data_persist/dev/bin/check-usb.sh
rm -f /tmp/mnt/data_persist/dev/bin/usb-allow.list
rm -f /tmp/mnt/data_persist/dev/bin/input_filter
rm -f /tmp/mnt/data/enable_input_filter
rm -f /tmp/mnt/data/input_filter
sed -i '/9999/d' ${STAGE_WIFI}
sed -i '/headunit/d' ${STAGE_WIFI}
sed -i '/Android Auto/d' ${STAGE_WIFI}
sed -i '/check-usb/d' ${STAGE_WIFI}
log_message "===                   Removed old Android Auto App                    ==="
if grep -Fq "input_filter" /jci/sm/sm.conf
then
  sed -i '/input_filter/ d' /jci/sm/sm.conf
  log_message "===           Clean obsolete input_filter to /jci/sm/sm.conf          ==="
fi

# delete empty lines
sed -i '/^ *$/ d' ${STAGE_WIFI}
sed -i '/#!/ a\ ' ${STAGE_WIFI}

# check for 1st line of stage_wifi.sh
if ! grep -Fq "#!/bin/sh" ${STAGE_WIFI}
then
  log_message "===                 Missing 1st line of stage_wifi.sh                 ==="
  echo "#!/bin/sh" > ${STAGE_WIFI}
fi
sed -i '/#!/ a\#### Android Auto start' ${STAGE_WIFI}
sleep 1
sed -i '/Android Auto start/ i\ ' ${STAGE_WIFI}
sed -i '/Android Auto start/ a\headunit-wrapper &' ${STAGE_WIFI}
log_message "===      Added Android Auto entry to ${STAGE_WIFI}       ==="

cp -a ${MYDIR}/config/androidauto/jci/gui/apps/_androidauto ${AIO_APP_DIR}
cp -a ${MYDIR}/config/androidauto/data_persist/dev/* /tmp/mnt/data_persist/dev
chmod -R 755 /tmp/mnt/data_persist/dev/bin/
log_message "===                Copied Android Auto Headunit App files             ==="

# symlink to resources
if [ $APPS2RESOURCES -eq 1 ]
then
  ln -sf /tmp/mnt/resources/aio/apps/_androidauto /jci/gui/apps/_androidauto
  log_message "===                Created Symlink To Resources Partition             ==="
fi

# copy additionalApps.js, if not already present
if [ $CASDK_MODE -eq 0 ]
then
  log_message "===           No additionalApps.js available, will copy one           ==="
  cp -a ${MYDIR}/config/jci/opera/opera_dir/userjs/*.js /jci/opera/opera_dir/userjs/ && CASDK_MODE=1
  find /jci/opera/opera_dir/userjs/ -type f -name '*.js' -exec chmod 755 {} \;
fi

create_app_json
# add preload to the AA json entry if needed
if grep -q "_androidauto" ${ADDITIONAL_APPS_JSON} && ! grep -q "preload.js" ${ADDITIONAL_APPS_JSON}
then
  remove_app_json "_androidauto"
fi
# call function add_app_json to modify additionalApps.json
add_app_json "_androidauto" "Android Auto" "preload.js"

if [ -e /etc/asound.conf.org ]
then
  # fix link from previous version
  if ! [ -L /etc/asound.conf ]; then
    mv /etc/asound.conf ${MYDIR}/asound.conf.AA
    ln -sf /data/asound.conf /etc/asound.conf
  fi
  rm -f /etc/asound.conf.org
  log_message "===     /etc/asound.conf reverted from factory /data/asound.conf    ==="
fi

if [ $TESTBKUPS -eq 1 ]
then
  cp ${STAGE_WIFI} "${MYDIR}/bakups/test/stage_wifi_androidauto-after.sh"
  [ -f ${ADDITIONAL_APPS_JSON} ] && cp ${ADDITIONAL_APPS_JSON} "${MYDIR}/bakups/test/additionalApps_after-AA.json"
fi

# Move headunit log file to USB Drive if exists
if [ -e /tmp/mnt/data/headunit.log ]
then
  mv /tmp/mnt/data/headunit.log ${MYDIR}
  log_message "===                 Moved headunit.log To USB Drive                   ==="
fi

# for FW v59 if they do not have No more disclamer or order of audio source
# apply patch to show apps in app List
if [ $COMPAT_GROUP -gt 2 ] && ! grep -Fq "app.casdkapps" /jci/gui/apps/system/js/systemApp.js
then
  backup_org /jci/gui/apps/system/js/systemApp.js
  if [ $COMPAT_GROUP -lt 6 ]
  then
    cp -a ${MYDIR}/config/jci/gui/apps/system/js/systemApp.js /jci/gui/apps/system/js/
    log_message "===        Patched systemApp.js for AIO + CASDK apps for v59          ==="
  elif [ $COMPAT_GROUP -eq 6 ]
  then
    cp -a ${MYDIR}/config/jci/gui/apps/system/js/systemApp.70.js /jci/gui/apps/system/js/systemApp.js
    log_message "===        Patched systemApp.js for AIO + CASDK apps for v70          ==="
  else
    log_message "=== FW > v70.00.100 DETECTED VISIT MAZDATWEAKS.COM FOR MORE DETAILS   ==="
  fi
fi

show_message "========== END OF TWEAKS INSTALLATION =========="
if [ -f "${MYDIR}/AIO_log.txt" ]
then
  END_ROOTFS=$(df -h | (grep 'rootfs' || echo 0) | awk '{ print $5 " " $1 }')
  END_RESOURCES=$(df -h | (grep 'resources' || echo 0) | awk '{ print $5 " " $1 }')
  sleep 2
  log_message "======================== rootfs $(echo $END_ROOTFS | awk '{ print $1}' | cut -d'%' -f1)% used ================================"
  log_message "====================== resources $(echo $END_RESOURCES | awk '{ print $1}' | cut -d'%' -f1)% used ==============================="
  log_message " "
  log_message "======================= END OF TWEAKS INSTALLATION ======================"
  log_message " "
  log_message "$(df -h )"
fi
if [ $KEEPBKUPS -eq 1 ] && [ -e ${MYDIR}/AIO_info.json ]
then
  json="$(cat ${MYDIR}/AIO_info.json)"
  rownend=$(echo -n $json | tail -c 1)
  if [ "$rownend" = "," ]
  then
    # if so, remove "," from back end
    echo -n ${json%,*} > ${MYDIR}/AIO_info.json
    sleep 2
  fi
  aio_info ']}'
fi
# a window will appear before the system reboots automatically
sleep 3
killall -q jci-dialog
/jci/tools/jci-dialog --info --title="SELECTED AIO TWEAKS APPLIED" --text="THE SYSTEM WILL REBOOT IN A FEW SECONDS!" --no-cancel &
sleep 9
killall -q jci-dialog
/jci/tools/jci-dialog --info --title="MZD-AIO-TI v.${AIO_VER}" --text="YOU CAN REMOVE THE USB DRIVE NOW\n\nENJOY!" --no-cancel &
sleep 1
reboot &
exit 0

