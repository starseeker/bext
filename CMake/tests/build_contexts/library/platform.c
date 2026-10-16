#if defined(EXPECT_WINDOWS) && !defined(_WIN32)
#error The compiler is generating host objects for a Windows target
#endif
#if !defined(EXPECT_WINDOWS) && defined(_WIN32)
#error The compiler is generating Windows objects for a native target
#endif
int platform_value(void) { return 0; }
