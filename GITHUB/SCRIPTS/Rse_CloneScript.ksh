#!/bin/bash
#===============================================================================
#  Check the usage.
#===============================================================================
PROG_NAME=`basename $0`
if [ $# -ne 1 ]; then
   echo "  Usage : $PROG_NAME ORACLE_SID"
   echo "Example : $PROG_NAME RBTEST"
   exit 100
fi
RDBMS_SID=`echo $1 | tr "[:lower:]" "[:upper:]"`
#===============================================================================
#  If the abend file exists, this is a restart else a fresh run
#===============================================================================
CURR_DATE=`date '+%Y%m%d'`
ABEND_FILE=/home_local/apusdebsrd/clone_scripts/manual/abend.${RDBMS_SID}.${CURR_DATE}
if [ -s $ABEND_FILE ]; then
   LAST_STEP=`cat $ABEND_FILE | cut -f2 -d:`
   echo "Abend file exists. This run is actually a restart of the program." >>$v_logfile
   echo "Last successful step executed was: $LAST_STEP" >>$v_logfile
   LAST_STEP=`expr $LAST_STEP + 1`
   echo "The program will resume execution from step#: $LAST_STEP" >>$v_logfile
else
   echo "Abend file NOT present. This is fresh run" >>$v_logfile
   LAST_STEP=1
fi
#===============================================================================
#  Set the script required config and environment
#===============================================================================
export v_patch_edition=fs2;
export v_source_file=/usdebsrd_app;
export dst=/usdebsrd_app/oracle
export v_apppass=EbsTst_QjoDurLmP6w8zEw2020;
export v_weblogic=weblogicr122;
export v_contextfile=/home_local/apusdebsrd/clone_scripts/manual/USDEBSRD_nhnaunxeerpt013.xml;
export v_port_pool=3;
export v_logfile=/home_local/apusdebsrd/clone_scripts/manual/appsTierClone$(date +%Y%m%d_%H%M%S).log; export v_run_edition=fs1; export v_patch_edition=fs2; export v_source_file=/usdebsrd_app; #export v_apppass=EbsTst_QjoDurLmP6w8zEw2020;
export v_weblogic=weblogicr122;
export v_contextfile=/home_local/apusdebsrd/clone_scripts/manual/USDEBSRD_nhnaunxeerpt013.xml;
export v_port_pool=3;

echo "                              Starting Applicaiton Clone                   " >>$v_logfile
. $v_source_file/oracle/EBSapps.env << EOF R EOF
/usr/sbin/fuser -km /usdebsrd_app/oracle
#===============================================================================
#  Start the actual processing.........
#===============================================================================
for CURR_STEP in $(seq "$LAST_STEP" 1 14)
do
   echo "Current Step#:$CURR_STEP:"
   case $CURR_STEP in
      1) echo " Step 001 ============>       apps_disable_custom_profile                  " >>$v_logfile
         $dst/fs2/EBSapps/10.1.2/bin/sqlplus /nolog  @alter_users1.sql
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "                        Error apps_disable_custom_profile                " >>$v_logfile
            exit $CURR_STEP
         else
            echo "                     apps_disable_custom_profile is Completed            " >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      2) echo " Step 002 ============>        apps password changed                      " >>$v_logfile
         /home_local/apusdebsrd/clone_scripts/manual/CFNDCPASS.sh
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "                             Error apps_custom_pass                     " >>$v_logfile
            exit $CURR_STEP
         else
            echo "                           apps_custom_pass is Completed                " >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      3) echo " Step 003 ============>            Cleanup Files                         " >>$v_logfile
         /usr/sbin/fuser -km $dst
         echo $dst/oraInventory $dst/fs2/FMW_Home $dst/fs1/FMW_Home >>$v_logfile
         rm -rf  $dst/oraInventory $dst/fs2/FMW_Home $dst/fs1/FMW_Home
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "                             Error apps_removefile                   " >>$v_logfile
            exit $CURR_STEP
         else
            echo "                            apps_removefile Completed                " >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      4) echo " Step 004 ============>       apps_enable_custom_profile                  " >>$v_logfile
         $dst/fs2/EBSapps/10.1.2/bin/sqlplus /nolog  @alter_users2.sql
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "                        Error apps_enable_custom_profile                " >>$v_logfile
            exit $CURR_STEP
         else
            echo "                     apps_enable_custom_profile is Completed            " >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      5) echo " Step 005 ============> Application Clone Tier                            " >>$v_logfile
         /usr/bin/perl $v_source_file/oracle/$v_run_edition/EBSapps/comn/clone/bin/adcfgclone.pl appsTier $v_contextfile dualfs <<EOF $v_apppass $v_weblogic $v_port_pool y EOF
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "                             Application Clone Failed                     " >>$v_logfile
            exit $CURR_STEP
         else
            echo "**************************************  Application Clone is Completed  ************************************             " >>$v_logfile
            echo
            echo
            echo "**********************************Application Filesystem " $v_source_file/$v_run_edition >>$v_logfile
            echo "*********************************      Context File " $v_contextfile  >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      6) source $v_source_file/oracle/EBSapps.env << EOF R EOF
         echo    >>$v_logfile
         echo " Step 006 ==========> SSO Configuration "    >>$v_logfile
         echo   >>$v_logfile
         echo "***********************************Removing OAM Referance CONTEXT_FILE "   >>$v_logfile
         { echo n ; echo $v_apppass ; echo y ; } |$v_source_file/oracle/$v_run_edition/EBSapps/appl/fnd/12.0.0/bin/txkrun.pl -script=SetOAMReg -removeoamreferences=yes
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "****************************Error Removeoamreference " >>$v_logfile
            exit $CURR_STEP
         else
            echo "****************************Removeoamreferenced" >>$v_logfile fi
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      7) echo " Step 007 ===========>  Removing OAM Referance Files "  >>$v_logfile
         echo  $v_source_file/oracle/$v_patch_edition/FMW_Home/Oracle_OAMWebGate1 >>$v_logfile
         echo  $v_source_file/oracle/$v_run_edition/FMW_Home/Oracle_OAMWebGate1 >>$v_logfile
         /usr/sbin/fuser -km $v_source_file/oracle
         rm -rf $v_source_file/oracle/$v_patch_edition/FMW_Home/Oracle_OAMWebGate1 $v_source_file/oracle/$v_run_edition/FMW_Home/Oracle_OAMWebGate1
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "*************************Error Removeoamreference Files  " >>$v_logfile
            exit $CURR_STEP
         else
            echo "Removeoamreferenced  Files"  >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      8) echo " Step 008 ===========>  Install OAM Webgate OAMOID " >>$v_logfile
         $v_source_file/oracle/$v_run_edition/EBSapps/appl/fnd/12.0.0/bin/txkrun.pl -script=SetOAMReg -installWebgate=yes -webgatestagedir=/ora_stage/OAMOID/OHS_webgate_11.1.2.3.0
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "************************Error Install OAM Webgate OAMOID " >>$v_logfile
            exit $CURR_STEP
         else
            echo "***********************Installed OAM Webgate OAMOID"  >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      9) echo " Step 009 ===========>  AdProvisionEBS "  >>$v_logfile
         { echo $v_apppass ; echo weblogicr122 ; } |perl $AD_TOP/patch/115/bin/adProvisionEBS.pl ebs-create-oaea_resources -contextfile=$CONTEXT_FILE -deployApps=accessgate -SSOServerURL=https://login-usd-sso-prod.dbamaze.com:443 -logfile=deployaccessgate.log
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "*************************Error AdProvisionEBS " >>$v_logfile
            exit $CURR_STEP
         else
            echo "***********************AdProvisionEBS is completed"  >>$v_logfile fi
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

     10) echo "" Step 010 ===========>  admanagedsrvctl starting " >>$v_logfile
         { echo $v_weblogic ; } |admanagedsrvctl.sh start  oaea_server1
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "*************************oaea_server1 Error "  >>$v_logfile
            exit $CURR_STEP
         else
            echo "*************************oaea_server1 started"  >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

     11) echo "" Step 011 ===========>  Register OAM  "  >>$v_logfile
         $v_source_file/oracle/$v_run_edition/EBSapps/appl/fnd/12.0.0/bin/txkrun.pl -script=SetOAMReg -registeroam=yes -ldapProvider=OUD -oamHost=http://nhnaunxlwebp045.goldlnk.rootlnka.net:7001 -oamUserName=weblogic -ldapUrl=ldap://nhnaunxlwebp047.goldlnk.rootlnka.net:1389  -oidUserName=cn=oudadmin -skipConfirm=yes -ldapSearchBase=cn=Users,dc=baesystems,dc=com -ldapGroupSearchBase=cn=Groups,dc=baesystems,dc=com -authScheme=PingFed_IdPFederationScheme -oamPassword=weblogicr122 -oidPassword=weblogicr122 -appsPassword=$v_apppass
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "**************************Register OAM Error " >>$v_logfile
            exit $CURR_STEP
         else
            echo "**************************Registered OAM" >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

     12) echo "" Step 012 ===========>  Restart Appliation  Tiers"   >>$v_logfile
         { echo apps ; echo  $v_apppass ; echo $v_weblogic ; } | $ADMIN_SCRIPTS_HOME/adstpall.sh
         sleep 600
         /usr/sbin/fuser -km $v_source_file/oracle
         { echo apps ; echo  $v_apppass ; echo $v_weblogic ; } | $ADMIN_SCRIPTS_HOME/adstrtal.sh
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "******************* Starting  Application Tier Error " >>$v_logfile
            exit $CURR_STEP
         else
            echo "*********************Started  Application Tier" >>$v_logfile fi
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

     13) echo "" Step 013 ===========>  Custom Appliation  Tiers"   >>$v_logfile
         sqlplus apps/$v_apppass @$FND_TOP/patch/115/sql/fndssouu.sql  %
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "***************************FNDSSOUU  Error "
            exit $CURR_STEP
         else
            echo "************************FNDSSOUU is Completed" >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

     14) echo "" Step 014 ===========>  Bae Apps Support Package"   >>$v_logfile
         sqlplus apps/$v_apppass @/home_local/apusdebsrd/clone_scripts/manual/bae_apps_support_pkg.sql
         RETN_CODE=$?
         if [ $RETN_CODE -ne 0 ]; then
            echo "************************Bae_apps_support_pkg  Error " >>$v_logfile
            exit $CURR_STEP
         else
            echo "***********************Bae_apps_support_pkg is  Completed" >>$v_logfile
            CURR_TIME=`date '+%Y%m%d%H%M'`
            echo "${CURR_TIME}:${CURR_STEP}" >$ABEND_FILE
         fi;;

      *) echo "step not found - step: $CURR_STEP" >>$v_logfile
         ;;
   esac
done

#===============================================================================
#   Remove the ABEND file
#===============================================================================
rm -f $ABEND_FILE

