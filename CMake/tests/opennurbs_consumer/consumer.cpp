#include <opennurbs.h>

static_assert(sizeof(ON_UUID) == 16, "UUID layout");
static_assert(sizeof(ON__INT64) == 8, "64-bit integer layout");
static_assert(sizeof(ON__UINT_PTR) == sizeof(void *), "Pointer layout");

int main()
{
    ON::Begin();
    ON_UUID id;
    if (!ON_CreateUuid(id) || ON_UuidIsNil(id))
        return 1;
    ON_wString formatted;
    formatted.Format(L"%ls %d", L"Windows", 42);
    if (formatted != L"Windows 42")
        return 2;
    int number = 0;
    if (ON_String::ScanBuffer("42", "%d", &number) != 1 || number != 42)
        return 3;
    if (!ON_FileSystem::IsDirectory(L"."))
        return 4;
    ON_FileIterator iterator;
    if (!iterator.Initialize(L".") || !iterator.FirstItem())
        return 5;
    return 0;
}
