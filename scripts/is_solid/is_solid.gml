function is_solid(argument0, argument1) {
	// is_solid function - check for collisions on space

	// argument0 - x
	// argument1 - y

	// Check platform first, because platform is complicated
	//如果我要往下，如果我当前下方是平台但我自己不是平台，虽然平台是Actor，也判断为solid
	//这样就实现了可以从下往上站到平台上，但是不会往下掉
	if(argument1 > 0 && !place_meeting(x + argument0, y, objPlatform) && 
		place_meeting(x + argument0, y + argument1, objPlatform))
		return true;

	return !place_free(x + argument0, y + argument1);


}
