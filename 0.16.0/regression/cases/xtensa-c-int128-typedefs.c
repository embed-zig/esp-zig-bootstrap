long long xtensa_int128_typedef_names(__uint128_t *value) {
	__int128_t shifted = (__int128_t)(*value >> 9);
	return (long long)shifted;
}
