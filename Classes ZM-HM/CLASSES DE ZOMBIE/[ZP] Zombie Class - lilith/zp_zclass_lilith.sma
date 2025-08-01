#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <engine>
#include <fun>
#include <zombie_plague_special>

// Teleport Mark
#define TELEPORT_MARK_MODEL		"models/xman2030/teleport_zombie_mark.mdl"
#define TELEPORT_MARK_CLASSNAME		"lilith_mark_teleport"

// Teleport Portal
#define TELEPORT_PORTAL_MODEL		"sprites/xman2030/ef_teleportzombie.spr"
#define TELEPORT_PORTAL_CLASSNAME	"lilith_portal_teleport"

// Teleport Origin ++
#define TELEPORT_X 			25.0
#define TELEPORT_Z 			15.0

// Zombie Configuration (String)
#define ZOMBIE_NAME			"Lilith Zombie"
#define ZOMBIE_INFO			"Cria um Portal"
#define ZOMBIE_MODEL			"teleport_xman2030"
#define ZOMBIE_CLAW_MDL			"v_knife_teleport_host.mdl"
#define ZOMBIE_BOMB_MDL			"models/xman2030/grenade/v_zombibomb_teleport_host.mdl"

// Zombie Configuration (Value)
#define ZOMBIE_HEALTH			6000
#define ZOMBIE_SPEED			260
#define ZOMBIE_GRAVITY			0.8
#define ZOMBIE_KNOCKBACK		0.8

// Delay Skill Configuration
#define DELAY_SKILL_1			30
#define DELAY_SKILL_2			40

// Task
#define TASK_TELEPORT			10221
#define	TASK_DELAY			10222

