typedef unsigned int u32;
typedef unsigned long long u64;
typedef unsigned __int128 u128;

u64 xtensa_uint128_mix(u64 hi, u64 lo, u32 shift) {
	const u32 amount = shift & 63;
	u128 wide = ((u128)hi << 64) | (u128)lo;

	wide += (u128)1 << amount;
	wide ^= wide >> 17;
	return (u64)(wide >> amount);
}
