#include <a_samp>
#include <sscanf2>
#include <zcmd>
#include <a_mysql>
#include <streamer>

#define function%0(%1)   forward %0(%1); public %0(%1)
#define SCM SendClientMessage

//COLORS
#define COLOR_RED 0xAA3333AA
#define MAX_JOBS 20
#define MAX_HOUSES 200

//enums
enum pInfo {
	pSQLID,
	pName[MAX_PLAYER_NAME],
	pPassword[32],
	pEmail[32],
	pGender,
	pSkin,
	pMoney,
	pBankMoney,
	pLevel,
	pLoggedIn,
	pJob,
	pAdminLevel,
}

new pizzas[MAX_PLAYERS] = 0, isWorkingPizza[MAX_PLAYERS] = false, pizzaVehicle[MAX_PLAYERS], playername[MAX_PLAYER_NAME],
lastCar[MAX_PLAYERS], timerid[MAX_PLAYERS], jobs;

enum pkInfo {
	pkID,
	pkType
}
new PickupInfo[MAX_PICKUPS][pkInfo];

enum jInfo {
	jId,
	jName[20],
	Float:jLocationX,
	Float:jLocationY,
	Float:jLocationZ,
}

new JobInfo[MAX_JOBS][jInfo];

enum hInfo {
	hId,

	Float:hEntranceX,
	Float:hEntranceY,
	Float:hEntranceZ,

	Float:hExitX,
	Float:hExitY,
	Float:hExitZ,

	interiorID,
	hPickupID
}

new HouseInfo[MAX_HOUSES][hInfo];

enum {
	//Register
	DIALOG_REGISTER,
	DIALOG_EMAIL,
	DIALOG_GENDER,

	//Login
	DIALOG_LOGIN
}

//globals
new PlayerInfo[MAX_PLAYERS][pInfo];
new MySQL:SQL;
new gQuery[256];
new loginAttempts[MAX_PLAYERS] = 0;

main() 
{
	// write code here and run "sampctl package build" to compile
	// then run "sampctl package run" to run it
}


new vehmodel_names[][] =
{
    "Landstalker", "Bravura", "Buffalo", "Linerunner", "Perrenial", "Sentinel",
    "Dumper", "Firetruck", "Trashmaster", "Stretch", "Manana", "Infernus",
    "Voodoo", "Pony", "Mule", "Cheetah", "Ambulance", "Leviathan", "Moonbeam",
    "Esperanto", "Taxi", "Washington", "Bobcat", "Whoopee", "BF Injection",
    "Hunter", "Premier", "Enforcer", "Securicar", "Banshee", "Predator", "Bus",
    "Rhino", "Barracks", "Hotknife", "Trailer", "Previon", "Coach", "Cabbie",
    "Stallion", "Rumpo", "RC Bandit", "Romero", "Packer", "Monster", "Admiral",
    "Squalo", "Seasparrow", "Pizzaboy", "Tram", "Trailer", "Turismo", "Speeder",
    "Reefer", "Tropic", "Flatbed", "Yankee", "Caddy", "Solair", "Berkley's RC Van",
    "Skimmer", "PCJ-600", "Faggio", "Freeway", "RC Baron", "RC Raider", "Glendale",
    "Oceanic","Sanchez", "Sparrow", "Patriot", "Quad", "Coastguard", "Dinghy",
    "Hermes", "Sabre", "Rustler", "ZR-350", "Walton", "Regina", "Comet", "BMX",
    "Burrito", "Camper", "Marquis", "Baggage", "Dozer", "Maverick", "News Chopper",
    "Rancher", "FBI Rancher", "Virgo", "Greenwood", "Jetmax", "Hotring", "Sandking",
    "Blista Compact", "Police Maverick", "Boxville", "Benson", "Mesa", "RC Goblin",
    "Hotring Racer A", "Hotring Racer B", "Bloodring Banger", "Rancher", "Super GT",
    "Elegant", "Journey", "Bike", "Mountain Bike", "Beagle", "Cropduster", "Stunt",
    "Tanker", "Roadtrain", "Nebula", "Majestic", "Buccaneer", "Shamal", "Hydra",
    "FCR-900", "NRG-500", "HPV1000", "Cement Truck", "Tow Truck", "Fortune",
    "Cadrona", "FBI Truck", "Willard", "Forklift", "Tractor", "Combine", "Feltzer",
    "Remington", "Slamvan", "Blade", "Freight", "Streak", "Vortex", "Vincent",
    "Bullet", "Clover", "Sadler", "Firetruck", "Hustler", "Intruder", "Primo",
    "Cargobob", "Tampa", "Sunrise", "Merit", "Utility", "Nevada", "Yosemite",
    "Windsor", "Monster", "Monster", "Uranus", "Jester", "Sultan", "Stratium",
    "Elegy", "Raindance", "RC Tiger", "Flash", "Tahoma", "Savanna", "Bandito",
    "Freight Flat", "Streak Carriage", "Kart", "Mower", "Dune", "Sweeper",
    "Broadway", "Tornado", "AT-400", "DFT-30", "Huntley", "Stafford", "BF-400",
    "News Van", "Tug", "Trailer", "Emperor", "Wayfarer", "Euros", "Hotdog", "Club",
    "Freight Box", "Trailer", "Andromada", "Dodo", "RC Cam", "Launch", "Police Car",
    "Police Car", "Police Car", "Police Ranger", "Picador", "S.W.A.T", "Alpha",
    "Phoenix", "Glendale", "Sadler", "Luggage", "Luggage", "Stairs", "Boxville",
    "Tiller", "Utility Trailer"
};

