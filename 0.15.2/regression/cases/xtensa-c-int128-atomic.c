typedef unsigned __int128 u128;
typedef unsigned long long u64;

static u128 counter;

u64 xtensa_int128_atomic_fetch_add(u64 value) {
	return (u64)__atomic_fetch_add(&counter, (u128)value, 0);
}
