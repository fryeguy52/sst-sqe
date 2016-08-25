#!/bin/bash 
# testSuite_EmberSweep.sh
#######################################################################
#
#    RRRR    EEEEE     A      DDD          M    M   EEEEE
#    R   R   E        A A     D  D         MM  MM   E  
#    R   R   EEEE     A A     D   D        M MM M   EEEE
#    RRRR    E       AAAAA    D   D        M    M   E 
#    R   R   E       A   A    D  D         M    M   E 
#    R   R   EEEEE  A     A   DDD          M    M   EEEEE
#
#    This test suite is unique (as of February 2015) in that the
#    enumberation of tests and the invocation of SST is NOT in
#    this file.
#
#    The enumberation and invocations of SST is from a file generated
#    by execution of the python file, EmberSweepGenerator.py
# 
#    That generated file is then sourced and that file fed to shuint2.
#
#    Note that this Suite runs in the ember elements sub-tree, not in test.
#
#    ------------------------------------------------------------------ 
#       Env variable:    SST_TEST_SE_LIST   to run specific numbers only
#######################################################################


# Description: 

# A shell script that defines a shunit2 test suite. This will be
# invoked by the Bamboo script.

# Preconditions:

# 1) The SUT (software under test) must have built successfully.
# 2) A test success reference file is available.
#  There is no sutArgs= statement.  SST is python wrapped.

TEST_SUITE_ROOT="$( cd -P "$( dirname "$0" )" && pwd )"
# Load test definitions
. $TEST_SUITE_ROOT/../include/testDefinitions.sh
. $TEST_SUITE_ROOT/../include/testSubroutines.sh

#===============================================================================
# Variables global to functions in this suite
#===============================================================================
L_SUITENAME="SST_EmberSweep_suite" # Name of this test suite; will be used to
                             # identify this suite in XML file. This
                             # should be a single string, no spaces
                             # please.

L_BUILDTYPE=$1 # Build type, passed in from bamboo.sh as a convenience
               # value. If you run this script from the command line,
               # you will need to supply this value in the same way
               # that bamboo.sh defines it if you wish to use it.

L_TESTFILE=()  # Empty list, used to hold test file names

#===============================================================================
# Test functions
#   NOTE: These functions are invoked automatically by shunit2 as long
#   as the function name begins with "test...".
#===============================================================================

#-------------------------------------------------------------------------------
# Test:
#     test_EmberSweep
#        The test are identified by a hash code from the sst test line
#        The actual tests generated by a python file.
# Purpose:
#     Exercise the EmberSweep code in SST
# Inputs:
#     None
# Outputs:
#     test_EmberSweep.out file
# Expected Results
#     Match of simulated time against those in single reference file
# Caveats:
#     The simulation time lines must match the reference file *exactly*,
#
#-------------------------------------------------------------------------------

    #  Most test Suites explicitly define an environment variable sut to be full path SST
    #     The Python script does not do this

pwd

pushd ${SST_ROOT}/sst-elements/src/sst/elements/ember/test

pwd
ls
#      Initialize variables
startSeconds=0
RUNNING_INDEX=0
FAILED_TESTS=0
FAILED="FALSE"
PARAMS=""
 

