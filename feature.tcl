proc features {path data} {
  global FEATURES SECTIONS LEVELS COVERAGE COVERED
  set numSections 0
  set sections [lindex $data 0]
  foreach section [lrange $sections 17 end] {
    set type [lindex $section 1]
    set percent [lindex $section 4]
    set childpath [format "%s" [lindex $section 0]]
    if {[string match "testplan" $type] } {
      set COVERAGE([file join $path $childpath]) $percent
      incr numSections 1
      lappend SECTIONS [file join $path $childpath]
      if {[regexp -all {/} [file join $path $childpath]] > $LEVELS} {
        set LEVELS [regexp -all {/} [file join $path $childpath]]
      }
      features [file join $path $childpath] [list $section]
    }
  } 
  if {$numSections} { set FEATURES($path) 0 } else { set FEATURES($path) 1 }
}

proc plan {path} {
  global FEATURES SECTIONS LEVELS COVERED COVERAGE
  set SECTIONS {}
  set LEVELS 0
  set data [coverage analyze -r -plansection $path -tcl]
  set type [lindex $data 0 0 1]
  set percent [lindex $data 0 0 4]
  if {[string match "testplan" $type] } {
    set COVERAGE($path) $percent
    lappend FEATURES($path) 0
    lappend COVERED($path) 0
    lappend SECTIONS $path
    incr LEVELS 1
    features $path [lindex $data 0]
  }
  foreach section $SECTIONS {
    if {$FEATURES($section) == 1} {
      if {$COVERAGE($section) == 100} {
        set COVERED($section) 1
      } else {
        set COVERED($section) 0
      }
    } else {
      set COVERED($section) 0
    }
  }
  for {set x $LEVELS} {$x != 0} {incr x -1} {
    foreach section $SECTIONS {
      if {[regexp -all {/} $section] == $x} {
        if {![string match "/" [file dirname $section]] } {
          set FEATURES([file dirname $section]) [expr $FEATURES([file dirname $section]) + $FEATURES($section)]
          set COVERED([file dirname $section]) [expr $COVERED([file dirname $section]) + $COVERED($section)]
        }
      }
    }
  }
  foreach section $SECTIONS {
    echo $FEATURES($section) $COVERED($section) [regexp -all {/} $section] $section $COVERAGE($section)
#TODO Report Questa tracker bug to display column names with space in it, for now replace space with _
    coverage attribute -path $section -name "Features" -value $FEATURES($section)
      coverage attribute -path $section -name "Features_Covered" -value $COVERED($section)
    coverage attribute -path $section -name "%Features_Covered" -value [format "%3.2f%%" [expr ($COVERED($section) / ($FEATURES($section)* 1.0)) * 100.0]]
  }
}

proc AddFeatures {testplan ucdbIn ucdbOut} {
  vsim -viewcov $ucdbIn
  plan $testplan
  coverage save $ucdbOut
}
