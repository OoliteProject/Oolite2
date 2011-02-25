#if __ppc__ || __ppc664__
#include "../mozilla/nsprpub/pr/src/md/unix/os_Darwin_ppc.s"
#elif __i386__
#include "../mozilla/nsprpub/pr/src/md/unix/os_Darwin_x86.s"
#elif __x86_64__
#include "../mozilla/nsprpub/pr/src/md/unix/os_Darwin_x86_64.s"
#endif
