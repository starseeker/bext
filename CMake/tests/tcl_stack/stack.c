#include <tcl.h>
#include <tk.h>
#include <itcl.h>
#include <itk.h>

/* Compile/link against the installed interfaces, independently of the source
 * build trees.  Loading this extension requires the target Tcl/Tk runtime. */
DLLEXPORT int Bextstack_Init(Tcl_Interp *interp)
{
    if (!Tcl_InitStubs(interp, "8.6", 0) ||
        !Tk_InitStubs(interp, "8.6", 0) ||
        !Itcl_InitStubs(interp, "4.3", 0) ||
        !Itk_InitStubs(interp, "4.2", 0)) {
        return TCL_ERROR;
    }
    return Tcl_PkgProvide(interp, "bextstack", "1.0");
}