new const Float:UnstuckVector[][] =
{
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0},
	{0.0, 0.0, 6.0}, {0.0, 0.0, -6.0}, {0.0, 6.0, 0.0}, {0.0, -6.0, 0.0}, {6.0, 0.0, 0.0}, {-6.0, 0.0, 0.0}, {-6.0, 6.0, 6.0}, {6.0, 6.0, 6.0}, {6.0, -6.0, 6.0}, {6.0, 6.0, -6.0}, {-6.0, -6.0, 6.0}, {6.0, -6.0, -6.0}, {-6.0, 6.0, -6.0}, {-6.0, -6.0, -6.0},
	{0.0, 0.0, 7.0}, {0.0, 0.0, -7.0}, {0.0, 7.0, 0.0}, {0.0, -7.0, 0.0}, {7.0, 0.0, 0.0}, {-7.0, 0.0, 0.0}, {-7.0, 7.0, 7.0}, {7.0, 7.0, 7.0}, {7.0, -7.0, 7.0}, {7.0, 7.0, -7.0}, {-7.0, -7.0, 7.0}, {7.0, -7.0, -7.0}, {-7.0, 7.0, -7.0}, {-7.0, -7.0, -7.0},
	{0.0, 0.0, 8.0}, {0.0, 0.0, -8.0}, {0.0, 8.0, 0.0}, {0.0, -8.0, 0.0}, {8.0, 0.0, 0.0}, {-8.0, 0.0, 0.0}, {-8.0, 8.0, 8.0}, {8.0, 8.0, 8.0}, {8.0, -8.0, 8.0}, {8.0, 8.0, -8.0}, {-8.0, -8.0, 8.0}, {8.0, -8.0, -8.0}, {-8.0, 8.0, -8.0}, {-8.0, -8.0, -8.0},
	{0.0, 0.0, 9.0}, {0.0, 0.0, -9.0}, {0.0, 9.0, 0.0}, {0.0, -9.0, 0.0}, {9.0, 0.0, 0.0}, {-9.0, 0.0, 0.0}, {-9.0, 9.0, 9.0}, {9.0, 9.0, 9.0}, {9.0, -9.0, 9.0}, {9.0, 9.0, -9.0}, {-9.0, -9.0, 9.0}, {9.0, -9.0, -9.0}, {-9.0, 9.0, -9.0}, {-9.0, -9.0, -9.0},
	{0.0, 0.0, 10.0}, {0.0, 0.0, -10.0}, {0.0, 10.0, 0.0}, {0.0, -10.0, 0.0}, {10.0, 0.0, 0.0}, {-10.0, 0.0, 0.0}, {-10.0, 10.0, 10.0}, {10.0, 10.0, 10.0}, {10.0, -10.0, 10.0}, {10.0, 10.0, -10.0}, {-10.0, -10.0, 10.0}, {10.0, -10.0, -10.0}, {-10.0, 10.0, -10.0}, {-10.0, -10.0, -10.0},
	{0.0, 0.0, 11.0}, {0.0, 0.0, -11.0}, {0.0, 11.0, 0.0}, {0.0, -11.0, 0.0}, {11.0, 0.0, 0.0}, {-11.0, 0.0, 0.0}, {-11.0, 11.0, 11.0}, {11.0, 11.0, 11.0}, {11.0, -11.0, 11.0}, {11.0, 11.0, -11.0}, {-11.0, -11.0, 11.0}, {11.0, -11.0, -11.0}, {-11.0, 11.0, -11.0}, {-11.0, -11.0, -11.0},
	{0.0, 0.0, 12.0}, {0.0, 0.0, -12.0}, {0.0, 12.0, 0.0}, {0.0, -12.0, 0.0}, {12.0, 0.0, 0.0}, {-12.0, 0.0, 0.0}, {-12.0, 12.0, 12.0}, {12.0, 12.0, 12.0}, {12.0, -12.0, 12.0}, {12.0, 12.0, -12.0}, {-12.0, -12.0, 12.0}, {12.0, -12.0, -12.0}, {-12.0, 12.0, -12.0}, {-12.0, -12.0, -12.0},
	{0.0, 0.0, 13.0}, {0.0, 0.0, -13.0}, {0.0, 13.0, 0.0}, {0.0, -13.0, 0.0}, {13.0, 0.0, 0.0}, {-13.0, 0.0, 0.0}, {-13.0, 13.0, 13.0}, {13.0, 13.0, 13.0}, {13.0, -13.0, 13.0}, {13.0, 13.0, -13.0}, {-13.0, -13.0, 13.0}, {13.0, -13.0, -13.0}, {-13.0, 13.0, -13.0}, {-13.0, -13.0, -13.0},
	{0.0, 0.0, 14.0}, {0.0, 0.0, -14.0}, {0.0, 14.0, 0.0}, {0.0, -14.0, 0.0}, {14.0, 0.0, 0.0}, {-14.0, 0.0, 0.0}, {-14.0, 14.0, 14.0}, {14.0, 14.0, 14.0}, {14.0, -14.0, 14.0}, {14.0, 14.0, -14.0}, {-14.0, -14.0, 14.0}, {14.0, -14.0, -14.0}, {-14.0, 14.0, -14.0}, {-14.0, -14.0, -14.0},
	{0.0, 0.0, 15.0}, {0.0, 0.0, -15.0}, {0.0, 15.0, 0.0}, {0.0, -15.0, 0.0}, {15.0, 0.0, 0.0}, {-15.0, 0.0, 0.0}, {-15.0, 15.0, 15.0}, {15.0, 15.0, 15.0}, {15.0, -15.0, 15.0}, {15.0, 15.0, -15.0}, {-15.0, -15.0, 15.0}, {15.0, -15.0, -15.0}, {-15.0, 15.0, -15.0}, {-15.0, -15.0, -15.0},
	{0.0, 0.0, 16.0}, {0.0, 0.0, -16.0}, {0.0, 16.0, 0.0}, {0.0, -16.0, 0.0}, {16.0, 0.0, 0.0}, {-16.0, 0.0, 0.0}, {-16.0, 16.0, 16.0}, {16.0, 16.0, 16.0}, {16.0, -16.0, 16.0}, {16.0, 16.0, -16.0}, {-16.0, -16.0, 16.0}, {16.0, -16.0, -16.0}, {-16.0, 16.0, -16.0}, {-16.0, -16.0, -16.0},
	{0.0, 0.0, 17.0}, {0.0, 0.0, -17.0}, {0.0, 17.0, 0.0}, {0.0, -17.0, 0.0}, {17.0, 0.0, 0.0}, {-17.0, 0.0, 0.0}, {-17.0, 17.0, 17.0}, {17.0, 17.0, 17.0}, {17.0, -17.0, 17.0}, {17.0, 17.0, -17.0}, {-17.0, -17.0, 17.0}, {17.0, -17.0, -17.0}, {-17.0, 17.0, -17.0}, {-17.0, -17.0, -17.0},
	{0.0, 0.0, 18.0}, {0.0, 0.0, -18.0}, {0.0, 18.0, 0.0}, {0.0, -18.0, 0.0}, {18.0, 0.0, 0.0}, {-18.0, 0.0, 0.0}, {-18.0, 18.0, 18.0}, {18.0, 18.0, 18.0}, {18.0, -18.0, 18.0}, {18.0, 18.0, -18.0}, {-18.0, -18.0, 18.0}, {18.0, -18.0, -18.0}, {-18.0, 18.0, -18.0}, {-18.0, -18.0, -18.0},
	{0.0, 0.0, 19.0}, {0.0, 0.0, -19.0}, {0.0, 19.0, 0.0}, {0.0, -19.0, 0.0}, {19.0, 0.0, 0.0}, {-19.0, 0.0, 0.0}, {-19.0, 19.0, 19.0}, {19.0, 19.0, 19.0}, {19.0, -19.0, 19.0}, {19.0, 19.0, -19.0}, {-19.0, -19.0, 19.0}, {19.0, -19.0, -19.0}, {-19.0, 19.0, -19.0}, {-19.0, -19.0, -19.0},
	{0.0, 0.0, 20.0}, {0.0, 0.0, -20.0}, {0.0, 20.0, 0.0}, {0.0, -20.0, 0.0}, {20.0, 0.0, 0.0}, {-20.0, 0.0, 0.0}, {-20.0, 20.0, 20.0}, {20.0, 20.0, 20.0}, {20.0, -20.0, 20.0}, {20.0, 20.0, -20.0}, {-20.0, -20.0, 20.0}, {20.0, -20.0, -20.0}, {-20.0, 20.0, -20.0}, {-20.0, -20.0, -20.0},
	{0.0, 0.0, 21.0}, {0.0, 0.0, -21.0}, {0.0, 21.0, 0.0}, {0.0, -21.0, 0.0}, {21.0, 0.0, 0.0}, {-21.0, 0.0, 0.0}, {-21.0, 21.0, 21.0}, {21.0, 21.0, 21.0}, {21.0, -21.0, 21.0}, {21.0, 21.0, -21.0}, {-21.0, -21.0, 21.0}, {21.0, -21.0, -21.0}, {-21.0, 21.0, -21.0}, {-21.0, -21.0, -21.0},
	{0.0, 0.0, 22.0}, {0.0, 0.0, -22.0}, {0.0, 22.0, 0.0}, {0.0, -22.0, 0.0}, {22.0, 0.0, 0.0}, {-22.0, 0.0, 0.0}, {-22.0, 22.0, 22.0}, {22.0, 22.0, 22.0}, {22.0, -22.0, 22.0}, {22.0, 22.0, -22.0}, {-22.0, -22.0, 22.0}, {22.0, -22.0, -22.0}, {-22.0, 22.0, -22.0}, {-22.0, -22.0, -22.0},
	{0.0, 0.0, 23.0}, {0.0, 0.0, -23.0}, {0.0, 23.0, 0.0}, {0.0, -23.0, 0.0}, {23.0, 0.0, 0.0}, {-23.0, 0.0, 0.0}, {-23.0, 23.0, 23.0}, {23.0, 23.0, 23.0}, {23.0, -23.0, 23.0}, {23.0, 23.0, -23.0}, {-23.0, -23.0, 23.0}, {23.0, -23.0, -23.0}, {-23.0, 23.0, -23.0}, {-23.0, -23.0, -23.0},
	{0.0, 0.0, 24.0}, {0.0, 0.0, -24.0}, {0.0, 24.0, 0.0}, {0.0, -24.0, 0.0}, {24.0, 0.0, 0.0}, {-24.0, 0.0, 0.0}, {-24.0, 24.0, 24.0}, {24.0, 24.0, 24.0}, {24.0, -24.0, 24.0}, {24.0, 24.0, -24.0}, {-24.0, -24.0, 24.0}, {24.0, -24.0, -24.0}, {-24.0, 24.0, -24.0}, {-24.0, -24.0, -24.0},
	{0.0, 0.0, 25.0}, {0.0, 0.0, -25.0}, {0.0, 25.0, 0.0}, {0.0, -25.0, 0.0}, {25.0, 0.0, 0.0}, {-25.0, 0.0, 0.0}, {-25.0, 25.0, 25.0}, {25.0, 25.0, 25.0}, {25.0, -25.0, 25.0}, {25.0, 25.0, -25.0}, {-25.0, -25.0, 25.0}, {25.0, -25.0, -25.0}, {-25.0, 25.0, -25.0}, {-25.0, -25.0, -25.0},
	{0.0, 0.0, 26.0}, {0.0, 0.0, -26.0}, {0.0, 26.0, 0.0}, {0.0, -26.0, 0.0}, {26.0, 0.0, 0.0}, {-26.0, 0.0, 0.0}, {-26.0, 26.0, 26.0}, {26.0, 26.0, 26.0}, {26.0, -26.0, 26.0}, {26.0, 26.0, -26.0}, {-26.0, -26.0, 26.0}, {26.0, -26.0, -26.0}, {-26.0, 26.0, -26.0}, {-26.0, -26.0, -26.0},
	{0.0, 0.0, 27.0}, {0.0, 0.0, -27.0}, {0.0, 27.0, 0.0}, {0.0, -27.0, 0.0}, {27.0, 0.0, 0.0}, {-27.0, 0.0, 0.0}, {-27.0, 27.0, 27.0}, {27.0, 27.0, 27.0}, {27.0, -27.0, 27.0}, {27.0, 27.0, -27.0}, {-27.0, -27.0, 27.0}, {27.0, -27.0, -27.0}, {-27.0, 27.0, -27.0}, {-27.0, -27.0, -27.0},
	{0.0, 0.0, 28.0}, {0.0, 0.0, -28.0}, {0.0, 28.0, 0.0}, {0.0, -28.0, 0.0}, {28.0, 0.0, 0.0}, {-28.0, 0.0, 0.0}, {-28.0, 28.0, 28.0}, {28.0, 28.0, 28.0}, {28.0, -28.0, 28.0}, {28.0, 28.0, -28.0}, {-28.0, -28.0, 28.0}, {28.0, -28.0, -28.0}, {-28.0, 28.0, -28.0}, {-28.0, -28.0, -28.0},
	{0.0, 0.0, 29.0}, {0.0, 0.0, -29.0}, {0.0, 29.0, 0.0}, {0.0, -29.0, 0.0}, {29.0, 0.0, 0.0}, {-29.0, 0.0, 0.0}, {-29.0, 29.0, 29.0}, {29.0, 29.0, 29.0}, {29.0, -29.0, 29.0}, {29.0, 29.0, -29.0}, {-29.0, -29.0, 29.0}, {29.0, -29.0, -29.0}, {-29.0, 29.0, -29.0}, {-29.0, -29.0, -29.0},
	{0.0, 0.0, 30.0}, {0.0, 0.0, -30.0}, {0.0, 30.0, 0.0}, {0.0, -30.0, 0.0}, {30.0, 0.0, 0.0}, {-30.0, 0.0, 0.0}, {-30.0, 30.0, 30.0}, {30.0, 30.0, 30.0}, {30.0, -30.0, 30.0}, {30.0, 30.0, -30.0}, {-30.0, -30.0, 30.0}, {30.0, -30.0, -30.0}, {-30.0, 30.0, -30.0}, {-30.0, -30.0, -30.0},
	{0.0, 0.0, 31.0}, {0.0, 0.0, -31.0}, {0.0, 31.0, 0.0}, {0.0, -31.0, 0.0}, {31.0, 0.0, 0.0}, {-31.0, 0.0, 0.0}, {-31.0, 31.0, 31.0}, {31.0, 31.0, 31.0}, {31.0, -31.0, 31.0}, {31.0, 31.0, -31.0}, {-31.0, -31.0, 31.0}, {31.0, -31.0, -31.0}, {-31.0, 31.0, -31.0}, {-31.0, -31.0, -31.0},
	{0.0, 0.0, 32.0}, {0.0, 0.0, -32.0}, {0.0, 32.0, 0.0}, {0.0, -32.0, 0.0}, {32.0, 0.0, 0.0}, {-32.0, 0.0, 0.0}, {-32.0, 32.0, 32.0}, {32.0, 32.0, 32.0}, {32.0, -32.0, 32.0}, {32.0, 32.0, -32.0}, {-32.0, -32.0, 32.0}, {32.0, -32.0, -32.0}, {-32.0, 32.0, -32.0}, {-32.0, -32.0, -32.0},
	{0.0, 0.0, 33.0}, {0.0, 0.0, -33.0}, {0.0, 33.0, 0.0}, {0.0, -33.0, 0.0}, {33.0, 0.0, 0.0}, {-33.0, 0.0, 0.0}, {-33.0, 33.0, 33.0}, {33.0, 33.0, 33.0}, {33.0, -33.0, 33.0}, {33.0, 33.0, -33.0}, {-33.0, -33.0, 33.0}, {33.0, -33.0, -33.0}, {-33.0, 33.0, -33.0}, {-33.0, -33.0, -33.0},
	{0.0, 0.0, 34.0}, {0.0, 0.0, -34.0}, {0.0, 34.0, 0.0}, {0.0, -34.0, 0.0}, {34.0, 0.0, 0.0}, {-34.0, 0.0, 0.0}, {-34.0, 34.0, 34.0}, {34.0, 34.0, 34.0}, {34.0, -34.0, 34.0}, {34.0, 34.0, -34.0}, {-34.0, -34.0, 34.0}, {34.0, -34.0, -34.0}, {-34.0, 34.0, -34.0}, {-34.0, -34.0, -34.0},
	{0.0, 0.0, 35.0}, {0.0, 0.0, -35.0}, {0.0, 35.0, 0.0}, {0.0, -35.0, 0.0}, {35.0, 0.0, 0.0}, {-35.0, 0.0, 0.0}, {-35.0, 35.0, 35.0}, {35.0, 35.0, 35.0}, {35.0, -35.0, 35.0}, {35.0, 35.0, -35.0}, {-35.0, -35.0, 35.0}, {35.0, -35.0, -35.0}, {-35.0, 35.0, -35.0}, {-35.0, -35.0, -35.0},
	{0.0, 0.0, 36.0}, {0.0, 0.0, -36.0}, {0.0, 36.0, 0.0}, {0.0, -36.0, 0.0}, {36.0, 0.0, 0.0}, {-36.0, 0.0, 0.0}, {-36.0, 36.0, 36.0}, {36.0, 36.0, 36.0}, {36.0, -36.0, 36.0}, {36.0, 36.0, -36.0}, {-36.0, -36.0, 36.0}, {36.0, -36.0, -36.0}, {-36.0, 36.0, -36.0}, {-36.0, -36.0, -36.0},
	{0.0, 0.0, 37.0}, {0.0, 0.0, -37.0}, {0.0, 37.0, 0.0}, {0.0, -37.0, 0.0}, {37.0, 0.0, 0.0}, {-37.0, 0.0, 0.0}, {-37.0, 37.0, 37.0}, {37.0, 37.0, 37.0}, {37.0, -37.0, 37.0}, {37.0, 37.0, -37.0}, {-37.0, -37.0, 37.0}, {37.0, -37.0, -37.0}, {-37.0, 37.0, -37.0}, {-37.0, -37.0, -37.0},
	{0.0, 0.0, 38.0}, {0.0, 0.0, -38.0}, {0.0, 38.0, 0.0}, {0.0, -38.0, 0.0}, {38.0, 0.0, 0.0}, {-38.0, 0.0, 0.0}, {-38.0, 38.0, 38.0}, {38.0, 38.0, 38.0}, {38.0, -38.0, 38.0}, {38.0, 38.0, -38.0}, {-38.0, -38.0, 38.0}, {38.0, -38.0, -38.0}, {-38.0, 38.0, -38.0}, {-38.0, -38.0, -38.0},
	{0.0, 0.0, 39.0}, {0.0, 0.0, -39.0}, {0.0, 39.0, 0.0}, {0.0, -39.0, 0.0}, {39.0, 0.0, 0.0}, {-39.0, 0.0, 0.0}, {-39.0, 39.0, 39.0}, {39.0, 39.0, 39.0}, {39.0, -39.0, 39.0}, {39.0, 39.0, -39.0}, {-39.0, -39.0, 39.0}, {39.0, -39.0, -39.0}, {-39.0, 39.0, -39.0}, {-39.0, -39.0, -39.0},
	{0.0, 0.0, 40.0}, {0.0, 0.0, -40.0}, {0.0, 40.0, 0.0}, {0.0, -40.0, 0.0}, {40.0, 0.0, 0.0}, {-40.0, 0.0, 0.0}, {-40.0, 40.0, 40.0}, {40.0, 40.0, 40.0}, {40.0, -40.0, 40.0}, {40.0, 40.0, -40.0}, {-40.0, -40.0, 40.0}, {40.0, -40.0, -40.0}, {-40.0, 40.0, -40.0}, {-40.0, -40.0, -40.0}
}