IsVehicleInRangeOfPlayer(vehicleid, playerid, Float:range, bool:ignoreVW = false)
{
	new Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2;

	return GetVehiclePos(vehicleid, x1, y1, z1) && GetPlayerPos(playerid, x2, y2, z2) && VectorSize(x1 - x2, y1 - y2, z1 - z2) <= range
		&& (ignoreVW || GetVehicleVirtualWorld(vehicleid) == GetPlayerVirtualWorld(playerid));
}

public OnGameModeInit()
{
	SetGameModeText("unknown");

	SQL = mysql_connect("localhost", "root", "", "unknowndb");
	if(mysql_errno() != 0) print("Could not connect to database!");
	else{
	}

	DisableInteriorEnterExits();
	EnableStuntBonusForAll(false);

	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	//jobs
	mysql_tquery(SQL, "SELECT * FROM `jobs`", "loadJobs", "");
	mysql_tquery(SQL, "SELECT * FROM `houses`", "loadProperties", "");
	//CreateDynamicPickup(1275, 0, 2096.7034, -1800.0417, 13.3828);
	//CreateDynamic3DTextLabel("id: 0\nJob: pizza delivery\nUse /getjob to get the job.", -1, 2096.7034, -1800.0417, 13.3828, 15.0);

	// AddPlayerClass(0,2096.7034,-1800.0417,13.3828,90.9737,0,0,0,0,0,0); //
	return 1;
}

function loadProperties()
{
	new houses = cache_num_rows();
	printf("number of houses: %d", houses);
	new housetextlabel[40];

	for(new house = 0; house < houses; house++)
	{
		cache_get_value_name_int(house, "ID", HouseInfo[house][hId]);

		cache_get_value_name_float(house, "EntranceX", HouseInfo[house][hEntranceX]);
		cache_get_value_name_float(house, "EntranceY", HouseInfo[house][hEntranceY]);
		cache_get_value_name_float(house, "EntranceZ", HouseInfo[house][hEntranceZ]);

		cache_get_value_name_float(house, "ExitX", HouseInfo[house][hExitX]);
		cache_get_value_name_float(house, "ExitY", HouseInfo[house][hExitY]);
		cache_get_value_name_float(house, "ExitZ", HouseInfo[house][hExitZ]);

		HouseInfo[house][hPickupID] = CreateDynamicPickup(1272, 23, HouseInfo[house][hEntranceX], HouseInfo[house][hEntranceY], HouseInfo[house][hEntranceZ]);
		format(housetextlabel, sizeof(housetextlabel), "id: %d", HouseInfo[house][hId]);
		CreateDynamic3DTextLabel(housetextlabel, -1, HouseInfo[house][hEntranceX], HouseInfo[house][hEntranceY], HouseInfo[house][hEntranceZ], 15.0);
	}

	return 1;
}

function loadJobs()
{
	jobs = cache_num_rows();
	printf("number of jobs: %d", jobs);

	new jobtextlabel[100];
	for(new job = 0; job < jobs; job++)
	{
		cache_get_value_name_int(job, "ID", JobInfo[job][jId]);
		cache_get_value_name(job, "Name", JobInfo[job][jName]);
		cache_get_value_name_float(job, "LocationX", JobInfo[job][jLocationX]);
		cache_get_value_name_float(job, "LocationY", JobInfo[job][jLocationY]);
		cache_get_value_name_float(job, "LocationZ", JobInfo[job][jLocationZ]);

		CreateDynamicPickup(1275, 23, JobInfo[job][jLocationX], JobInfo[job][jLocationY], JobInfo[job][jLocationZ]);
		format(jobtextlabel, sizeof(jobtextlabel), "id: %d\nJob: %s\nUse /getjob to get the job.", JobInfo[job][jId], JobInfo[job][jName]);
		CreateDynamic3DTextLabel(jobtextlabel, -1, JobInfo[job][jLocationX], JobInfo[job][jLocationY], JobInfo[job][jLocationZ], 15.0);
	}
}

