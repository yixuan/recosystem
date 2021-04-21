AC_INIT([recosystem], 0.4.4)
AC_LANG([C++])

AC_COMPILE_IFELSE(
  [AC_LANG_PROGRAM([
    #if defined(__AVX__)
    #error "doesnt_meet_requirements"
    #endif
])],
  [HASAVX=1],
  [HASAVX=0]
)

AC_COMPILE_IFELSE(
  [AC_LANG_PROGRAM([
    #if defined(__SSE3__)
    #error "doesnt_meet_requirements"
    #endif
])],
  [HASSSE3=1],
  [HASSSE3=0]
)

SIMD_CPP_FLAG=""
if test HASAVX=1; then
    SIMD_CPP_FLAG="-DUSEAVX"
else
    if test HASSSE3=1; then
        SIMD_CPP_FLAG="-DUSESSE"
    fi
fi

AC_SUBST(SIMD_CPP_FLAG)
AC_CONFIG_FILES([src/Makevars])
AC_OUTPUT