enum _:LILITH_SKILL
{
	SKILL_READY = 0,
	SKILL_USE,
	SKILL_DELAY,
}

enum _:LILITH_ANIMATION
{
	V_ANIM_SKILL_1	= 2,
	V_ANIM_SKILL_2	= 8,
	P_ANIM_SKILL_1	= 152,
	P_ANIM_SKILL_2	= 153
}

enum _:LILITH_SOUND
{
	SKILL_1 = 0,
	SKILL_2_IN,
	SKILL_2_OUT,
	PAIN_HURT,
	PAIN_GATE,
	PAIN_DEATH
}

enum _:LILITH_ENT
{
	ENT_MARK = 0,
	ENT_PORTAL1,
	ENT_PORTAL2
}

new const LilithSound[][] = 
{
	"xman2030/lil/lilith_teleport_skill1.wav",
	"xman2030/lil/lilith_teleport_skill2_in.wav",
	"xman2030/lil/lilith_teleport_skill2_out.wav",
	"xman2030/lil/lilith_pain_hurt.wav",
	"xman2030/lil/lilith_pain_gate.wav",
	"xman2030/lil/lilith_pain_death.wav"
}

new g_lilith,
	g_skill1[33],
	g_skill2[33],
	g_teleport_ent[33][3],
	sync_hud;