SE_start() {
    RUNNING_INDEX=$(($RUNNING_INDEX+1))
    echo " $RUNNING_INDEX run, $FAILED_TESTS have failed"
    if [ $SE_SELECT == 1 ] ; then
        TEST_INDEX=${SE_LIST[$RUNNING_INDEX]} 
        echo " Running case #${TEST_INDEX}"
    else
        TEST_INDEX=$RUNNING_INDEX
    fi
    startSeconds=`date +%s`
    FAILED="FALSE"
    PARAMS="$1"
    echo "     $1"
    testDataFileBase="testES_${TEST_INDEX}"
    L_TESTFILE+=(${testDataFileBase})
    pushd ${SST_ROOT}/sst-elements/src/sst/elements/ember/test
}
####################
#    SE_fini()
#          tmp_file is output from SST
#          $TL is the "complete" line from SST (with time)
#          $RL is the line from the Reference File
#
SE_fini() {
   TL=`grep Simulation.is.complete tmp_file`
   RetVal=$?
   TIME_FLAG=/tmp/TimeFlag_$$_${__timerChild} 
   if [ -e $TIME_FLAG ] ; then 
        echo " Time Limit detected at `cat $TIME_FLAG` seconds" 
        fail " Time Limit detected at `cat $TIME_FLAG` seconds" 
        rm $TIME_FLAG 
        return 
   fi 

   if [ $RetVal != 0 ] ; then 
      echo "       SST run is incomplete, FATAL" 
      fail " # $TEST_INDEX: SST run is incomplete, FATAL" 
      FAILED="TRUE"
   else
       echo $TL
       echo $1   $TL >> $SST_TEST_OUTPUTS/EmberSweep_cumulative.out
       RL=`grep $1 $SST_TEST_REFERENCE/test_EmberSweep.out`
       if [ $? != 0 ] ; then 
          echo " Can't locate this test in Reference file "
          fail " # $TEST_INDEX:  Can't locate this test in Reference file "
          FAILED="TRUE"
       else
           if [[ "$RL" != *"$TL"* ]] ; then 
               echo output does not match reference time
               echo "Reference  $RL" | awk '{print $1, $3, $4, $5, $6, $7, $8, $9}'
               echo "Out Put   $TL" 
               fail " # $TEST_INDEX:  output does not match reference time"
               FAILED="TRUE"
           fi
       fi
   fi
   if [ $FAILED == "TRUE" ] ; then
       FAILED_TESTS=$(($FAILED_TESTS + 1))
       echo ' '
       grep Ember_${1} -A 5 ${SST_ROOT}/sst-elements/src/sst/elements/ember/test/bashIN | grep sst
       echo ' '
       wc ${SST_ROOT}/sst-elements/src/sst/elements/ember/test/tmp_file
       len_tmp_file=`wc -l ${SST_ROOT}/sst-elements/src/sst/elements/ember/test/tmp_file | awk '{print $1}'`
       if [ $len_tmp_file -gt 25 ] ; then
           echo "      stdout from sst   first and last 25 lines"
           Sed 25q ${SST_ROOT}/sst-elements/src/sst/elements/ember/test/tmp_file
           echo "              . . ."      
           tail -25 ${SST_ROOT}/sst-elements/src/sst/elements/ember/test/tmp_file
           echo "    ----   end of stdout "
       else
           echo "    ----   stdout for sst:"
           cat ${SST_ROOT}/sst-elements/src/sst/elements/ember/test/tmp_file
           echo "    ----   end of stdout "
       fi
       echo ' '
   else
       echo ' '; echo Test Passed
   fi
   endSeconds=`date +%s`
   elapsedSeconds=$(($endSeconds -$startSeconds))
   echo "${TEST_INDEX}: Wall Clock Time  $elapsedSeconds sec.  ${PARAMS}"
   echo " "

}     #  - - - END OF Subroutine SE_fini()

###          Begin MAIN

#    Generate the bash input script

    if [[ ${SST_MULTI_THREAD_COUNT:+isSet} != isSet ]] ; then
        cp  ${SST_TEST_INPUTS}/EmberSweepGenerator.py .
    else
        sed '/print..sst.*model/s/sst./sst -n '"${SST_MULTI_THREAD_COUNT} /" ${SST_TEST_INPUTS}/EmberSweepGenerator.py > EmberSweepGenerator.py
        chmod +x EmberSweepGenerator.py
    fi
    if [[ ${SST_MULTI_RANK_COUNT:+isSet} == isSet ]] ; then
        sed -i.x '/print..sst.*model/s/..sst/ "mpirun -np '"${SST_MULTI_RANK_COUNT}"' sst/' EmberSweepGenerator.py 
    fi

    ./EmberSweepGenerator.py > bashIN
    if [ $? -ne 0 ] ; then 
        preFail " Test Generation FAILED"
    fi

    #     This is the code to run just a few test from the sweep
    #     Using the indices defined by SST_TEST_SE_LIST

     SE_SELECT=0
     if [[ ${SST_TEST_SE_LIST:+isSet} == isSet ]] ; then
         SE_SELECT=1
         mv bashIN bashIN0
         ICT=1
         for IND in $SST_TEST_SE_LIST
         do
             SE_LIST[$ICT]=$IND
             ICT=$(($ICT+1))
             S0=$(($IND-1))
             S1=$(($S0*6))
             START=$(($S1+1))
             END=$(($START+5))
             sed -n ${START},${END}p  bashIN0 >> bashIN
          done
     fi

#    Source the bash file

    . bashIN


export SHUNIT_OUTPUTDIR=$SST_TEST_RESULTS
popd

#    Invoke shunit2 with the bash input as a parameter!

# Invoke shunit2. Any function in this file whose name starts with
# "test"  will be automatically executed.
#                In this position the local Time Out will override the multithread TL
export SST_TEST_ONE_TEST_TIMEOUT=1900

(. ${SHUNIT2_SRC}/shunit2 ${SST_ROOT}/sst-elements/src/sst/elements/ember/test/bashIN)

