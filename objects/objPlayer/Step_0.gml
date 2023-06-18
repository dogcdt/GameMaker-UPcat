//如果暂停
if(global.pause_player) return;

// Inherit the parent event
event_inherited();

// Keep player inside room on x axis 
if(x < -1) { x = -1; spdX = 0; }
else if(x > 121) { x = 121; spdX = 0; }

// 1 右		-1 左 
inputX = global.keyRight - global.keyLeft;
// 1 下		-1 上
inputY = global.keyDown - global.keyUp;

//spikes or fall causes player death
//要么死亡碰撞(刺)，要么往下掉出地图
if(place_meeting(x, y, objSpike) || y > 128)
{
	//kill player	死亡
	global.deaths++;
	audio_play_sound(sndDeath, 10, false);
	global.shake = 10;
	
	//死亡时的八方向圆圈扩散obj
	for(i = 0; i < 8; i++)	// create death particles
	{
		deadParticleAngle = 45.0 *i ;
		newDeathParticle = instance_create_layer(x + 4, y + 4, "Player", objDeathParticle);
		newDeathParticle.spdX = 3.0*dcos(deadParticleAngle);
		newDeathParticle.spdY = 3.0*dsin(deadParticleAngle);
	}
	
	//30帧后房间重启
	objGameControl.alarm[0] = 30; // To restart room after animation
	instance_destroy(objPlayerHair);
	instance_destroy();
}



on_ground = is_solid(0, 1);
on_ice = place_meeting(x, y+1, objBlockIce);

//落地烟雾
if(on_ground && !was_on_ground)  
	instance_create_layer(x, y + 4, "Front", objSmokeParticle);


jump = global.keyJump && !p_jump;
p_jump = global.keyJump;

//将可行jump存入输入缓冲
if(jump)
	jbuffer = 4;
else if(jbuffer > 0)
	jbuffer--;
	
dash = global.keyDash && !p_dash;
p_dash = global.keyDash;

if(on_ground)
{
	grace = 6;
	if(djump < global.max_djump)
	{
		audio_play_sound(sndResetDash, 10, false);
		djump = global.max_djump;
	}
}
else if(grace > 0) grace--;