public plugin_init() {
	// Forward Event
	register_plugin("[ZP] lilith Zombie", "3.0", "Teixeira")
	register_event("DeathMsg", "Event_Death", "a")
	register_event("CurWeapon","Event_CurWeapon","be","1=1")
	register_event("HLTV", "Event_RoundStart", "a", "1=0", "2=0")
	
	// Forward Log Event
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	
	// Forward Fakemeta
	register_forward(FM_CmdStart , "Forward_CmdStart")
	
	// Forward Ham
	RegisterHam(Ham_TakeDamage, "player", "Forward_TakeDamage")
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "Ham_GrenadeDeploy_Post", true)
	
	// Forward Think Entity
	register_think(TELEPORT_MARK_CLASSNAME, "Forward_Mark_Think")
	register_think(TELEPORT_PORTAL_CLASSNAME, "Forward_Portal_Think")
	register_touch(TELEPORT_MARK_CLASSNAME, "player", "Forward_Mark_Touch")

	// Create Sync Hud
	sync_hud = CreateHudSyncObj(12)
}

public plugin_precache() {
	g_lilith = zp_register_zombie_class(ZOMBIE_NAME, ZOMBIE_INFO, ZOMBIE_MODEL, ZOMBIE_CLAW_MDL, ZOMBIE_HEALTH, ZOMBIE_SPEED, ZOMBIE_GRAVITY, ZOMBIE_KNOCKBACK);

	// Precache models
	precache_model(ZOMBIE_BOMB_MDL)
	precache_model(TELEPORT_MARK_MODEL)
	precache_model(TELEPORT_PORTAL_MODEL)

	// Precache sounds
	for(new i = 0; i < sizeof(LilithSound); i++) precache_sound(LilithSound[i])
	//precache_viewmodel_sound(ZOMBIE_BOMB_MDL)
	precache_sound("common/null.wav")
}