CMD:addhouse(playerid, params[])
{
	new Float:x, Float:y, Float:z, interiorid;
	if(sscanf(params, "i", interiorid)) return SCM(playerid, -1, "usage: /addhouse <interiorid>");
	GetPlayerPos(playerid, x, y, z);

	new pickupid = CreateDynamicPickup(1272, 23, x, y, z);
	new message[128];

	format(message, sizeof(message), "pickupid: %d", pickupid);
	SCM(playerid, -1, message);

	mysql_format(SQL, gQuery, sizeof(gQuery), "INSERT INTO `houses`(`InteriorID`, `EntranceX`, `EntranceY`, `EntranceZ`) VALUES ('%d','%f','%f', '%f')", interiorid, x, y, z);
	mysql_tquery(SQL, gQuery, "InsertHouse", "i", playerid);

	return 1;
}

function InsertHouse(playerid)
{
	new houseID = cache_insert_id(), textlabel[40], Float:x, Float:y, Float:z;
	
	printf("houseid: %d", houseID);

	GetPlayerPos(playerid, x, y, z);

	format(textlabel, sizeof(textlabel), "id: %d", houseID);
	CreateDynamic3DTextLabel(textlabel, -1, x, y, z, 15.0);
}

public OnGameModeExit()
{
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	// SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	// SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);

	return 1;
}

public OnPlayerConnect(playerid)
{

	GetPlayerName(playerid, playername, sizeof(playername));
	mysql_format(SQL, gQuery, sizeof(gQuery), "SELECT * FROM `users` WHERE `Name` LIKE '%e'", playername);	
	mysql_tquery(SQL, gQuery, "checkAccount", "d", playerid);

	SetPlayerPos(playerid, 2094.2788,-1816.7831,13.3828);
	// SetPlayerPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraPos(playerid, 1958.3783, 1343.1572, 15.3746);
	SetPlayerCameraLookAt(playerid, 1958.3783, 1343.1572, 15.3746);

	PlayerInfo[playerid][pLoggedIn] = false;

	if(SQL == MySQL:0)
	{
		SCM(playerid, -1, "db error");
		return Kick(playerid);
	}

	return 1;
}

function checkAccount(playerid)
{
	printf("cache_num_rows(): %d", cache_num_rows());
	if(cache_num_rows())
	{
		new caption[10], info[128], button1[10], button2[10];
		format(caption, sizeof(caption), "login");
		format(info, sizeof(info), "please enter the password");
		format(button1, sizeof(button1), "login");
		format(button2, sizeof(button2), "cancel");
		// ShowPlayerDialog(playerid, dialogid, style, info[], info[], button1[], button2[])
		SCM(playerid, -1, "please login.");
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, caption, info, button1, button2);
	}
	else
	{
		new caption[10], info[128], button1[10], button2[10];
		new pname[MAX_PLAYER_NAME];
		GetPlayerName(playerid, pname, sizeof(pname));

		SCM(playerid, -1, "please register.");

		format(caption, sizeof(caption), "register");
		format(info, sizeof(info), "please enter a password.");
		format(button1, sizeof(button1), "register");
		format(button2, sizeof(button2), "cancel");
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, caption, info, button1, button2);
	} 
}

