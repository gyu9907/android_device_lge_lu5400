/* CM12.1 RefBase.cpp provides this legacy ABI under
 * REFBASE_JB_MR1_COMPAT_SYMBOLS. The LG camera imports it; keep the same
 * no-op implementation in its device-only compatibility dependency rather
 * than enabling legacy symbols for every target or host library.
 * RefBase reference tracking is disabled in the production libutils build.
 */
#include <stddef.h>

namespace android { class ReferenceConverterBase; }

extern "C" void
_ZN7android7RefBase14moveReferencesEPvPKvjRKNS_22ReferenceConverterBaseE(
        void *, const void *, size_t, const android::ReferenceConverterBase &)
{
}