public Ham_GrenadeDeploy_Post(iEnt) {
	new iPlayer = get_pdata_cbase(iEnt, 41, 4);
	if(!IsPlayerLilith(iPlayer)) return HAM_IGNORED;

	set_pev(iPlayer, pev_viewmodel2, ZOMBIE_BOMB_MDL);
	return HAM_HANDLED;
}

public Event_RoundEnd(id) lilith_reset_value(id)
public Event_RoundStart(id) lilith_reset_value(id)
public Event_Death()
{
	new id = read_data(2)
	if(IsPlayerLilith(id))
	{
		engfunc(EngFunc_EmitSound, id, CHAN_ITEM, LilithSound[PAIN_DEATH], 1.0, ATTN_NORM, 0, PITCH_NORM)
		lilith_reset_value(id)
	
	}
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	if(!IsPlayerLilith(id))
		return
	
	if(g_skill1[id] != SKILL_USE) set_user_maxspeed(id, float(ZOMBIE_SPEED))
	else if(g_skill2[id] != SKILL_USE) set_user_maxspeed(id, float(ZOMBIE_SPEED))
}

public Forward_TakeDamage(victim, inflictor, attacker, Float:damage, dmgtype)
{
	if(!is_user_alive(attacker) || zp_get_user_zombie(attacker))
		return
	if(!is_user_alive(victim) || !is_user_connected(victim))
		return
	if(!IsPlayerLilith(victim))
		return
		
	engfunc(EngFunc_EmitSound, victim, CHAN_ITEM, LilithSound[PAIN_HURT], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public show_lilith_hud(id)
{
	id -= 348635343;
	if(!IsPlayerLilith(id)) return PLUGIN_HANDLED;
	
	static Temp_Skill_1[128];
	
	if(g_skill1[id] == SKILL_READY) formatex(Temp_Skill_1, sizeof(Temp_Skill_1), "[ E ] -> Сriar Portal [ Pode Usar ]")
	else if(g_skill1[id] == SKILL_USE) formatex(Temp_Skill_1, sizeof(Temp_Skill_1), "Сriando um portal ....")
	else if(g_skill1[id] == SKILL_DELAY) formatex(Temp_Skill_1, sizeof(Temp_Skill_1), "[ E ] -> Criar Portal [ Espere... ]")
	
	if(g_skill2[id] == SKILL_READY) format(Temp_Skill_1, sizeof(Temp_Skill_1), "%s^n[ R ] -> Teletransporta [ Pode Usar ]", Temp_Skill_1)
	else if(g_skill2[id] == SKILL_USE) format(Temp_Skill_1, sizeof(Temp_Skill_1), "%s^nTeletransportando .....", Temp_Skill_1)
	else if(g_skill2[id] == SKILL_DELAY) format(Temp_Skill_1, sizeof(Temp_Skill_1), "%s^n[ R ] -> Crie um Portal primeiro [ Espere... ]", Temp_Skill_1)
	
	set_hudmessage(255, 120, 0, -1.0, -0.79, 0, 2.0, 10.0);
	ShowSyncHudMsg(id, sync_hud, Temp_Skill_1)
	return PLUGIN_HANDLED;
}

public Forward_CmdStart(id, UC_Handle, seed)
{
	if(!is_user_alive(id))
		return
	if(!IsPlayerLilith(id))
		return
	
	static Float:CurrentTime, Float:g_hud_delay[33]
	CurrentTime = get_gametime()
	
	if(CurrentTime - 1.0 > g_hud_delay[id])
	{
		
		if(pev(id, pev_solid) == SOLID_NOT)
			set_pev(id, pev_solid, SOLID_BBOX)
		
		g_hud_delay[id] = CurrentTime
	}
	
	static PressedButton
	PressedButton = get_uc(UC_Handle, UC_Buttons)
	
	if(PressedButton & IN_RELOAD)
	{
		if(g_skill2[id] != SKILL_READY)
			return
		if(!pev_valid(g_teleport_ent[id][ENT_MARK]))
			return
			
		set_uc(UC_Handle, UC_Buttons, IN_ATTACK2)
		set_task(0.001, "action_teleport", id)
	}
	else if(PressedButton & IN_USE)
	{
		if(pev(id, pev_flags) & FL_DUCKING)
		{
			client_print(id, print_center, "You Can't Create Teleport Portal If You Ducking ...")
			return
		}
		
		if(g_skill1[id] != SKILL_READY)
			return
		
		set_uc(UC_Handle, UC_Buttons, IN_ATTACK2)
		set_task(0.001, "action_create_teleport_mark", id)
	}
	
	auto_unstuck(id)
}

public auto_unstuck(id)
{
	static Float:origin[3], Float:mins[3], hull, Float:vec[3], i
	
	pev(id, pev_origin, origin)
	hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN
	
	if(!is_hull_vacant(origin, hull, id))
	{
		pev(id, pev_mins, mins)
		vec[2] = origin[2]
		
		for (i = 0; i < sizeof UnstuckVector; ++i)
		{
			vec[0] = origin[0] - mins[0] * UnstuckVector[i][0]
			vec[1] = origin[1] - mins[1] * UnstuckVector[i][1]
			vec[2] = origin[2] - mins[2] * UnstuckVector[i][2]
			
			if(is_hull_vacant(vec, hull, id))
			{
				engfunc(EngFunc_SetOrigin, id, vec)
				set_pev(id,pev_velocity,{0.0,0.0,0.0})
			
				i = sizeof UnstuckVector
			}
		}
	}
}

public zp_zombie_class_choosed_pre(id, classid) 
{
	if(g_lilith != classid)
		return PLUGIN_CONTINUE;

	zp_menu_textadd("\d[SEM ACESSO]"); // Adiciona um textin igual no 5.0
	if(!(get_user_flags(id) & ADMIN_LEVEL_G) && !(get_user_flags(id) & ADMIN_LEVEL_F) && !(get_user_flags(id) & ADMIN_LEVEL_E) && !(get_user_flags(id) & ADMIN_LEVEL_D) && !(get_user_flags(id) & ADMIN_LEVEL_C) && !(get_user_flags(id) & ADMIN_LEVEL_B) && !(get_user_flags(id) & ADMIN_LEVEL_A) && !(get_user_flags(id) & ADMIN_RCON))
		return ZP_PLUGIN_HANDLED;

	else 
	zp_menu_textadd("\y[ACESSO ACEITO]")
	return PLUGIN_CONTINUE;
}

public zp_user_infected_post(id)
{
	if(zp_get_user_zombie_class(id) == g_lilith)
	{
		set_task(1.0, "show_lilith_hud", id + 348635343, _, _, "b");
		lilith_reset_var_skill(id)
	}
}

public action_teleport(id)
{
	if(!is_user_alive(id))
		return
	if(!IsPlayerLilith(id))
		return
	if(g_skill2[id] != SKILL_READY)
		return
	
	g_skill2[id] = SKILL_USE
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, id)
	write_short((1<<12)*10) // amplitude
	write_short((1<<12)*2) // duration
	write_short((1<<12)*5) // frequency
	message_end()
	
	set_weapon_anim(id, V_ANIM_SKILL_2)
	set_pev(id, pev_sequence, P_ANIM_SKILL_2)
	set_pev(id, pev_framerate, 0.3)
		
	set_user_maxspeed(id, 0.1)
	set_user_gravity(id, 2.0)
	set_pdata_float(id, 83, 2.0, 5)
	
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_byte(20) // radius
	write_byte(200)    // r
	write_byte(200)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(1)  // decay rate in 10's
	message_end() 
	
	new Float:OriginPlayer[3]
	get_position(id, 5.0, 0.0, 0.0, OriginPlayer)
	create_teleport_portal(g_teleport_ent[id][ENT_PORTAL1], id, SKILL_2_IN, OriginPlayer)
	
	if(pev_valid(g_teleport_ent[id][ENT_MARK]))
	{
		static Float:OriginTeleport[3]
		pev(g_teleport_ent[id][ENT_MARK], pev_origin, OriginTeleport)
		OriginTeleport[2] += 50.0
		create_teleport_portal(g_teleport_ent[id][ENT_PORTAL2], id, SKILL_2_OUT, OriginTeleport)
	}
	
	set_task(2.0, "do_teleport", id+TASK_TELEPORT)
}

public do_teleport(id)
{
	id -= TASK_TELEPORT
	if(!is_user_alive(id))
		return
	if(!IsPlayerLilith(id))
	{
		remove_task(id+TASK_TELEPORT)
		return
	}
	
	if(!pev_valid(g_teleport_ent[id][ENT_MARK]))
		return
	if(g_skill2[id] != SKILL_USE)
		return
	
	client_cmd(id, "+duck")
	
	static Float:OriginTeleport[3]
	pev(g_teleport_ent[id][ENT_MARK], pev_origin, OriginTeleport)
	OriginTeleport[2] += 50.0
	set_pev(id, pev_origin, OriginTeleport)
	engfunc(EngFunc_EmitSound, g_teleport_ent[id][ENT_MARK], CHAN_ITEM, "common/null.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	remove_entity(g_teleport_ent[id][ENT_MARK])
	g_teleport_ent[id][ENT_MARK] = 0
	
	set_user_maxspeed(id, float(ZOMBIE_SPEED))
	set_user_gravity(id, ZOMBIE_GRAVITY)
	set_pev(id, pev_framerate, 1.0)
	client_cmd(id, "-duck")
	
	g_skill2[id] = SKILL_DELAY
	set_task(float(DELAY_SKILL_2), "skill2_delay", id+TASK_DELAY)
}

public skill2_delay(id)
{
	id -= TASK_DELAY
	
	if(g_skill2[id] != SKILL_DELAY)
		return
	
	g_skill2[id] = SKILL_READY
}

public action_create_teleport_mark(id)
{
	if(!is_user_alive(id))
		return
	if(!IsPlayerLilith(id))
		return
	if(g_skill1[id] != SKILL_READY)
		return
	
	g_skill1[id] = SKILL_USE
	
	set_weapon_anim(id, V_ANIM_SKILL_1)
	set_pev(id, pev_sequence, P_ANIM_SKILL_1)
	set_pev(id, pev_framerate, 0.5)
	
	set_user_maxspeed(id, 0.1)
	set_user_gravity(id, 2.0)
	
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_byte(20) // radius
	write_byte(200)    // r
	write_byte(200)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(1)  // decay rate in 10's
	message_end() 
	
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, LilithSound[SKILL_1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_pdata_float(id, 83, 1.0, 5)
	
	set_task(0.63, "create_teleport_mark", id+TASK_TELEPORT)
}

public create_teleport_mark(id)
{
	id -= TASK_TELEPORT
	
	if(!is_user_alive(id))
		return
	if(!IsPlayerLilith(id))
	{
		remove_task(id+TASK_TELEPORT)
		return
	}
	
	if(g_skill1[id] != SKILL_USE)
		return
	
	if(pev_valid(g_teleport_ent[id][ENT_MARK]))
	{
		remove_entity(g_teleport_ent[id][ENT_MARK])
		g_teleport_ent[id][ENT_MARK] = 0
	}
	
	set_user_maxspeed(id, float(ZOMBIE_SPEED))
	set_user_gravity(id, ZOMBIE_GRAVITY)
	set_pev(id, pev_framerate, 1.0)
	
	static Float:fOrigin1[3], Float:fOrigin2[3]
	g_teleport_ent[id][ENT_MARK] = create_entity("env_sprite")
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_classname, TELEPORT_MARK_CLASSNAME)
	engfunc(EngFunc_SetModel, g_teleport_ent[id][ENT_MARK], TELEPORT_MARK_MODEL)
	
	pev(id, pev_origin, fOrigin1)
	set_pev(g_teleport_ent[id][ENT_MARK], pev_origin, fOrigin1)
	
	drop_to_floor(g_teleport_ent[id][ENT_MARK])
	
	pev(g_teleport_ent[id][ENT_MARK], pev_origin, fOrigin2)
	fOrigin2[0] += TELEPORT_X
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_origin, fOrigin2)
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_solid, SOLID_NOT)
	set_pev(g_teleport_ent[id][ENT_MARK], pev_movetype, MOVETYPE_NOCLIP)
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_animtime, get_gametime())
	set_pev(g_teleport_ent[id][ENT_MARK], pev_framerate, 1.0)
	set_pev(g_teleport_ent[id][ENT_MARK], pev_sequence, 0)
	set_pev(g_teleport_ent[id][ENT_MARK], pev_owner, id)
	
	set_pev(g_teleport_ent[id][ENT_MARK], pev_nextthink, get_gametime() + 2.0)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, fOrigin2[0])
	engfunc(EngFunc_WriteCoord, fOrigin2[1])
	engfunc(EngFunc_WriteCoord, fOrigin2[2])
	write_byte(10) // radius
	write_byte(200)    // r
	write_byte(200)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(1)  // decay rate in 10's
	message_end() 
	
	engfunc(EngFunc_EmitSound, g_teleport_ent[id][ENT_MARK], CHAN_ITEM, LilithSound[PAIN_GATE], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	g_skill1[id] = SKILL_DELAY
	set_task(float(DELAY_SKILL_1), "skill1_delay", id+TASK_DELAY)
}