function updateDatabase(playerid)
{
	new pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, sizeof(pname));

	mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Job`='%d' WHERE `Name` LIKE '%s'", PlayerInfo[playerid][pJob], pname);
	mysql_tquery(SQL, gQuery, "", "");

	mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Level`='%d' WHERE `Name` LIKE '%s'", PlayerInfo[playerid][pLevel], pname);
	mysql_tquery(SQL, gQuery, "", "");

	mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Money`='%d' WHERE `Name` LIKE '%s'", PlayerInfo[playerid][pMoney], pname);
	mysql_tquery(SQL, gQuery, "", "");

	mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `BankMoney`='%d' WHERE `Name` LIKE '%s'", PlayerInfo[playerid][pBankMoney], pname);
	mysql_tquery(SQL, gQuery, "", "");

	mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Level`='%d' WHERE `Name` LIKE '%s'", PlayerInfo[playerid][pLevel], pname);
	mysql_tquery(SQL, gQuery, "", "");

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	updateDatabase(playerid);
	GetPlayerName(playerid, playername, sizeof(playername));
	new message[40];
	format(message, sizeof(message), "%s left. reason: %s", playername, reason);
	SendClientMessageToAll(-1, message);
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_REGISTER: {
			//SCM(playerid, -1, "register pressed");
			if(response == 0) Kick(playerid);
			else {

				new pname[MAX_PLAYER_NAME];
				new caption[10], info[128], button1[10], button2[10];

				GetPlayerName(playerid, pname, sizeof(pname));

				mysql_format(SQL, gQuery, sizeof(gQuery), "INSERT INTO `users`(`Name`, `Password`) VALUES ('%s','%s')", pname, inputtext);
				mysql_tquery(SQL, gQuery, "insertAccount", "i", playerid);

				//show email dialog
				format(PlayerInfo[playerid][pName], MAX_PLAYER_NAME, pname);
				format(caption, sizeof(caption), "email");
				format(info, sizeof(info), "please enter your email");
				format(button1, sizeof(button1), "ok");
				format(button2, sizeof(button2), "cancel");

				ShowPlayerDialog(playerid, DIALOG_EMAIL, DIALOG_STYLE_INPUT, caption, info, button1, button2);
			}
		}

		case DIALOG_EMAIL: {
			//SCM(playerid, -1, "login pressed");
			new pname[MAX_PLAYER_NAME];
			GetPlayerName(playerid, pname, sizeof(pname));

			new caption[10], info[128], button1[10], button2[10], funcName[20];
			if(response == 0) {
				mysql_format(SQL, gQuery, sizeof(gQuery), "DELETE FROM `users` WHERE `Name` LIKE '%s'", pname);
				mysql_tquery(SQL, gQuery, "", "");
				Kick(playerid); 
			} 
			else {

				mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Email`='%s' WHERE `Name` LIKE '%s'", inputtext, pname);
				mysql_tquery(SQL, gQuery, "", "");

				format(caption, sizeof(caption), "gender");
				format(info, sizeof(info), "please select your gender");
				format(button1, sizeof(button1), "male");
				format(button2, sizeof(button2), "female");
				format(PlayerInfo[playerid][pEmail], MAX_PLAYER_NAME, inputtext);
				ShowPlayerDialog(playerid, DIALOG_GENDER, DIALOG_STYLE_MSGBOX, caption, info, button1, button2);

				mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Level`='%d' WHERE `Name` LIKE '%s'", 0, pname);
				mysql_tquery(SQL, gQuery, "", "");

				mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Money`='%d' WHERE `Name` LIKE '%s'", 15000, pname);
				mysql_tquery(SQL, gQuery, "", "");

				mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `BankMoney`='%d' WHERE `Name` LIKE '%s'", 0, pname);
				mysql_tquery(SQL, gQuery, "", "");

				mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Job`='%d' WHERE `Name` LIKE '%s'", -1, pname);
				mysql_tquery(SQL, gQuery, "", "");

				PlayerInfo[playerid][pLevel] = 0;
				PlayerInfo[playerid][pMoney] = 15000;
				PlayerInfo[playerid][pBankMoney] = 0;
				PlayerInfo[playerid][pJob] = -1;

				format(funcName, sizeof(funcName), "updateDatabase");
				SetTimerEx(funcName, 60000, true, "i", playerid);
			}
		}

		case DIALOG_GENDER: {
			new pname[MAX_PLAYER_NAME];
			GetPlayerName(playerid, pname, sizeof(pname));

			mysql_format(SQL, gQuery, sizeof(gQuery), "UPDATE `users` SET `Gender`='%d' WHERE `Name` LIKE '%s'", response, pname);
			mysql_tquery(SQL, gQuery, "", "");


			// format(PlayerInfo[playerid][pGender], MAX_PLAYER_NAME, response);

			PlayerInfo[playerid][pGender] = response;
			
			SpawnPlayer(playerid);
			SetPlayerPos(playerid, 2094.2788,-1816.7831,13.3828);
			PlayerInfo[playerid][pLoggedIn] = true;
			GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
		}

		case DIALOG_LOGIN: {
			//SCM(playerid, -1, "login pressed");
			if(response == 0) Kick(playerid);

			new pname[MAX_PLAYER_NAME];
			GetPlayerName(playerid, pname, sizeof(pname));
			mysql_format(SQL, gQuery, sizeof(gQuery), "SELECT * FROM `users` WHERE `Name` LIKE '%s' AND `Password` LIKE '%s'", pname, inputtext);
			mysql_tquery(SQL, gQuery, "loginAccount", "i", playerid);
		}
		
	}

	return 0;
}

