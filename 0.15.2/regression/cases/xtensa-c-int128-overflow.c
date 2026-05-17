typedef unsigned __int128 u128;
typedef unsigned long long u64;

int xtensa_int128_add_overflow(const u128 *lhs, const u128 *rhs, u64 *out) {
	u128 sum;
	const int overflowed = __builtin_add_overflow(*lhs, *rhs, &sum);

	*out = (u64)sum ^ (u64)(sum >> 64);
	return overflowed;
}
