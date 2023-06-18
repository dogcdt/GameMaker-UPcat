function appr(argument0, argument1, argument2) {
	// argument0 以 argument2的速度渐近一次argument1
	
	return (argument0 > argument1 ? max(argument0 - argument2, argument1) : min(argument0 + argument2, argument1));

}
