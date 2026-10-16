#include "schema.h"
#include "Registry.h"

int main()
{
    Registry registry(SchemaInit);
    return registry.FindSchema("bext_cross") && registry.FindEntity("sample")
        ? 0 : 1;
}
