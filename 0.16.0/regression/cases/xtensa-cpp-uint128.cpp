using u128 = unsigned __int128;

extern "C" unsigned long long xtensa_cpp_uint128_mix(unsigned long long value) {
	u128 wide = (u128)value * ((u128)value + 7);
	return (unsigned long long)(wide >> 5);
}
