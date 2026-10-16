package require Tcl 8.6
if {[package vcompare [info patchlevel] 8.7] >= 0} {
    error "The build scripts require the Tcl 8.6 series"
}
# Exercise the installed script library, not just the executable's version.
package require msgcat
if {[::msgcat::mc {native Tcl is runnable}] ne {native Tcl is runnable}} {
    error "Native Tcl script library did not initialize"
}
puts "Native Tcl [info patchlevel] ($tcl_platform(os)) is runnable"