function loginAccount(playerid)
{
	if(cache_num_rows())
	{
		new message[128], pname[MAX_PLAYER_NAME], funcName[20];

		GetPlayerName(playerid, pname, sizeof(pname));
		format(message, sizeof(message), "login successful. welcome %s.", pname);
		SCM(playerid, -1, message);
		SpawnPlayer(playerid);
		format(funcName, sizeof(funcName), "updateDatabase");
		SetTimerEx(funcName, 60000, true, "i", playerid);

		new result[128];
		cache_get_value_name(0, "Name", result);
		format(PlayerInfo[playerid][pName], MAX_PLAYER_NAME, result);
		printf("The value in the column 'Name' is '%s'.", PlayerInfo[playerid][pName]);

		cache_get_value_name(0, "Password", result);
		format(PlayerInfo[playerid][pPassword], 32, result);
		printf("The value in the column 'Password' is '%s'.", PlayerInfo[playerid][pPassword]);

		cache_get_value_name(0, "Email", result);
		format(PlayerInfo[playerid][pEmail], 32, result);
		printf("The value in the column 'Email' is '%s'.", PlayerInfo[playerid][pEmail]);

		new gender;
	    cache_get_value_name_int(0, "Gender", gender);
		PlayerInfo[playerid][pGender] =	gender;
		// format(PlayerInfo[playerid][pGender], 32, result);
		printf("The value in the column 'Gender' is '%d'.", PlayerInfo[playerid][pGender]);

		new job;
	    cache_get_value_name_int(0, "Job", job);
		PlayerInfo[playerid][pJob] = job;
		printf("The value in the column 'Job' is '%d'.", PlayerInfo[playerid][pJob]);

		new money;
	    cache_get_value_name_int(0, "Money", money);
		PlayerInfo[playerid][pMoney] = money;
		printf("The value in the column 'Money' is '%d'.", PlayerInfo[playerid][pMoney]);

		new bankmoney;
	    cache_get_value_name_int(0, "BankMoney", bankmoney);
		PlayerInfo[playerid][pBankMoney] = bankmoney;
		printf("The value in the column 'BankMoney' is '%d'.", PlayerInfo[playerid][pBankMoney]);

		GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
		PlayerInfo[playerid][pLoggedIn] = true;

		new level;
	    cache_get_value_name_int(0, "Level", level);
		PlayerInfo[playerid][pLevel] = level;
		printf("The value in the column 'Level' is '%d'.", PlayerInfo[playerid][pLevel]);
		SetPlayerScore(playerid, PlayerInfo[playerid][pLevel]);

		SetPlayerPos(playerid, 2094.2788,-1816.7831,13.3828);
	}
	else
	{
		new message[128];
		loginAttempts[playerid] += 1;
		new caption[10], info[128], button1[10], button2[10];
		if(loginAttempts[playerid] == 3)
		{
			SCM(playerid, -1, "wrong password. (3/3 attempts)");
			Kick(playerid);
		}
		else
		{
			format(message, sizeof(message), "wrong password, try again. (%d/3 attempts)", loginAttempts);

			SCM(playerid, -1, message);
			format(caption, sizeof(caption), "login");
			format(info, sizeof(info), "please enter the password");
			format(button1, sizeof(button1), "login");
			format(button2, sizeof(button2), "cancel");
			ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, caption, info, button1, button2);
		}
	}

}

function insertAccount(playerid)
{
	new message[128], pname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, pname, sizeof(pname));
	format(message, sizeof(message), "%s(%d) joined.", pname, playerid);
	SendClientMessageToAll(-1, message);

	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(!PlayerInfo[playerid][pLoggedIn])
	{
		SCM(playerid, COLOR_RED, "you are not logged in!");
		Kick(playerid);
	} 

	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	return 1;
}

CMD:work(playerid)
{
	if(PlayerInfo[playerid][pJob] == -1) return SCM(playerid, -1, "you do not have a job!");
	if(isWorkingPizza[playerid]) return SCM(playerid, -1, "you are already working!");

	//player's job is pizza delivery
	if(PlayerInfo[playerid][pJob] == 0)
	{
		if(!IsPlayerInRangeOfPoint(playerid, 5.0, 2115.3057,-1776.4438,13.3912))
		{
			SetPlayerCheckpoint(playerid, 2115.3057,-1776.4438,13.3912, 5.0);

			SCM(playerid, -1, "you are not in the right location to start working!");
			SCM(playerid, -1, "go to the checkpoint and use /work.");
		}
		else
		{
			SCM(playerid, -1, "start work");
			isWorkingPizza[playerid] = true;
			pizzas[playerid] = 7;

			new Float:x, Float:y, Float:z;
			new Float:ang;
			GetPlayerFacingAngle(playerid, ang);
			GetPlayerPos(playerid, x, y,z);
			pizzaVehicle[playerid] = CreateVehicle(448, x, y, z, ang, -1, -1, -1);
			PutPlayerInVehicle(playerid, pizzaVehicle[playerid], 0);
			lastCar[playerid] = pizzaVehicle[playerid];
		}
	}
	
	return 1;
}

CMD:getjob(playerid)
{
	//pizza delivery
	if(IsPlayerInRangeOfPoint(playerid, 5.0, 2096.7034, -1800.0417, 13.3828))
	{
		if(PlayerInfo[playerid][pJob] != -1) return SCM(playerid, -1, "you already have a job! use /quitjob to quit the job.");
		PlayerInfo[playerid][pJob] = 0;
		SCM(playerid, -1, "");
		SCM(playerid, -1, "you got the job!");
		SCM(playerid, -1, "use /work to deliver pizzas.");
	}
	return 1;
}

