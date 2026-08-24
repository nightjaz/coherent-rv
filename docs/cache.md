# Caches

The instruction cache is read-only and direct-mapped. The data cache is direct-mapped, write-back, write-allocate, and MESI-coherent. `CACHE_SIZE` and `LINE_SIZE` parameters determine set count; both must be powers of two and a line contains 32-bit words. CPU requests are blocking. Dirty replacement writes a complete line before acquisition. Byte enables merge SB/SH/SW stores into cached words.

Performance outputs count hits, misses, and writebacks. The shared bus counts BusRd, BusRdX, BusUpgr, and invalidations. Generated benchmark reports must use these signals; numbers are never hand-authored.