public skill1_delay(id)
{
	id -= TASK_DELAY
	
	if(g_skill1[id] != SKILL_DELAY)
		return
	
	g_skill1[id] = SKILL_READY
}

public create_teleport_portal(ent, owner, const Sound, Float:Origin[3])
{
	ent = create_entity("env_sprite")
	
	Origin[0] += TELEPORT_X
	Origin[2] += TELEPORT_Z
	
	set_pev(ent, pev_classname, TELEPORT_PORTAL_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, TELEPORT_PORTAL_MODEL)
	
	set_pev(ent, pev_origin, Origin)
	
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_movetype, MOVETYPE_NOCLIP)
	
	set_pev(ent, pev_rendermode, kRenderTransAdd)
	set_pev(ent, pev_renderamt, 150.0)
	set_pev(ent, pev_scale, 0.5)
	
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, owner)
	set_pev(ent, pev_fuser1, get_gametime() + 3.0)
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.05)
	engfunc(EngFunc_EmitSound, ent, CHAN_ITEM, LilithSound[Sound], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public Forward_Portal_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Float:fFrame, Float:Origin[3], owner
	owner = pev(ent, pev_owner)
	pev(ent, pev_frame, fFrame)
	pev(ent, pev_origin, Origin)

	if(ent == g_teleport_ent[owner][ENT_PORTAL2])
	{
		fFrame += 1.0
		if(fFrame > 15.0) fFrame = 0.0
	}
	else if(ent == g_teleport_ent[owner][ENT_PORTAL1])
	{
		fFrame -= 1.0
		if(fFrame == 0.0) fFrame = 15.0
	}
	
	set_pev(ent, pev_frame, fFrame)
	set_pev(ent, pev_nextthink, get_gametime() + 0.05)
	
	static Float:fTimeRemove
	pev(ent, pev_fuser1, fTimeRemove)
	if(get_gametime() >= pev(ent, pev_fuser1))
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return
	}
}