CMD:quitjob(playerid)
{
	PlayerInfo[playerid][pJob] = -1;
	DestroyVehicle(pizzaVehicle[playerid]);
	DisablePlayerCheckpoint(playerid);
	SCM(playerid, -1, "you quit your job!");
	return 1;
}

CMD:stats(playerid)
{
	SCM(playerid, -1, "");
	new message[128];
	new gender[10];
	new job[40];

	if(PlayerInfo[playerid][pGender] == 1) format(gender, sizeof(gender), "male");
	else format(gender, sizeof(gender), "female");

	format(message, sizeof(message), "id: %d | name: %s | email: %s | gender: %s | level: %d | hours played: ", playerid, PlayerInfo[playerid][pName], PlayerInfo[playerid][pEmail], gender, PlayerInfo[playerid][pLevel]);
	SCM(playerid, -1, message);

	if(PlayerInfo[playerid][pJob] == -1) format(job, sizeof(job), "none");
	if(PlayerInfo[playerid][pJob] == 0) format(job, sizeof(job), "pizza delivery");
	format(message, sizeof(message), "cash: %d$ | bank money: %d$ | job: %s |", PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pBankMoney], job);
	SCM(playerid, -1, message);
	return 1;
}

CMD:fixveh(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid);

	SetVehicleHealth(vehicleid, 1000.0);
	SCM(playerid, -1, "vehicle repaired.");
	return 1;
}

CMD:vehname(playerid, params[])
{
	new vehname[40], message[128];
	if(sscanf(params, "s[40]", vehname)) return SCM(playerid, 0xEB4034, "usage: /vehname <vehname>.");

	for(new vehicle = 0; vehicle < sizeof(vehmodel_names); vehicle++)
	{
		// format(message, sizeof(message), "sizeof(vehmodel_names): %d", sizeof(vehmodel_names));
		// SCM(playerid, -1, message);
		if(!strcmp(vehmodel_names[vehicle], vehname, true, strlen(vehname)))
		{
			format(message, sizeof(message), "vehicle name: %s - ID: %d", vehmodel_names[vehicle], vehicle + 400);
			SCM(playerid, -1, message);
		}

	}

	// format(message, sizeof(message), "vehname: %s", vehname);
	// SCM(playerid, -1, message);
	return 1;
}

CMD:spawnveh(playerid, params[])
{
	new Float:x, Float:y, Float:z;
	new modelid[30];
	new message[128];

	if(sscanf(params, "s[30]", modelid)) return SCM(playerid, -1, "usage: /spawnveh <vehicleid>.");

	GetPlayerPos(playerid, x, y, z);

	if(IsNumeric(modelid))
	{
		if(strval(modelid) < 400 || strval(modelid) > 611) return SCM(playerid, -1, "valid model between 400 and 611");
		new id = CreateVehicle(strval(modelid), x, y, z, 0, -1, -1, 30);
		PutPlayerInVehicle(playerid, id, 0); 

		//trying to use a value of an element that does not exit
		//in the vehmodel array doesn't return an error.
		format(message, sizeof(message), "%s(id: %d) created.", vehmodel_names[strval(modelid) - 400], id);
		return SCM(playerid, -1, message);
	}
	else
	{
		for(new vehicle = 0; vehicle < sizeof(vehmodel_names); vehicle++)
		{
			if(!strcmp(modelid, vehmodel_names[vehicle], true, strlen(modelid)))
			{
				new id = CreateVehicle(vehicle + 400, x, y, z, 0, -1, -1, 30);

				if(id == 65535)
				{
					return SCM(playerid, -1, "invalid model");
				}
				format(message, sizeof(message), "%s(id: %d) created.", vehmodel_names[vehicle], id);
				SCM(playerid, -1, message);
				PutPlayerInVehicle(playerid, id, 0); 

				break;
			}
		}
	}

	return 1;
}


CMD:destroyveha(playerid, params[])
{
	new vehicleid;
	new range;
	new count = 0;
	if(sscanf(params, "i", range)) return SCM(playerid, 0xEB4034, "usage: /destroyveha <range>.");

	new tv = GetVehiclePoolSize();
	new message[100];
	// format(message, sizeof(message), "number of vehicles spawned on the map: %i", tv);
	// SCM(playerid, 0xEB4034, message);

	for(vehicleid = 0; vehicleid <= tv; vehicleid++)
	{
		if(IsVehicleInRangeOfPlayer(vehicleid, playerid, range))
		{
			DestroyVehicle(vehicleid);
			count += 1;
			// format(message, sizeof(message), "destroyed vehicle. (id: %d)", vehicleid);
			// SCM(playerid, 0xEB4034, message);
		}
	}

	format(message, sizeof(message), "number of vehicles destroyed: %d", count);
	SCM(playerid, 0xEB4034, message);

	return 1;
}