dash_effect_time--;	// To check collision with the fake wall
if(dash_time > 0)
{
	//正在冲刺中
	instance_create_layer(x, y, "Front", objSmokeParticle);
	dash_time--;
	//dash_accel_x和dash_accel_y都是正数
	spdX = appr(spdX, dash_target_x, dash_accel_x);
	spdY = appr(spdY, dash_target_y, dash_accel_y);
}
else
{
	//move
	maxrun = 1.0;
	//水平移动加速度和减速度
	accel = 0.6;
	deccel = 0.15;
	
	//空中和冰上
	if(!on_ground)
		accel = 0.4;
	else if(on_ice)
		accel = 0.05;
	
	//如果往左走人物图像翻转
	if(spdX != 0)
		flipX = (spdX < 0);
	
	//appr() - approach(A,B, v) 让A渐近B,每次最多动v
	//maxrun以外a为deccel，maxrun以内a为accel(加减速都是)
	if(abs(spdX) > maxrun)
		spdX = appr(spdX, sign(spdX)*maxrun,  deccel);
	else
		spdX = appr(spdX, inputX*maxrun, accel);
		
	//facing
	if(spdX != 0)
		flipX = (spdX < 0);
		
		
	//gravity	重力
	maxfall = 2.0;
	grav = 0.21;
	
	//半空中(顶端)重力减半
	if(abs(spdY) <= 0.15)
		grav  *= 0.5;
		
	//wall slide	贴墙下滑,贴的不是冰
	if(inputX != 0 && is_solid(inputX, 0) && !place_meeting(x+inputX, y, objBlockIce))
	{
		maxfall = 0.4;
		if(random(10) < 2)		//小概率产生烟雾
			instance_create_layer(x + inputX*6, y, "Front", objSmokeParticle);
	}
	
	//不在地上受重力,最大下落速maxfall
	if(!on_ground)
		spdY = appr(spdY, maxfall, grav);	
	
	
	//jump	处理跳跃<核心>
	if(jbuffer > 0)			//输入缓冲
	{
		if(grace > 0)		//土狼跳
		{
			audio_play_sound(sndJump, 10, false);
			jbuffer = 0;
			grace = 0;
			spdY = -2.0;
			instance_create_layer(x, y + 4, "Front", objSmokeParticle);
		}
		else
		{
			//wall jump		蹬墙跳
			wall_dir = (is_solid(-3, 0) ? -1 : (is_solid(3, 0)? 1 : 0));
			if(wall_dir != 0)
			{
				audio_play_sound(sndWallJump, 10, false);
				jbuffer = 0;
				spdY = -2.0;
				spdX = -wall_dir * (maxrun + 1.0);		//墙的反方向(最大速度加1)
				if(place_meeting(x + wall_dir*3, y, objBlockIce))
					instance_create_layer(x + wall_dir*6, y, "Front", objSmokeParticle);
			}
		}
	}


	//dash	处理冲刺<核心>
	d_full = 5.0;
	d_half = d_full * 0.70710678118;

	if(djump > 0 && dash)
	{
		instance_create_layer(x, y, "Front", objSmokeParticle);
		djump--;
		dash_time = 4;
		global.has_dashed = true;
		dash_effect_time = 10;
		
		if(inputX != 0)
		{
			if(inputY != 0)		//斜冲
			{
				spdX = inputX * d_half;
				spdY = inputY * d_half;
			}
			else				//横冲
			{
				spdX = inputX * d_full;
				spdY = 0;
			}
		}
		else if(inputY != 0)	//竖冲
		{
			spdX = 0;
			spdY = inputY * d_full;
		}
		else		//如果未按下方向键则往player面向方向冲
		{
			spdX = (flipX? -1 : 1) * d_full;
			spdY = 0;
		}

		audio_play_sound(sndDash, 10, false);
		global.shake = 6;
		
		//冲刺最大速度 , 5->2
		dash_target_x = 2*sign(spdX);
		dash_target_y = 2*sign(spdY);
		//冲刺加速度
		dash_accel_x = 1.5;
		dash_accel_y = 1.5;

		//斜冲判断
		if(spdY < 0)	
			dash_target_y *= 0.75;
		if(spdY != 0)
			dash_accel_x *= 0.70710678118;
		if(spdX != 0)
			dash_accel_y *= 0.70710678118;
	}
	else if(dash && djump <= 0)			//想冲但是次数不够
	{
		// Out of dashes!!!
		instance_create_layer(x, y + 4, "Front", objSmokeParticle);
		audio_play_sound(sndNoDash, 10, false);
	}
		
}
	
	
// animation
if(!on_ground)	//空中
{// on-air
	
	// wall-climb		爬墙
	if(is_solid(inputX, 0)) { image_index = 4; image_speed = 0; }
	// on-air			普通空中
	else { image_index = 2; image_speed = 0; }	
}

//地上
// look down			往下看
else if(global.keyDown) { image_index = 5; image_speed = 0; }
// look up				往上看
else if(global.keyUp) { image_index = 6; image_speed = 0; }
// idle					静止
else if( spdX == 0 || inputX == 0) { image_index = 0; image_speed = 0; }
else 
{// moving horizontally			走路，每四帧变一张
	sprOffset += 0.25; if(sprOffset > 4) sprOffset = 0.0;
	image_index = sprOffset % 4; 
}
		
//Select sprite			素材选择
if(djump == 2) {
	if( (global.step/3) % 2 )
		sprite_index = (flipX ? sprPlayerWhiteLeft : sprPlayerWhite);	
	else
		sprite_index = (flipX ? sprPlayerGreenLeft : sprPlayerGreen);
}
else if(djump == 1)
	sprite_index = (flipX ? sprPlayerRedLeft : sprPlayerRed);
else
	sprite_index = (flipX ? sprPlayerBlueLeft : sprPlayerBlue);


//如果到达窗口顶端并且不是最后一关
//next level
//if (y < -4 && global.level_index < 30)
if (y < -4)
{
	global.level_index++;
	//*
	room_goto_next() 
	//room_restart();
}

was_on_ground = on_ground;
	