public Forward_Mark_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(10) // radius
	write_byte(200)    // r
	write_byte(200)  // g
	write_byte(255)   // b
	write_byte(40) // life in 10's
	write_byte(1)  // decay rate in 10's
	message_end()
	
	engfunc(EngFunc_EmitSound, ent, CHAN_ITEM, LilithSound[PAIN_GATE], 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_pev(ent, pev_nextthink, get_gametime() + 2.0)
}

public Forward_Mark_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
	if(!is_user_alive(id))
		return
	
	if(pev(id, pev_solid) != SOLID_NOT)
		set_pev(id, pev_solid, SOLID_NOT)
}

public zp_round_ended() for(new i = 0, j = get_maxplayers(); i < j; i++) lilith_reset_value(i);
public lilith_reset_value(id)
{
	remove_task(id + 348635343);
	lilith_reset_var_skill(id)
}

public lilith_reset_var_skill(id)
{
	remove_task(id+TASK_TELEPORT)
	
	if(pev_valid(g_teleport_ent[id][ENT_MARK]))
	{
		remove_entity(g_teleport_ent[id][ENT_MARK])
		g_teleport_ent[id][ENT_PORTAL2] = 0
	}
	
	if(pev_valid(g_teleport_ent[id][ENT_PORTAL1]))
	{
		remove_entity(g_teleport_ent[id][ENT_PORTAL1])
		g_teleport_ent[id][ENT_PORTAL2] = 0
	}
	
	if(pev_valid(g_teleport_ent[id][ENT_PORTAL2]))
	{
		remove_entity(g_teleport_ent[id][ENT_PORTAL2])
		g_teleport_ent[id][ENT_PORTAL2] = 0
	}
	
	g_skill1[id] = 0
	g_skill2[id] = 0
	g_teleport_ent[id][ENT_MARK] = 0
}