CMD:destroyveh(playerid, params[])
{
	new message[30];
	new vehicleid;
	// format(message, sizeof(message), "params: %s", params);
	// SCM(playerid, 0xEB4034, message);
	if(sscanf(params, "i", vehicleid)) return SCM(playerid, 0xEB4034, "usage: /destroyveh <vehicleid>.");
	if(!DestroyVehicle(vehicleid)) return SCM(playerid, -1, "vehicle does not exist!");
	format(message, sizeof(message), "destroyed vehicle. (id: %d)", vehicleid);
	SCM(playerid, 0xEB4034, message);
	return 1;
}

CMD:giveplayer(playerid, params[])
{
	new targetid, good[100], Float:amount;

	if(sscanf(params, "is[100]f", targetid, good, amount))
	{
		SCM(playerid, 0xEB4034, "usage: /giveplayer <playerid> <good> <amount>\n");
		SCM(playerid, 0xEB4034, "goods: money, bankmoney");
		return 1;
	} 

	if(!strcmp(good, "money"))
	{
		givegood(playerid, "money", targetid, amount);
	}
	if(!strcmp(good, "bankmoney"))
	{
		givegood(playerid, "bankmoney", targetid, amount);
	}
	return 1;
}

CMD:set(playerid, params[])
{
	new targetid, good[100], amount;

	if(sscanf(params, "is[100]i", targetid, good, amount))
	{
		SCM(playerid, 0xEB4034, "usage: /set <playerid> <stat> <amount>\n");
		SCM(playerid, 0xEB4034, "stats: money, bankmoney, level");
		return 1;
	} 

	if(!strcmp(good, "money"))
	{
		set(playerid, "money", targetid, amount);
	}
	if(!strcmp(good, "bankmoney"))
	{
		set(playerid, "bankmoney", targetid, amount);
	}
	if(!strcmp(good, "level"))
	{
		set(playerid, "level", targetid, amount);
	}

	return 1;
}

function IsNumeric(const string[])
{
	for(new i = 0; i < strlen(string); i++)
	{
		if(string[i] > '9' || string[i] < '0') return 0;
		return 1;
	}
	return 1;
}

CMD:id(playerid, params[])
{
	new player[24];
	if(sscanf(params, "s[24]", player)) return SCM(playerid, -1, "usage: /id <playerid/playername>.");
	printf("strval(player): %d", strval(player));
	// The integer value of the string. '0 if the string is not numeric.
	if(IsNumeric(player))
	{
		new pname[MAX_PLAYER_NAME], message[127];
		if(!GetPlayerName(strval(player), pname, sizeof(pname)))
		{
			return SCM(playerid, COLOR_RED, "player is not connected");
		}
		
		format(message, sizeof(message), "name: %s | level: %d |", pname, PlayerInfo[strval(player)][pLevel]);
		SCM(playerid, -1, message);
	}
	else
	{
		new message[126], pname[MAX_PLAYER_NAME], count = 0;
		for(new pid = 0; pid < MAX_PLAYERS; pid++)
		{
			if(!GetPlayerName(pid, pname, sizeof(pname))) continue;
			if(!strcmp(player, pname, true, strlen(player)))
			{
				count++;
				format(message, sizeof(message), "name: %s | level: %d |", pname, PlayerInfo[strval(player)][pLevel]);
				SCM(playerid, -1, message);
			}
		}
		if(count == 0)
		{
			return SCM(playerid, COLOR_RED, "player is not connected");
		}
	}
 
	return 1;
}

function GetPlayerID(const pname[])
{
	for(new player = 0; player < MAX_PLAYERS; player++)
	{
		new name[MAX_PLAYER_NAME];
		GetPlayerName(player, name, sizeof(name));

		if(!strcmp(name, pname, true, strlen(pname)))
		{
			return player;
		}
		return -1;
	}

	return 1;
}

function givegood(playerid, const good[], targetid, Float:amount)
{
	//is player admin blah blah
	if(!strcmp(good, "money"))
	{
		if(!IsPlayerConnected(targetid)) return SCM(playerid, -1, "the player is not connected!");
		new tname[MAX_PLAYER_NAME], pname[MAX_PLAYER_NAME], message[128];

		GetPlayerName(targetid, tname, sizeof(tname));
		GetPlayerName(playerid, pname, sizeof(pname));
		
		GivePlayerMoney(targetid, floatround(amount));
		PlayerInfo[targetid][pMoney] += amount;
		format(message, sizeof(message), "you gave %s: %d$.", tname, amount);
		SCM(playerid, -1, message);

		format(message, sizeof(message), "you received %d$ from %s.", amount, pname);
		SCM(playerid, -1, message);
	}
	else if(!strcmp(good, "bankmoney"))
	{
		if(!IsPlayerConnected(targetid)) return SCM(playerid, -1, "the player is not connected!");
		new tname[MAX_PLAYER_NAME], message[128], pname[MAX_PLAYER_NAME];

		GetPlayerName(targetid, tname, sizeof(tname));
		GetPlayerName(playerid, pname, sizeof(pname));
		
		PlayerInfo[targetid][pBankMoney] += amount;
		new gender[20];
		if(PlayerInfo[targetid][pGender] == 1)
		format(gender, sizeof(gender), "his");
		else
		format(gender, sizeof(gender), "her");
		
		format(message, sizeof(message), "you sent %s: %d$ into %s bank account.", tname, amount, gender);
		SCM(playerid, -1, message);

		format(message, sizeof(message), "%s sent you %d$ into your bank account", pname, amount);
		SCM(targetid, -1, message);
	}

	return 1;
}

