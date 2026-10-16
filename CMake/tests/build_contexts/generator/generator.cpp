#include <fstream>

int main(int argc, char **argv)
{
    if (argc != 2) return 1;
    std::ofstream out(argv[1]);
    out << "int generated_value(void) { return 42; }\n";
    return out.good() ? 0 : 1;
}