stock bool:is_hull_vacant(const Float:origin[3], hull,id)
{
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid))
		return true;
	
	return false;
}

stock get_position(id, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock precache_viewmodel_sound(const model[]) // I Get This From BTE
{
	new file, i, k
	if((file = fopen(model, "rt")))
	{
		new szsoundpath[64], NumSeq, SeqID, Event, NumEvents, EventID
		fseek(file, 164, SEEK_SET)
		fread(file, NumSeq, BLOCK_INT)
		fread(file, SeqID, BLOCK_INT)
		
		for(i = 0; i < NumSeq; i++)
		{
			fseek(file, SeqID + 48 + 176 * i, SEEK_SET)
			fread(file, NumEvents, BLOCK_INT)
			fread(file, EventID, BLOCK_INT)
			fseek(file, EventID + 176 * i, SEEK_SET)
			
			// The Output Is All Sound To Precache In ViewModels (GREAT :V)
			for(k = 0; k < NumEvents; k++)
			{
				fseek(file, EventID + 4 + 76 * k, SEEK_SET)
				fread(file, Event, BLOCK_INT)
				fseek(file, 4, SEEK_CUR)
				
				if(Event != 5004)
					continue
				
				fread_blocks(file, szsoundpath, 64, BLOCK_CHAR)
				
				if(strlen(szsoundpath))
				{
					strtolower(szsoundpath)
					engfunc(EngFunc_PrecacheSound, szsoundpath)
				}
			}
		}
	}
	fclose(file)
}
stock IsPlayerLilith(iPlayer) return (zp_get_user_zombie(iPlayer) && !zp_get_user_nemesis(iPlayer) && zp_get_user_zombie_class(iPlayer) == g_lilith);