function set(playerid, const stat[], targetid, amount)
{
	//is player admin blah blah
	if(!strcmp(stat, "money"))
	{
		if(!IsPlayerConnected(targetid)) return SCM(playerid, -1, "the player is not connected!");
		new tname[MAX_PLAYER_NAME], message[128];
		GetPlayerName(targetid, tname, sizeof(tname));
		PlayerInfo[targetid][pMoney] = amount;

		ResetPlayerMoney(targetid);
		GivePlayerMoney(targetid, amount);

		format(message, sizeof(message), "you set %s's money to: %d$.", tname, amount);
		SCM(playerid, -1, message);
	}
	else if(!strcmp(stat, "bankmoney"))
	{
		if(!IsPlayerConnected(targetid)) return SCM(playerid, -1, "the player is not connected!");
		new tname[MAX_PLAYER_NAME], message[128];
		GetPlayerName(targetid, tname, sizeof(tname));
		PlayerInfo[targetid][pBankMoney] = amount;
	
		format(message, sizeof(message), "you set %s's bank money to: %d$", tname, amount);
		SCM(playerid, -1, message);
	}
	else if(!strcmp(stat, "level"))
	{
		if(!IsPlayerConnected(targetid)) return SCM(playerid, -1, "the player is not connected!");
		new tname[MAX_PLAYER_NAME], message[128];
		GetPlayerName(targetid, tname, sizeof(tname));
		PlayerInfo[targetid][pLevel] = amount;
		SetPlayerScore(targetid, amount);
	
		format(message, sizeof(message), "you set %s's level to %d", tname, amount);
		SCM(playerid, -1, message);
	}
	return 1;
}
public OnPlayerCommandText(playerid, cmdtext[])
{
	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(isWorkingPizza[playerid])
	{

		if(oldstate == PLAYER_STATE_DRIVER && newstate == PLAYER_STATE_ONFOOT) 
		{
			if(lastCar[playerid] == pizzaVehicle[playerid])
			{
				SCM(playerid, COLOR_RED, "you left your pizza vehicle, you have 60 seconds to return.");
				new funcname[30];
				
				format(funcname, sizeof(funcname), "leftPizzaVehicle");
				timerid[playerid] = SetTimer(funcname, 60000, false);
				// printf("timerid[playerid](off): %d", timerid[playerid]);
			}
			// new vehicleid = GetPlayerVehicleID(playerid);
			// AddVehicleComponent(vehicleid, 1010); // Add NOS to the vehicle
		}

		if(oldstate == PLAYER_STATE_ONFOOT && newstate == PLAYER_STATE_DRIVER) 
		{
			// printf("timerid[playerid](on): %d", timerid[playerid]);
			lastCar[playerid] = GetPlayerVehicleID(playerid);
			
			if(timerid[playerid] != 0)
			{
				if(GetPlayerVehicleID(playerid) == pizzaVehicle[playerid])
				{
					KillTimer(timerid[playerid]);
					timerid[playerid] = -1;
					// SCM(playerid, -1, "timer killed.");
				}
			}
		}
	}
	
	return 1;
}

function leftPizzaVehicle(playerid)
{
	isWorkingPizza[playerid] = false;
	DestroyVehicle(pizzaVehicle[playerid]);
	DisablePlayerCheckpoint(playerid);
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	DisablePlayerCheckpoint(playerid);
	// SCM(playerid, COLOR_RED, "checkpoint entered");

	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	new message[128];
	if(newkeys & KEY_SECONDARY_ATTACK)
	{
		format(message, sizeof(message), "pressed: KEY_SECONDARY_ATTACK")
		SCM(playerid, -1, message);
	}
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, STREAMER_TAG_PICKUP:pickupid)
{
	new messagep[128];
	format(messagep, sizeof(messagep), "callback pickupid: %d", pickupid);
	SCM(playerid, -1, messagep);
	
	return 1;
}

// public OnPlayerPickUpDynamicPickup(playerid, STREAMER_TAG_PICKUP pickupid)
// {
// 	new messagep[128];
// 	format(messagep, sizeof(messagep), "pickupid: %d", pickupid);
// 	SCM(playerid, -1, messagep);

// 	return 1;
// }