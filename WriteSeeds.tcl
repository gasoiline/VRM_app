# This procedure reads the output files from Questa's ranking report
# and generates a file of testnames and seeds that achieve the highest
# coverage
proc ExtractSeedsFromRankingFile {INFILE OUTFILE} {
   set outFile [open $OUTFILE w]
   if {[file exist $INFILE]} {
     set inFile [open $INFILE r]
     set line [read $inFile]
     set ucdbfile [lindex $line 2 2 0]
     if {[file exist $ucdbfile]} {
       foreach record [lindex $line 2 13] {
         if {![info exist high]} {set high [lindex $record 7]}
         if { $high <= [lindex $record 7] }  {
           set seed [lindex [vcover attribute -test [lindex [lindex [lindex $record 11] 0] 1] -name SEED $ucdbfile -tcl -concise] 0]
           set testname [lindex [vcover attribute -test [lindex [lindex [lindex $record 11] 0] 1] -name TESTNAME $ucdbfile -tcl -concise] 0]
           # Extract the testname from the VRM name, i.e Simulate~testmode_random_1 becomes testmode
           set testname [lindex [split [lindex [split $testname "~"] 1] "."] 0]
           if {$seed != 0}  {
             puts $outFile [format "%s 1 %s" $testname $seed]
           }
         }
       }
     }
     close $inFile
   }
   close $outFile
}

# This procedure reads a testfile for the testnames and the number of
# times the test needs to be run. It then uses a results file output for
# the ranking process by the procedure above and generates a new
# testfile that has the optimized seeds next to each test. If a test
# doesn't have enough test seeds for all of its runs then it will be
# left blank so a random one is used.
proc WriteToTestFile {TFILE RFILE OUTFILE} {
   set tfile [open $TFILE r]
   set outFile [open $OUTFILE w]
   while {![eof $tfile]} {
     gets $tfile line
     if {[string range $line 0 0] != "#"} {
       if {[llength $line] != 0} {
         set testname [lindex $line 0]
         set numtests [lindex $line 1]
         set rfile [open $RFILE r]
         set seeds ""
         set numSeeds $numtests
         gets $rfile line
         while {![eof $rfile]} {
           set resultTest [lindex $line 0]
           if {$numSeeds != 0} {
             if {[string match $testname $resultTest]} {
               set seed [lindex $line 1]
               append seeds [format "%s " $seed]
               incr numSeeds -1
             }
           }
           gets $rfile line
         }
         close $rfile
         puts $outFile [format "%s %s %s" $testname $numtests $seeds]
       }
     }
   }
   close $tfile
   close $outFile
}
