package require Tcl 8.6
package require msgcat
set out [open [lindex $argv 0] w]
puts $out {int tcl_generated_value(void) { return 42; }}
close $out
