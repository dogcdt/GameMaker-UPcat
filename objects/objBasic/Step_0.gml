/// @description Insert description here
// You can write your code in this editor
//Calculation for pixel perfect movement


// X axis

//xx:x方向的小数缓存
xx += spdX;
moveX = floor(xx + 0.5);		//round()
xx -= moveX;

if(solid)
{
	//Actors
	stepX = sign(moveX);
	//逐像素判断
	for(i = 0; i <= abs(moveX); i++)
	{
		if(!is_solid(stepX, 0))
			x += stepX;
		else
		{
			spdX = 0;
			xx = 0;
			break;
		}
	}
}
else	//Solids
	x += moveX;

//Y axis
yy += spdY;
moveY = floor(yy + 0.5);
yy -= moveY;

if(solid)
{
	stepY = sign(moveY);
	for(i = 0; i <= abs(moveY); i++)
	{
		if(!is_solid(0, stepY))
			y += stepY;
		else
		{
			spdY = 0;
			yy = 0;
			break;
		}
	}
}
else
	y += moveY;
