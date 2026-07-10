// Copyright © Armsoup 2026
#define _CRT_SECURE_NO_WARNINGS
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <chrono>
#include <thread>
#include <mmsystem.h>
#include <algorithm>
#include <cctype>
#include <conio.h>
#include <direct.h>
#include <io.h>
#include <filesystem>
#include <psapi.h>
#include <functional>
#include <winternl.h>
#include "resource.h"
#include "miniz.h"
#include "arslanius.h"

std::map<std::string, CommandHandler> driverCommands;
ARSLANIUS_API g_api;

#pragma comment(lib, "winmm.lib")
#pragma comment(lib, "psapi.lib")
#pragma comment(lib, "dbghelp.lib")
#pragma comment(lib, "ntdll.lib")

typedef struct _PEB64 {
	BYTE Reserved1[2];
	BYTE BeingDebugged;
	BYTE Reserved2[1];
	BYTE Reserved3[2];
	DWORD Ldr;
	DWORD ProcessParameters;
	BYTE Reserved4[52];
	DWORD PostProcessInitRoutine;
	DWORD Reserved5[128];
	DWORD SessionId;
} PEB64, * PPEB64;

#define GetPeb() ((PPEB64)__readgsqword(0x60))

#define FLG_HEAP_ENABLE_TAIL_CHECK 0x10
#define FLG_HEAP_ENABLE_FREE_CHECK 0x20
#define FLG_HEAP_VALIDATE_PARAMETERS 0x40

std::vector<void*> g_TrapPages;
bool g_AntiHackRunning = true;

using namespace std;
typedef NTSTATUS(NTAPI* NtReadVirtualMemory_t)(
	HANDLE ProcessHandle,
	PVOID BaseAddress,
	PVOID Buffer,
	SIZE_T NumberOfBytesToRead,
	PSIZE_T NumberOfBytesReaded
	);
typedef NTSTATUS(NTAPI* RtlGetVersionPtr)(PRTL_OSVERSIONINFOW);

NtReadVirtualMemory_t OriginalNtReadVirtualMemory = NULL;

void load_error(string_view code) {
	if (code == "17") {
		system("cls");
		system("color 0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000017" << endl;
		cout << "Info: CRITICAL_RAM_OUTFIT" << endl;
		cout << endl;
		cout << "File: \\ARSLANIUS.exe" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		system("pause");
		abort();
	}
	abort();
}

void CheckAvailableMemory() {
	const SIZE_T TEST_SIZE = 15 * 1024 * 1024;
	void* testMem = VirtualAlloc(NULL, TEST_SIZE, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);

	if (testMem == NULL) {
		load_error("17");
	}
	volatile char* ptr = (volatile char*)testMem;
	for (size_t i = 0; i < TEST_SIZE; i += 4096) {
		ptr[i] = 0xDE;
	}
	VirtualFree(testMem, 0, MEM_RELEASE);
}

struct MemoryGuard {
	MemoryGuard() {
		CheckAvailableMemory();
	}
};

MemoryGuard __memory_guard;

// =====================================================================
// CONSTANTS
// =====================================================================
const string CURRENT_BUILD = "60.0.0";
const string REG_VERSION = "30";
const string OS_NAME_DEFAULT = "ARSLANIUS 30";
const string EXPECTED_SYSTEM_HASH = "57a98c0544492de7afb6aaa83cfa058c6b445e7c4c24127b13d2cfac748e1150";
const string EXPECTED_ADMIN_HASH = "8e5a8afe96e11b2a6921cfd2af1dc2f1b78652a9a7c60de2d69cb2e523ca38da";
const unsigned int BOOT_TIMEOUT_DEFAULT = 30;
const int DEFAULT_MODE_DEFAULT = 1;
const unsigned int MAX_LOGIN_ATTEMPTS = 10;
const size_t MAX_KERNEL_SIZE = 12288;
const size_t MAX_REGISTRY_SIZE = 2048;
const size_t MAX_LOG_SIZE = 153600;

// =====================================================================
// GLOBAL VARIABLES
// =====================================================================
string VersionBarOSkrnl;
string rootPath;
string configRoot;
string kernelPath;
string usersRoot;
string programsRoot;
string sysProf;
string sysServices;
string regPath;
string logPath;
string restoreRoot;

string currentUser;
string userHome;
string UnchangeableUserHome;
string osName = OS_NAME_DEFAULT;
string currentBuild = CURRENT_BUILD;
string REG_VERSION_FOUND = "0";
string systemColor = "0e";
string adminColor = "4f";
string userColor = "1f";
string t_c;
string ConfigPath;
string ex_c;
string recoveryRequest = "0";
string p_in;
string failFile;
string adminUser;
string u_in;
string color_user;
string defaultuserHome;
string regKey = "SYSTEM_COLOR";

DWORD64 bootTimeout = BOOT_TIMEOUT_DEFAULT;
DWORD64 logoutTimeout = 60;
DWORD64 kernelStartTime = 0;
DWORD64* ptr = nullptr;
int defaultMode = DEFAULT_MODE_DEFAULT;
int bootChoice = 0;
int requestFromResume = 0;
int safeMode = 0;
int rec = 0;
int diagnostic = 0;
int lastSuccessfulMode = 0;
int acpiRequest = 0;
int enableLua = 1;
int fastBoot = 1;
int setup = 0;
int system_hash_found = 0;
int admin_hash_found = 0;
int sudo_command = 0;
int lockdown = 0;
int loginAttempts = 0;
int DriverloadOFF = 0;
int autorun = 1;

// =====================================================================
// FORWARD DECLARATIONS
// =====================================================================
void BarOSkrnl(string_view Kernel_mode);
void loadBCD();
void saveBCD();
void bootMenu();
void normalBoot();
void safeModeBoot();
void recoveryEnv();
void diagnosticMode(int mode);
void startupRepair();
void restoreMenu();
void imageRecovery();
void memoryDiag();
void logonScreen();
void loader_errors(string_view code);
void applyColor();
void cmdLoop();
void print_slow(string_view text);
void check_AUTHORITY();
void check_kernel();
void check_registry();
void BSOD_Runner();
void check_BCD();
void installapp(string_view app_id);
void core(const string& cmd);
bool checkHash(string_view input, string_view expectedHash);
string calculateHash(string_view input);
void bsod(const string& code);
void arslogon(string_view authority);
void shutdownScreen();
void rebootScreen();
void interfaceScreen();
bool fileExists(string_view path);
bool dirExists(string_view path);
vector<string> split(const string& s, char delimiter);
string trim(const string& s);
string getCurrentDateTime();
string getUptime();
void writeLog(string_view message);
string readFile(const string& path);
void writeFile(const string& path, string_view content);
void appendFile(const string& path, string_view content);
void setColor(const string& colorCode);
void SetConsoleWidthOnly(int newWidth);
namespace fs = filesystem;

// =====================================================================
// IMPLEMENTATION: UTILITY FUNCTIONS
// =====================================================================

string trim(const string& s) {
	size_t start = s.find_first_not_of(" \t\r\n");
	if (start == string::npos) return "";
	size_t end = s.find_last_not_of(" \t\r\n");
	return s.substr(start, end - start + 1);
}

string getUptime() {
	if (kernelStartTime == 0) return "[ ERROR ] For some unknown reason, the kernel was not initialized.";
	DWORD64 now = GetTickCount64();
	DWORD64 elapsed = now - kernelStartTime;
	DWORD64 seconds = elapsed / 1000;
	DWORD64 minutes = seconds / 60;
	DWORD64 hours = minutes / 60;
	DWORD64 days = hours / 24;
	seconds %= 60;
	minutes %= 60;
	hours %= 24;
	char buf[128];
	if (days > 0) {
		sprintf_s(buf, "%llud %lluh %llum %llus", days, hours, minutes, seconds);
	}
	else if (hours > 0) {
		sprintf_s(buf, "%lluh %llum %llus", hours, minutes, seconds);
	}
	else if (minutes > 0) {
		sprintf_s(buf, "%llum %llus", minutes, seconds);
	}
	else {
		sprintf_s(buf, "%llus", seconds);
	}
	return string(buf);
}

vector<string> split(const string& s, char delimiter) {
	vector<string> tokens;
	string token;
	istringstream tokenStream(s);
	while (getline(tokenStream, token, delimiter)) {
		token = trim(token);
		if (!token.empty()) tokens.push_back(token);
	}
	return tokens;
}

bool fileExists(string_view path) {
	return fs::exists(path) && fs::is_regular_file(path);
}

bool dirExists(string_view path) {
	return fs::exists(path) && fs::is_directory(path);
}

string getCurrentDateTime() {
	auto now = chrono::system_clock::now();
	time_t tt = chrono::system_clock::to_time_t(now);
	struct tm tm_info;
	localtime_s(&tm_info, &tt);
	char buf[64];
	strftime(buf, sizeof(buf), "%d.%m.%Y %H:%M:%S", &tm_info);
	return string(buf);
}

void writeLog(string_view message) {
	ofstream log(logPath, ios::app);
	if (log.is_open()) {
		log << "[" << getCurrentDateTime() << "]" << " " << message << endl;
	}
}

string readFile(const string& path) {
	ifstream f(path);
	if (!f.is_open()) return "";
	stringstream ss;
	ss << f.rdbuf();
	return ss.str();
}

void writeFile(const string& path, string_view content) {
	ofstream f(path);
	if (f.is_open()) {
		f << content;
		f.close();
	}
	else {
		bsod("UNKNOWN");
	}
}

void appendFile(const string& path, string_view content) {
	ofstream f(path, ios::app);
	if (f.is_open()) {
		f << content;
	}
}

string calculateHash(string_view input) {
	const string_view secret_pepper = "Armsoup2026ARSLANIUS"; // Yes, due to the open source code, that secret phrase isn't actually secret at all, but the SYSTEM password is 26 characters long, so it still won't be possible to crack it : )

	string data = string(input) + string(secret_pepper);

	unsigned int h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
	unsigned int h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
	const unsigned int k[64] = {
		0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
		0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
		0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
		0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
		0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
		0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
		0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
		0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
	};

	unsigned long long bitlen = data.length() * 8;
	string padded = data;
	padded += (char)0x80;
	while ((padded.length() * 8) % 512 != 448) padded += (char)0x00;
	for (int i = 7; i >= 0; --i) padded += (char)((bitlen >> (i * 8)) & 0xFF);

	for (size_t chunk = 0; chunk < padded.length(); chunk += 64) {
		unsigned int w[64];
		for (int i = 0; i < 16; ++i) {
			w[i] = ((unsigned char)padded[chunk + i * 4] << 24) |
				((unsigned char)padded[chunk + i * 4 + 1] << 16) |
				((unsigned char)padded[chunk + i * 4 + 2] << 8) |
				((unsigned char)padded[chunk + i * 4 + 3]);
		}
		for (int i = 16; i < 64; ++i) {
			unsigned int s0 = ((w[i - 15] >> 7) | (w[i - 15] << 25)) ^ ((w[i - 15] >> 18) | (w[i - 15] << 14)) ^ (w[i - 15] >> 3);
			unsigned int s1 = ((w[i - 2] >> 17) | (w[i - 2] << 15)) ^ ((w[i - 2] >> 19) | (w[i - 2] << 13)) ^ (w[i - 2] >> 10);
			w[i] = w[i - 16] + s0 + w[i - 7] + s1;
		}
		unsigned int a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
		for (int i = 0; i < 64; ++i) {
			unsigned int S1 = ((e >> 6) | (e << 26)) ^ ((e >> 11) | (e << 21)) ^ ((e >> 25) | (e << 7));
			unsigned int ch = (e & f) ^ (~e & g);
			unsigned int temp1 = h + S1 + ch + k[i] + w[i];
			unsigned int S0 = ((a >> 2) | (a << 30)) ^ ((a >> 13) | (a << 19)) ^ ((a >> 22) | (a << 10));
			unsigned int maj = (a & b) ^ (a & c) ^ (b & c);
			unsigned int temp2 = S0 + maj;
			h = g; g = f; f = e; e = d + temp1; d = c; c = b; b = a; a = temp1 + temp2;
		}
		h0 += a; h1 += b; h2 += c; h3 += d; h4 += e; h5 += f; h6 += g; h7 += h;
	}

	stringstream ss;
	ss << hex << setfill('0')
		<< setw(8) << h0 << setw(8) << h1 << setw(8) << h2 << setw(8) << h3
		<< setw(8) << h4 << setw(8) << h5 << setw(8) << h6 << setw(8) << h7;
	return ss.str();
}

bool checkHash(string_view input, string_view expectedHash) {
	return calculateHash(input) == expectedHash;
}

void pause() {
	cout << "Press any key to continue...";
	char TEMP = _getch();
	cout << endl;
}

void clearScreen() {
	HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	COORD coordScreen = { 0, 0 };
	DWORD cCharsWritten;
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	if (!GetConsoleScreenBufferInfo(hConsole, &csbi)) return;
	DWORD dwConSize = (csbi.srWindow.Right - csbi.srWindow.Left + 1) *
		(csbi.srWindow.Bottom - csbi.srWindow.Top + 1);
	FillConsoleOutputAttribute(hConsole, csbi.wAttributes, dwConSize, coordScreen, &cCharsWritten);
	WriteConsoleOutputCharacterA(hConsole, "", 0, coordScreen, &cCharsWritten);
	FillConsoleOutputCharacter(hConsole, (TCHAR)' ', dwConSize, coordScreen, &cCharsWritten);
	SetConsoleCursorPosition(hConsole, coordScreen);
}

void setColor(const string& colorCode) {
	HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	try {
		int color = stoi(colorCode, nullptr, 16);
		SetConsoleTextAttribute(hConsole, (WORD)color);
		clearScreen();
	}
	catch (...) {
		SetConsoleTextAttribute(hConsole, 7);
	}
}

void loadBCD() {
	string bcdPath = configRoot + "\\BCD";
	if (!fileExists(bcdPath)) return;

	ifstream bcd(bcdPath);
	string line;
	while (getline(bcd, line)) {
		size_t sep = line.find('=');
		if (sep == string::npos) continue;
		string key = line.substr(0, sep);
		string value = line.substr(sep + 1);

		if (value.empty()) continue;

		try {
			if (key == "BOOT_TIMEOUT") bootTimeout = stoi(value);
			else if (key == "DEFAULT_MODE") defaultMode = stoi(value);
			else if (key == "LAST_SUCCESSFUL_MODE") lastSuccessfulMode = stoi(value);
			else if (key == "FAST_BOOT") fastBoot = stoi(value);
			else if (key == "DRIVER_LOAD_OFF") DriverloadOFF = stoi(value);
		}
		catch (...) {
			continue;
		}
	}
}

void print_slow(string_view text) {
	timeBeginPeriod(1);
	for (char c : text) {
		cout << c << flush;
		Sleep(2);
	}
	cout << endl;
	timeEndPeriod(1);
}

void BSOD_Runner() {
	srand((unsigned)time(NULL));
	const int H = 10, W = 20;
	char field[H][W];
	int files = 15, score = 0, level = 1;
	int px = 0, py = 0, spawnInterval = 5;

	for (int i = 0; i < H; i++)
		for (int j = 0; j < W; j++)
			field[i][j] = '.';

	for (int i = 0; i < files; i++) {
		int x, y;
		do {
			x = rand() % W;
			y = rand() % H;
		} while ((x == px && y == py) || field[y][x] == 'F');
		field[y][x] = 'F';
	}
	field[py][px] = 'T';

	auto lastSpawn = chrono::steady_clock::now();
	auto lastLevelUp = chrono::steady_clock::now();

	while (true) {
		auto now = chrono::steady_clock::now();

		if (chrono::duration_cast<chrono::seconds>(now - lastSpawn).count() >= spawnInterval) {
			int x, y, attempts = 0;
			do {
				x = rand() % W;
				y = rand() % H;
				attempts++;
			} while ((field[y][x] != '.' || (x == px && y == py)) && attempts < 100);
			if (field[y][x] == '.') {
				field[y][x] = 'F';
				files++;
				lastSpawn = now;
			}
		}

		if (score > 0 && score % 10 == 0 && chrono::duration_cast<chrono::seconds>(now - lastLevelUp).count() >= 2) {
			level++;
			spawnInterval = max(1, spawnInterval - 1);
			lastLevelUp = now;
		}

		clearScreen();
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                    BSOD RUNNER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << "  Level: " << level << "  |  Score: " << score << "  |  Files: " << files << "/60" << endl;
		cout << "----------------------------------------------------------------------------------------------------------------------" << endl;
		for (int i = 0; i < H; i++) {
			cout << "  ";
			for (int j = 0; j < W; j++) cout << field[i][j];
			cout << endl;
		}
		cout << "----------------------------------------------------------------------------------------------------------------------" << endl;
		cout << "  WASD - Move  |  SPACE - Clean  |  Q/ESC - Quit" << endl;
		cout << "======================================================================================================================" << endl;

		char key = _getch();
		if (key == 'q' || key == 27) applyColor();

		int nx = px, ny = py;
		if (key == 'w') ny--;
		else if (key == 's') ny++;
		else if (key == 'a') nx--;
		else if (key == 'd') nx++;
		else if (key == ' ') {
			bool cleaned = false;
			int dirs[4][2] = { {-1,0},{1,0},{0,-1},{0,1} };
			for (int i = 0; i < 4; i++) {
				int checkX = px + dirs[i][0];
				int checkY = py + dirs[i][1];
				if (checkX >= 0 && checkX < W && checkY >= 0 && checkY < H) {
					if (field[checkY][checkX] == 'F') {
						field[checkY][checkX] = '.';
						files--;
						score++;
						cleaned = true;
						break;
					}
				}
			}
			if (!cleaned) {
				cout << "\nNo file nearby to clean!" << endl;
				Sleep(200);
			}
			if (files == 0) {
				setColor("2f");
				cout << "\n======================================================================================================================" << endl;
				cout << "                                                TEMP IS CLEAN! YOU WIN!" << endl;
				cout << "======================================================================================================================" << endl;
				cout << "  Final Score: " << score << "  |  Level: " << level << endl;
				cout << "======================================================================================================================" << endl;
				break;
			}
			continue;
		}
		else continue;

		if (nx < 0 || nx >= W || ny < 0 || ny >= H) continue;

		if (field[ny][nx] == 'F') {
			cout << "\nCan't walk through files! Clean them first!" << endl;
			Sleep(200);
			continue;
		}

		field[py][px] = '.';
		px = nx; py = ny;
		field[py][px] = 'T';

		if (files >= 60) {
			bsod("");
			break;
		}
	}
	cout << "\n  Press any key to return to ARSLANIUS...";
	char TEMP = _getch();
	applyColor();
}

void installapp(string_view app_id) {
	if (app_id == "1") {
		string appPath = programsRoot + "\\Scanner.bat";
		stringstream app_install;
		app_install << "@echo off" << endl;
		app_install << "echo Scanning %cd%..." << endl;
		app_install << "dir /s /b \"%cd%\" > \"%cd%\\scan_%date%.txt\"" << endl;
		app_install << "echo Scan complete. Saved to scan_%date%.txt" << endl;
		app_install << "pause" << endl;
		app_install << "exit /b" << endl;
		writeFile(appPath, app_install.str());
	}
	if (app_id == "2") {
		string appPath = programsRoot + "\\Notes.bat";
		stringstream app_install;
		app_install << "@echo off" << endl;
		app_install << "set /p txt=Enter text: " << endl;
		app_install << "echo %txt% >> \"%cd%\\notes.txt\"" << endl;
		app_install << "echo Note saved." << endl;
		app_install << "pause" << endl;
		app_install << "exit /b" << endl;
		writeFile(appPath, app_install.str());
	}
	if (app_id == "3") {
		string appPath = programsRoot + "\\Calc.bat";
		stringstream app_install;
		app_install << "@echo off" << endl;
		app_install << "title Calculator" << endl;
		app_install << "color 2f" << endl;
		app_install << ":start" << endl;
		app_install << "set /p sum=Please enter the question:" << endl;
		app_install << "set /a ans=%sum%" << endl;
		app_install << "echo The Answer=%ans%" << endl;
		app_install << "pause" << endl;
		app_install << "cls" << endl;
		app_install << "goto start" << endl;
		writeFile(appPath, app_install.str());
	}
}

void check_kernel() {
	vector<string> linesToFind = {
		"SYSTEM =",
		"SYSTEM ADMINISTRATOR ="
	};
	string content = readFile(kernelPath);
	string lowerContent = content;
	transform(lowerContent.begin(), lowerContent.end(), lowerContent.begin(), ::tolower);
	for (const string& searchFor : linesToFind) {
		string lowerSearch = searchFor;
		transform(lowerSearch.begin(), lowerSearch.end(), lowerSearch.begin(), ::tolower);
		if (lowerContent.find(lowerSearch) != string::npos) {
		}
		else {
			loader_errors("8");
		}
	}
}

void SetConsoleWidthOnly(int newWidth) {
	HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
	CONSOLE_SCREEN_BUFFER_INFO csbi;

	if (!GetConsoleScreenBufferInfo(hOut, &csbi)) return;

	short currentHeight = 40;

	COORD newBufferSize = { (short)newWidth, csbi.dwSize.Y };
	SetConsoleScreenBufferSize(hOut, newBufferSize);

	SMALL_RECT rect;
	rect.Left = csbi.srWindow.Left;
	rect.Top = csbi.srWindow.Top;
	rect.Right = csbi.srWindow.Left + (short)newWidth - 1;
	rect.Bottom = csbi.srWindow.Top + currentHeight - 1;

	SetConsoleWindowInfo(hOut, TRUE, &rect);
}

void loader_errors(string_view code) {
	clearScreen();
	if (code == "1a") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000001a" << endl;
		cout << "Info: CONFIG_ROOT_NOT_FOUND" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("1a");
	}
	if (code == "1") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000001" << endl;
		cout << "Info: KERNEL_NOT_FOUND" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\SAM" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("1");
	}
	if (code == "2") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000002" << endl;
		cout << "Info: SYSTEM_ACCOUNT_HASH_MISMATCH" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\SAM" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("2");
	}
	if (code == "3") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000003" << endl;
		cout << "Info: REGISTRY_VERSION_MISMATCH" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\REG.cfg" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("3");
	}
	if (code == "4") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000004" << endl;
		cout << "Info: REGISTRY_NOT_FOUND" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\REG.cfg" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("4");
	}
	if (code == "5") {
		setColor("04");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000005" << endl;
		cout << "Info: RESERVED_USERNAME_DETECTED" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\SAM" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("5");
	}
	if (code == "7") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000007" << endl;
		cout << "Info: BAD_SYSTEM_CONFIG_INFO" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\REG.cfg" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("7");
	}
	if (code == "8") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000008" << endl;
		cout << "Info: KERNEL_INCOMPLETE" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\SAM" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("8");
	}
	if (code == "10") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000010" << endl;
		cout << "Info: KERNEL_LOCKED" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\SAM" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("10");
	}
	if (code == "11") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000011" << endl;
		cout << "Info: REGISTRY_LOCKED" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\REG.cfg" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("11");
	}
	if (code == "12") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000012" << endl;
		cout << "Info: LOG_OVERFLOW" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\system.log" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("12");
	}
	if (code == "13") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000013" << endl;
		cout << "Info: BCD_CORRUPTED" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\BCD" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("13");
	}
	if (code == "14") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000014" << endl;
		cout << "Info: BCD_NOT_FOUND" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\BCD" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("14");
	}
	if (code == "15") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000015" << endl;
		cout << "Info: DRIVER_CRITICAL_FAILURE" << endl;
		cout << endl;
		cout << "File: \\Settings And System Files\\Drivers" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("15");
	}
	if (code == "16") {
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "ARSLANIUS failed to start. A recent hardware or software change might be" << endl;
		cout << "the cause." << endl;
		cout << endl;
		cout << "Status: 0xc00000016" << endl;
		cout << "Info: CRITICAL_KERNEL_ERROR" << endl;
		cout << endl;
		cout << "File: \\ARSLANIUS.exe" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		pause();
		bsod("16");
	}
	bsod("");
}

void check_registry() {
	vector<string> linesToFind = {
		"OS_NAME=",
		"SYSTEM_COLOR=",
		"ADMIN_COLOR=",
		"USER_COLOR=",
		"ENABLE_LUA=",
		"LOCKDOWN=",
		"ADMIN_USER",
		"SETUP=",
		"REG_VERSION="
	};
	string content = readFile(regPath);
	string lowerContent = content;
	transform(lowerContent.begin(), lowerContent.end(), lowerContent.begin(), ::tolower);
	for (const string& searchFor : linesToFind) {
		string lowerSearch = searchFor;
		transform(lowerSearch.begin(), lowerSearch.end(), lowerSearch.begin(), ::tolower);
		if (lowerContent.find(lowerSearch) != string::npos) {
		}
		else {
			loader_errors("7");
		}
	}
}
void check_BCD() {
	vector<string> linesToFind = {
		"BOOT_TIMEOUT=",
		"DEFAULT_MODE=",
		"FAST_BOOT=",
		"DRIVER_LOAD_OFF="
	};
	string content = readFile(configRoot + "\\BCD");
	string lowerContent = content;
	transform(lowerContent.begin(), lowerContent.end(), lowerContent.begin(), ::tolower);
	for (const string& searchFor : linesToFind) {
		string lowerSearch = searchFor;
		transform(lowerSearch.begin(), lowerSearch.end(), lowerSearch.begin(), ::tolower);
		if (lowerContent.find(lowerSearch) != string::npos) {
		}
		else {
			loader_errors("13");
		}
	}
}

void check_AUTHORITY() {
	string kernel = readFile(kernelPath);
	string lowerKernel = kernel;
	transform(lowerKernel.begin(), lowerKernel.end(), lowerKernel.begin(), ::tolower);

	if (lowerKernel.find("baros authority") != string::npos) {
		loader_errors("5");
	}
}

void loadRegistry() {
	if (!fileExists(regPath)) return;

	ifstream reg(regPath);
	string line;
	while (getline(reg, line)) {
		size_t sep = line.find('=');
		if (sep == string::npos) continue;
		string key = line.substr(0, sep);
		string value = line.substr(sep + 1);

		if (value.empty()) continue;

		try {
			if (key == "OS_NAME") osName = value;
			else if (key == "ENABLE_LUA") enableLua = stoi(value);
			else if (key == "LOCKDOWN") lockdown = stoi(value);
			else if (key == "SYSTEM_COLOR") systemColor = value;
			else if (key == "ADMIN_COLOR") adminColor = value;
			else if (key == "USER_COLOR") userColor = value;
			else if (key == "REG_VERSION") REG_VERSION_FOUND = value;
			else if (key == "SETUP") setup = stoi(value);
			else if (key == "ADMIN_USER") adminUser = value;
		}
		catch (...) {
			continue;
		}
	}
}

void register_driver_command(const char* name, CommandHandler handler) {
	string cmd_name = name;
	transform(cmd_name.begin(), cmd_name.end(), cmd_name.begin(), ::tolower);
	driverCommands[cmd_name] = handler;
}

void saveBCD() {
	string bcdPath = configRoot + "\\BCD";
	stringstream ss;
	ss << "BOOT_TIMEOUT=" << bootTimeout << endl;
	ss << "DEFAULT_MODE=" << defaultMode << endl;
	ss << "FAST_BOOT=" << fastBoot << endl;
	ss << "LAST_SUCCESSFUL_MODE=" << lastSuccessfulMode << endl;
	ss << "DRIVER_LOAD_OFF=" << DriverloadOFF << endl;
	ss << "BOOT_COUNT=0" << endl;
	ss << "LAST_BOOT_SUCCESS=" << getCurrentDateTime() << endl;
	writeFile(bcdPath, ss.str());
}

void Manual() {
	clearScreen();
	cout << "======================================================================================================================" << endl;
	cout << "                                         " << osName << " - USER MANUAL" << endl;
	cout << "======================================================================================================================" << endl;
	cout << endl;
	cout << "[ QUICK START ]" << endl;
	cout << "  1. First run? Press R at BSoD then press 1 [Startup Repair]" << endl;
	cout << "  2. complete OOBE (Out-Of-Box Experience) to create your user account." << endl;
	cout << "  3. Login as your user." << endl;
	cout << "  4. Type help for a list of commands." << endl;
	cout << endl;
	cout << "[ ARSLANIUS BOOT MANAGER ]" << endl;
	cout << "  - Press 1-7 to select mode" << endl;
	cout << "  - Auto-boot in " << bootTimeout << " seconds" << endl;
	cout << endl;
	cout << "[ COMMANDS ]" << endl;
	cout << "  System: help, lock, hibernate, rebootemer or arslogon -emergency reboot, cls, ver, confeditor, whoami, reboot, shutdown, lockmenu [ctrl alt shift]" << endl;
	cout << "  Files: ls, cd, cat, ren, mkdir, touch, edit, cp, mv, rm" << endl;
	cout << "  Admin: adduser, deluser, passwd, regedit, bcdedit, bcdboot, reset" << endl;
	cout << "  Network: ping, netstat, ipconfig, tracert, nslookup, arp, route" << endl;
	cout << "  Recovery: backup, backup-restore, restore-point, restore, sfc, events" << endl;
	cout << "  Fun: bsod, Notepad, wait_mode, echo, game.bsodrunner" << endl;
	cout << endl;
	cout << "[ RECOVERY ENVIRONMENT ]" << endl;
	cout << "  1 [Startup Repair] - recreates all files" << endl;
	cout << "  4 [Mini cmd] - command line with recovery tools" << endl;
	cout << "  2 or 3 - restore from restore points or backup" << endl;
	cout << "======================================================================================================================" << endl;
	pause();
	bootMenu();
}

void Update() {
	cout << "If you have files from an older version, place them in the root folder along with the .exe file and press Y." << endl;
	cout << "Y/N: ";
	char c = _getch();
	cout << c << endl;

	if (toupper(c) == 'Y') {
		if (!fileExists(kernelPath)) {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] SAM not found." << endl;
			pause();
			loader_errors("1");
		}
		saveBCD();

		stringstream reg_update;
		reg_update << "OS_NAME=ARSLANIUS 30" << endl;
		reg_update << "SYSTEM_COLOR=0e" << endl;
		reg_update << "ADMIN_COLOR=4f" << endl;
		reg_update << "USER_COLOR=1f" << endl;
		reg_update << "ENABLE_LUA=" << enableLua << endl;
		reg_update << "LOCKDOWN=0" << endl;
		reg_update << "ADMIN_USER=" << adminUser << endl;
		reg_update << "SETUP=0" << endl;
		reg_update << "REG_VERSION=" << REG_VERSION << endl;
		writeFile(regPath, reg_update.str());
		bootMenu();
	}
	bootMenu();
}

void ensureDirectories() {
	fs::create_directories(configRoot);
	fs::create_directories(sysServices);
	fs::create_directories(usersRoot);
	fs::create_directories(programsRoot);
}

// =====================================================================
// BSOD SCREENS
// =====================================================================

void bsod(const string& code) {
	clearScreen();
	thread soundThread([]() { Beep(750, 1710); });
	soundThread.detach();

	if (code == "1a") {
		setColor("17");
		print_slow("*** STOP: 0x00000001a [0xc00000001a, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files");
		cout << endl;
		print_slow("CONFIG_ROOT_NOT_FOUND - The config root is missing.");
		print_slow("Please reinstall or run Startup Repair.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "1") {
		setColor("17");
		print_slow("*** STOP: 0x00000001 [0xc00000001, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\SAM");
		cout << endl;
		print_slow("KERNEL_NOT_FOUND - The SAM is missing.");
		print_slow("Please reinstall or run Startup Repair.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "2") {
		setColor("17");
		print_slow("*** STOP: 0x00000002 [0xc00000002, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\SAM");
		cout << endl;
		print_slow("SYSTEM_ACCOUNT_HASH_MISMATCH - Someone's been playing with SAM in Notepad, huh?");
		print_slow("Please reinstall or run Startup Repair.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** Expected system hash: " + EXPECTED_SYSTEM_HASH);
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "3") {
		setColor("17");
		print_slow("*** STOP: 0x00000003 [0xc00000003, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\REG.cfg");
		cout << endl;
		print_slow("REGISTRY_VERSION_MISMATCH - The version specified in the REG.cfg file is incorrect.");
		print_slow("Please update(7) it to continue working.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** Expected version: " + REG_VERSION);
		print_slow("*** Found version: " + REG_VERSION_FOUND);
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "4") {
		setColor("17");
		print_slow("*** STOP: 0x00000004 [0xc00000004, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\REG.cfg");
		cout << endl;
		print_slow("REGISTRY_NOT_FOUND - The REG.cfg is missing.");
		print_slow("Please reinstall or run Startup Repair.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "5") {
		setColor("04");
		print_slow("*** STOP: 0x00000005 [0xc00000005, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\SAM");
		cout << endl;
		print_slow("RESERVED_USERNAME_DETECTED - Security violation!");
		print_slow("Someone tried to create 'BarOS AUTHORITY' in SAM.");
		print_slow("That's like printing your own \"100% REAL OFFICIAL\" dollar bill.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** Reserved username found in SAM.");
		print_slow("*** System halted to prevent unauthorized access.");
		cout << endl;
		print_slow("If you call a support specialist, tell him this information so that he can laugh.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "6") {
		setColor("04");
		print_slow("*** STOP: 0x00000006 [0xc00000006, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\ARSLANIUS.exe");
		cout << endl;
		print_slow("CRITICAL_STRUCTURE_CORRUPTION - Someone decided to use Debugger, ya?");
		print_slow("It didn't work, cheater.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** CRITICAL_STRUCTURE_CORRUPTION");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		Sleep(2000);
		exit(0);
	}
	else if (code == "7") {
		setColor("17");
		print_slow("*** STOP: 0x00000007 [0xc00000007, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\REG.cfg");
		cout << endl;
		print_slow("BAD_SYSTEM_CONFIG_INFO - The registry is missing required entries.");
		print_slow("OS_NAME, SYSTEM_COLOR, ADMIN_COLOR, USER_COLOR, ENABLE_LUA, LOCKDOWN, ADMIN_USER, SETUP or REG_VERSION");
		print_slow("is missing. Run update(7) to restore the registry.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** Registry file found but incomplete.");
		print_slow("*** Expected entries: OS_NAME, SYSTEM_COLOR, ADMIN_COLOR, USER_COLOR,");
		print_slow("*** ENABLE_LUA, LOCKDOWN, ADMIN_USER, SETUP REG_VERSION");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "8") {
		setColor("17");
		print_slow("*** STOP: 0x00000008 [0xc00000008, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\SAM");
		cout << endl;
		print_slow("KERNEL_INCOMPLETE - The kernel is missing required SYSTEM or ADMINISTRATOR entries.");
		print_slow("Someone deleted important lines from SAM. Probably with Notepad.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** Missing: SYSTEM or SYSTEM ADMINISTRATOR account");
		print_slow("*** Kernel file found but incomplete.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "9") {
		setColor("17");
		print_slow("*** STOP: 0x00000009 [0xc00000009, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\ARSLANIUS.exe");
		cout << endl;
		print_slow("LOGON_ATTACK_DETECTED - Too many failed login attempts.");
		print_slow("A brute force attack may be in progress.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** Failed attempts: 10");
		print_slow("*** System halted to prevent unauthorized access.");
		print_slow("*** Run Recovery Environment to investigate.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "10") {
		setColor("17");
		print_slow("*** STOP: 0x00000010 [0xc00000010, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\SAM");
		cout << endl;
		print_slow("The kernel is full, run startup repair to reset it.");
		print_slow("Looks like someone needed TOO many accounts.");
		print_slow("Run Startup Repair to restore kernel.");
		cout << endl;
		print_slow("Technical information:");
		cout << "*** Size: " << *ptr << " bytes" << endl;
		delete ptr;
		print_slow("*** Kernel file found but locked.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "11") {
		setColor("17");
		print_slow("*** STOP: 0x00000011 [0xc00000011, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\REG.cfg");
		cout << endl;
		print_slow("The registry is full, run startup repair to reset it.");
		print_slow("Looks like someone filled the registry with all sorts of junk, huh?");
		print_slow("Run Startup Repair to restore registry.");
		cout << endl;
		print_slow("Technical information:");
		cout << "*** Size: " << *ptr << " bytes" << endl;
		delete ptr;
		print_slow("*** REG file found but locked.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "12") {
		setColor("17");
		print_slow("*** STOP: 0x00000012 [0xc00000012, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\system.log");
		cout << endl;
		print_slow("LOG_OVERFLOW - The system log is full of shit.");
		print_slow("Someone's been writing a novel in system.log.");
		print_slow("150 KB is the limit. Run Startup Repair to clear the log.");
		cout << endl;
		print_slow("Technical information:");
		cout << "*** Size: " << *ptr << " bytes" << endl;
		delete ptr;
		print_slow("*** Log file found but locked due to size limit.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "13") {
		setColor("17");
		print_slow("*** STOP: 0x00000013 [0xc00000013, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\BCD");
		cout << endl;
		print_slow("BCD_CORRUPTED - The BCD is missing required entries.");
		print_slow("DEFAULT_MODE, BOOT_TIMEOUT, FAST_BOOT or DRIVER_LOAD_OFF is missing.");
		print_slow("Run update(7) to restore the BCD.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** BCD file found but incomplete.");
		print_slow("*** Expected entries: BOOT_TIMEOUT, DEFAULT_MODE, FAST_BOOT, DRIVER_LOAD_OFF");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "14") {
		setColor("17");
		print_slow("*** STOP: 0x00000014 [0xc00000014, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\BCD");
		cout << endl;
		print_slow("BCD_NOT_FOUND - The BCD is missing.");
		print_slow("Please reinstall or run Startup Repair.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "15") {
		setColor("17");
		print_slow("*** STOP: 0x00000015 [0xc00000015, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\Settings And System Files\\Drivers");
		cout << endl;
		print_slow("DRIVER_CRITICAL_FAILURE - A critical driver returned BAROS_CRITICAL (2).");
		print_slow("Set DRIVER_LOAD_OFF=1 in BCD to disable all drivers.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "16") {
		setColor("04");
		print_slow("*** STOP: 0x00000016 [0xc00000016, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\ARSLANIUS.exe");
		cout << endl;
		print_slow("CRITICAL_KERNEL_ERROR - A serious problem has occurred and ARSLANIUS has stopped working.");
		print_slow("Try updating the program to the latest version or, conversely, reverting to the old one.");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		recoveryEnv();
	}
	else if (code == "DIED") {
		setColor("17");
		print_slow("*** STOP: CRITICAL_PROCESS_DIED [0xc00000000, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("*** File: \\ARSLANIUS.exe");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** ArsLogon died");
		cout << endl;
		print_slow("If this is the first time you've seen this error, restart the system.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		bootMenu();
	}
	else if (code == "666") {
		setColor("17");
		print_slow("*** STOP: 0xDEADBEEF [0x00000666, 0x00000000, 0x00000000, 0x00000000]");
		cout << endl;
		print_slow("MANUAL_CRASH - You typed 'bsod' and now you're here. Surprised? You shouldn't be.");
		print_slow("This error was intentionally triggered by the 'bsod' command.");
		print_slow("No real damage was done. Just reboot and continue.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** Crash initiated by user: " + currentUser);
		print_slow("*** Stop code: 0xTeam_by_" + currentUser);
		print_slow("*** Next time try 'help' instead. Or don't. I'm not your mom.");
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		bootMenu();
	}
	else {
		setColor("08");
		print_slow("*** STOP: 0x00001225a [0x00000220, 0x00000002, 0x00000000a, 0x00000000]");
		cout << endl;
		print_slow("UNKNOWN_ERROR - Something went wrong and ARSLANIUS crashed,");
		print_slow("perhaps the bsod environment variable was not defined due to a serious problem,");
		print_slow("replace the main ARSLANIUS file with the original one.");
		cout << endl;
		print_slow("Technical information:");
		print_slow("*** UNKNOWN_ERROR");
		print_slow("*** Stop code: 0x00001225a");
		print_slow("*** Last User: " + currentUser);
		print_slow("*** Uptime: " + getUptime());
		cout << endl;
		print_slow("For support, visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/issues");
		pause();
		exit(1);
	}
}

// =====================================================================
// BOOT MENU
// =====================================================================

void bootMenu() {
	BarOSkrnl("loading");
	if (setup == 1) {
		setColor("1f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                        " << osName << endl;
		cout << "                                                  Copyright © 2026 Armsoup" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "This program is FREE SOFTWARE under the GNU AGPL - 3.0 license." << endl;
		cout << endl;
		cout << "You MAY:" << endl;
		cout << " -Use it for any purpose" << endl;
		cout << " -Modify it" << endl;
		cout << " -Distribute it" << endl;
		cout << endl;
		cout << "You MUST:" << endl;
		cout << " -Keep the original copyright notice(© Armsoup)" << endl;
		cout << " -Disclose ALL source code(including your changes)" << endl;
		cout << " -License your modified version under AGPL - 3.0 as well" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		cout << "!WARNING!" << endl;
		cout << "If you remove the copyright notice, rename the project, or try to hide its origin:" << endl;
		cout << " -Your license is automatically TERMINATED" << endl;
		cout << " -You are violating DMCA(17 U.S.C.§ 1202)" << endl;
		cout << " -The author(I`m, Armsoup) has the right to sue you" << endl;
		cout << " -Maximum statutory damages: up to $150, 000 per work" << endl;
		cout << "In simple terms: STEAL MY CODE, REMOVE MY NAME = YOU'RE F***ED." << endl;
		cout << endl;
		cout << "Full license: https://www.gnu.org/licenses/agpl-3.0.html" << endl;
		cout << "or: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus?tab=AGPL-3.0-1-ov-file" << endl;
		cout << "Type 'license' on command line to view this again" << endl;
		cout << "======================================================================================================================" << endl;
		cout << "You Agree?: ";
		char choice_license = _getch();
		choice_license = tolower(choice_license);
		cout << choice_license << endl;
		switch (choice_license) {
		case 'y': {
			clearScreen(); break;
		}
		case 'n': {
			exit(1); break;
		}
		}
		cout << "Welcome to OOBE " << osName << "! Do you want to start?" << endl;
		cout << "Y/N: ";
		char choice = _getch();
		choice = tolower(choice);
		cout << choice << endl;

		switch (choice) {
		case 'y': {
			cout << "Preparing ARSLANIUS..." << endl;
			Sleep(2000);
			PlaySound(MAKEINTRESOURCE(IDR_WAVE1), GetModuleHandle(NULL), SND_RESOURCE | SND_ASYNC | SND_LOOP);
			clearScreen();
			cout << "Type your Username: ";
			string nu, np;
			getline(cin, nu);
			nu = trim(nu);
			if (nu == "SYSTEM" || nu == "BarOS AUTHORITY\\SYSTEM" || nu == "SYSTEM ADMINISTRATOR") {
				cout << "[ ERROR ] Reserved username." << endl;
				return;
			}
			string user_exists = readFile(kernelPath);
			if (user_exists.find(nu + " =") != string::npos) {
				cout << "[ ERROR ] User already exists." << endl;
				return;
			}
			cout << "Password: ";
			char ch;
			while ((ch = _getch()) != '\r') {
				if (ch == '\b') {
					if (!np.empty()) {
						np.pop_back();
						cout << "\b \b";
					}
				}
				else {
					np += ch;
					cout << '*';
				}
			}
			cout << endl;

			string hash = calculateHash(np);
			appendFile(kernelPath, nu + " = " + hash + "\n");
			fs::create_directories(usersRoot + "\\" + nu);
			cout << "[ OK ] User created." << endl;
			pause();
			stringstream reg;
			reg << "OS_NAME=ARSLANIUS 30" << endl;
			reg << "SYSTEM_COLOR=0e" << endl;
			reg << "ADMIN_COLOR=4f" << endl;
			reg << "USER_COLOR=1f" << endl;
			reg << "ENABLE_LUA=1" << endl;
			reg << "LOCKDOWN=0" << endl;
			reg << "ADMIN_USER=" << endl;
			reg << "SETUP=0" << endl;
			reg << "REG_VERSION=" << REG_VERSION << endl;
			writeFile(regPath, reg.str());
			clearScreen();
			cout << "[ OK ] Everything is ready to go." << endl;
			pause();
			PlaySound(NULL, NULL, 0);
			bootMenu(); break;
		}
		case 'n': {
			exit(1); break;
		}
		default: bootMenu();
		}
		bootMenu();
	}
	if (fileExists(configRoot + "\\hibernate.sys")) {
		clearScreen();
		setColor("0f");
		cout << "Do you want to resume from hibernate.sys?" << endl;
		cout << "Y/N: ";
		char choice = _getch();
		choice = tolower(choice);
		cout << choice << endl;

		switch (choice) {
		case 'y': {
			BarOSkrnl("resume"); break;
		}
		}
	}

	if (recoveryRequest != "1") {
		clearScreen();
		setColor("0f");
		diagnostic = 0;
		safeMode = 0;
		rec = 0;
		cout << "======================================================================================================================" << endl;
		cout << "                                                 ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		if (lastSuccessfulMode != 0) {
			cout << "  Last Known Good Configuration [Mode " << lastSuccessfulMode << "]" << endl;
		}
		cout << "  1. Start ARSLANIUS Normally" << endl;
		cout << "  2. Safe Mode [No Services / No Autorun]" << endl;
		cout << "  3. Recovery Environment" << endl;
		cout << "  4. Diagnostic Mode LOCAL" << endl;
		cout << "  5. Diagnostic Mode NETWORK" << endl;
		cout << "----------------------------------------------------------------------------------------------------------------------" << endl;
		cout << "  Auto-boot in " << bootTimeout << " seconds..." << endl;
		cout << "  Press 6 for Manual" << endl;
		cout << "  Press 7 for update from old version" << endl;
		cout << "======================================================================================================================" << endl;

		// Simple timed input
		cout << "Select option (1-7): ";

		// Simulate auto-boot with sleep
		DWORD64 startTime = GetTickCount64();
		bool keyPressed = false;
		char choice = defaultMode; // default

		while (GetTickCount64() - startTime < (DWORD64)(bootTimeout * 1000)) {
			if (_kbhit()) {
				choice = _getch();
				keyPressed = true;
				break;
			}
			Sleep(100);
		}

		if (!keyPressed) {
			choice = '0' + defaultMode;
		}
		cout << choice << endl;

		if (choice == '1') bootChoice = 1;
		else if (choice == '2') bootChoice = 2;
		else if (choice == '3') bootChoice = 3;
		else if (choice == '4') bootChoice = 4;
		else if (choice == '5') bootChoice = 5;
		else if (choice == '6') Manual();
		else if (choice == '7') Update();
		else bootChoice = defaultMode;

		if (!fileExists(kernelPath)) {
			loader_errors("1");
		};
		if (!fileExists(regPath)) {
			loader_errors("4");
		};
		check_registry();
		if (REG_VERSION_FOUND != REG_VERSION) {
			loader_errors("3");
		}
		check_AUTHORITY();
		check_kernel();
		string kernel_hash_check = readFile(kernelPath);
		if (kernel_hash_check.find("SYSTEM = " + EXPECTED_SYSTEM_HASH) == string::npos) loader_errors("2");
		if (!fileExists(configRoot + "\\BCD")) {
			loader_errors("14");
		};
		check_BCD();
	}

	if (bootChoice == 3) {
		recoveryRequest = "1";
		bootChoice = 1;
	}
	if (recoveryRequest == "1") bootChoice = 1;
	if (bootChoice == 1) normalBoot();
	else if (bootChoice == 2) safeModeBoot();
	else if (bootChoice == 4) diagnosticMode(1);
	else if (bootChoice == 5) diagnosticMode(2);
}

void normalBoot() {
	// Check config
	if (recoveryRequest != "1") {
		if (!dirExists(configRoot)) {
			loader_errors("1a");
			return;
		}
		if (!fileExists(configRoot + "\\BCD")) {
			loader_errors("14");  // BCD not found
			return;
		}
	}

	// Boot animation
	for (int i = 1; i <= 20; i++) {
		clearScreen();
		setColor("0f");
		cout << "======================================================================================================================" << endl;
		cout << "                                                 ARSLANIUS BOOT MANAGER" << endl;
		cout << "======================================================================================================================" << endl;
		cout << "                                                  Loading " << osName << endl;
		cout << endl;
		cout << "         Build: " << currentBuild << endl;
		cout << "         Kernel: BarOS " << VersionBarOSkrnl << endl;
		cout << "         © Armsoup 2026" << endl;
		cout << endl;
		cout << "                                                     _____________" << endl;

		switch (i) {
		case 1: cout << "                                                    |.            |" << endl; break;
		case 2: cout << "                                                    |..           |" << endl; break;
		case 3: cout << "                                                    |...          |" << endl; break;
		case 4: cout << "                                                    | ...         |" << endl; break;
		case 5: cout << "                                                    |  ...        |" << endl; break;
		case 6: cout << "                                                    |   ...       |" << endl; break;
		case 7: cout << "                                                    |    ...      |" << endl; break;
		case 8: cout << "                                                    |     ...     |" << endl; break;
		case 9: cout << "                                                    |      ...    |" << endl; break;
		case 10: cout << "                                                    |       ...   |" << endl; break;
		case 11: cout << "                                                    |        ...  |" << endl; break;
		case 12: cout << "                                                    |         ... |" << endl; break;
		case 13: cout << "                                                    |          ...|" << endl; break;
		case 14: cout << "                                                    |           ..|" << endl; break;
		case 15: cout << "                                                    |            .|" << endl; break;
		case 16: cout << "                                                    |             |" << endl; break;
		case 17: cout << "                                                    |.            |" << endl; break;
		case 18: cout << "                                                    |..           |" << endl; break;
		case 19: cout << "                                                    |...          |" << endl; break;
		case 20: cout << "                                                    | ...         |" << endl; break;
		}
		cout << "                                                     -------------" << endl;
		Sleep(230);
	}
	if (recoveryRequest == "1") {
		recoveryRequest = "0";
		recoveryEnv();
	}
	logonScreen();
}

void safeModeBoot() {
	clearScreen();
	setColor("0f");
	safeMode = 1;
	cout << "======================================================================================================================" << endl;
	cout << "                                                 ARSLANIUS BOOT MANAGER" << endl;
	cout << "======================================================================================================================" << endl;
	Sleep(2000);

	if (!fileExists(configRoot + "\\BCD")) {
		PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
		cout << "[ ERROR ] BCD not found" << endl;
		Sleep(3000);
		return;
	}

	cout << "Loaded: \\Settings And System Files\\BCD" << endl;
	if (fileExists(kernelPath)) cout << "Loaded: \\Settings And System Files\\SAM" << endl;
	Sleep(1000);
	if (fileExists(regPath)) cout << "Loaded: \\Settings And System Files\\REG.cfg" << endl;
	Sleep(1000);
	cout << "Loaded: \\Settings And System Files\\systemprofile" << endl;
	Sleep(1000);
	cout << endl << "[ INFO ] Safe Mode enabled." << endl;
	Sleep(1000);

	// Disable services
	fs::remove(sysServices + "\\SysPulse.active");
	fs::remove(sysServices + "\\TrustedInstaller.active");
	fs::remove(sysServices + "\\NetMonitor.active");

	logonScreen();
}

void diagnosticMode(int mode) {
	diagnostic = mode;
	safeMode = 0;
	rec = 0;

	// Disable some services
	if (mode == 1) {
		fs::remove(sysServices + "\\TrustedInstaller.active");
		fs::remove(sysServices + "\\NetMonitor.active");
		currentUser = "BarOS SERVICE\\SysPulse";
	}
	else if (mode == 2) {
		fs::remove(sysServices + "\\SysPulse.active");
		fs::remove(sysServices + "\\TrustedInstaller.active");
		currentUser = "BarOS SERVICE\\NetMonitor";
	}

	interfaceScreen();
}

// =====================================================================
// RECOVERY ENVIRONMENT
// =====================================================================
void recoveryEnv() {
	rec = 1;
	diagnostic = 0;
	safeMode = 0;

	clearScreen();
	setColor("1f");
	cout << "======================================================================================================================" << endl;
	cout << "                                             ARSLANIUS RECOVERY ENVIRONMENT" << endl;
	cout << "======================================================================================================================" << endl;
	cout << endl;
	cout << "  [1] Startup Repair        - Fix kernel/registry" << endl;
	cout << "  [2] System Restore        - Go to restore points" << endl;
	cout << "  [3] System Image Recovery - Restore from backup" << endl;
	cout << "  [4] Command Line          - Mini cmd" << endl;
	cout << "  [5] Memory Diagnostic     - Check system memory" << endl;
	cout << "  [6] Return to boot menu" << endl;
	cout << endl;
	cout << "======================================================================================================================" << endl;
	cout << "Select option (1-6): ";

	char choice = _getch();
	cout << choice << endl;

	switch (choice) {
	case '1': startupRepair(); break;
	case '2': restoreMenu(); break;
	case '3': imageRecovery(); break;
	case '4':
		rec = 1;
		interfaceScreen();
		return;
	case '5': memoryDiag(); break;
	case '6': bootMenu(); return;
	default: recoveryEnv(); return;
	}

	recoveryEnv();
}

void startupRepair() {
	cout << endl << "[ WAIT ] Running Startup Repair..." << endl;

	ensureDirectories();

	// Create SAM
	stringstream kernel;
	kernel << "SYSTEM = 57a98c0544492de7afb6aaa83cfa058c6b445e7c4c24127b13d2cfac748e1150" << endl;
	kernel << "SYSTEM ADMINISTRATOR = 8e5a8afe96e11b2a6921cfd2af1dc2f1b78652a9a7c60de2d69cb2e523ca38da" << endl;
	writeFile(kernelPath, kernel.str());

	// Create BCD
	saveBCD();

	// Create REG.cfg
	stringstream reg;
	reg << "OS_NAME=ARSLANIUS 30" << endl;
	reg << "SYSTEM_COLOR=0e" << endl;
	reg << "ADMIN_COLOR=4f" << endl;
	reg << "USER_COLOR=1f" << endl;
	reg << "ENABLE_LUA=1" << endl;
	reg << "LOCKDOWN=1" << endl;
	reg << "ADMIN_USER=" << endl;
	reg << "SETUP=1" << endl;
	reg << "REG_VERSION=" << REG_VERSION << endl;
	writeFile(regPath, reg.str());

	writeLog("KERNEL_RESTORED_BY_RECOVERY");

	cout << "[ OK ] Startup Repair completed." << endl;
	pause();
}

void restoreMenu() {
	if (!dirExists(restoreRoot)) {
		PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
		cout << "[ ERROR ] No restore points directory." << endl;
		pause();
		return;
	}

	cout << "Available restore points:" << endl;
	// List directories
	WIN32_FIND_DATAA fd;
	HANDLE hFind = FindFirstFileA((restoreRoot + "\\*").c_str(), &fd);
	if (hFind != INVALID_HANDLE_VALUE) {
		do {
			if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
				string name = fd.cFileName;
				if (name != "." && name != "..") {
					cout << "  " << name << endl;
				}
			}
		} while (FindNextFileA(hFind, &fd));
		FindClose(hFind);
	}

	cout << endl << "Enter restore point name (or 0 for exit): ";
	string rpSel;
	cin >> rpSel;
	cin.ignore();

	if (rpSel == "0") return;

	string rpPath = restoreRoot + "\\" + rpSel;
	if (!dirExists(rpPath) || !fileExists(rpPath + "\\SAM")) {
		PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
		cout << "[ ERROR ] Invalid restore point." << endl;
		pause();
		return;
	}

	fs::copy_file(rpPath + "\\SAM", kernelPath, fs::copy_options::overwrite_existing);
	fs::copy_file(rpPath + "\\REG.cfg", regPath, fs::copy_options::overwrite_existing);
	fs::copy_file(rpPath + "\\system.log", logPath, fs::copy_options::overwrite_existing);

	writeLog("RESTORE_APPLIED_FROM_RECOVERY: " + rpSel);

	cout << "[ OK ] System restored from " << rpSel << "." << endl;
	pause();
}

void imageRecovery() {
	cout << endl << "===== SYSTEM IMAGE RECOVERY =====" << endl;
	cout << endl;

	string backupPath = rootPath + "\\Backup";
	if (dirExists(backupPath)) {
		cout << "[ FOUND ] Backup directory detected." << endl;
	}
	else {
		PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
		cout << "[ ERROR ] No backup image found." << endl;
		pause();
		return;
	}

	cout << "Restore from backup? (Y/N): ";
	char confirm;
	cin >> confirm;
	cin.ignore();

	if (toupper(confirm) != 'Y') return;

	cout << "[ WAIT ] Restoring system image..." << endl;

	// Simple copy (recursive copy would need more code)
	string cmd = "xcopy /e /y \"" + backupPath + "\\*\" \"" + rootPath + "\\\"";
	system(cmd.c_str());

	writeLog("IMAGE_RESTORE_EXECUTED");
	cout << "[ OK ] System image restored." << endl;
	pause();
}

void memoryDiag() {
	clearScreen();
	setColor("1f");
	cout << "======================================================================================================================" << endl;
	cout << "                                             ARSLANIUS MEMORY DIAGNOSTIC" << endl;
	cout << "======================================================================================================================" << endl;
	cout << endl << "Checking for memory problems..." << endl << endl;

	int total = 0;
	for (int i = 1; i <= 10; i++) {
		total += 64;
		cout << "Progress: " << (i * 10) << "% complete..." << endl;
		Sleep(1000);
	}

	cout << endl;
	cout << "[ PASS ] Memory test complete. No errors detected." << endl;
	cout << "Total memory simulated: " << total << " MB" << endl;
	cout << "Status: Healthy" << endl;
	pause();
}

// =====================================================================
// LOGON SCREEN
// =====================================================================

void logonScreen() {
	currentUser = "SYSTEM";
	userHome = sysProf;
	acpiRequest = 0;
	vector<string> users;
	users.push_back("Shutdown");
	users.push_back("Reboot");
	users.push_back("Rebootemer");

	if (fileExists(kernelPath)) {
		string kernel = readFile(kernelPath);
		istringstream iss(kernel);
		string line;
		while (getline(iss, line)) {
			line = trim(line);
			if (line.empty()) continue;
			size_t eqPos = line.find('=');
			if (eqPos != string::npos) {
				string username = trim(line.substr(0, eqPos));
				if (!username.empty() && username != "SYSTEM" && username != "SYSTEM ADMINISTRATOR") {
					users.push_back(username);
				}
			}
		}
		users.insert(users.begin(), "SYSTEM ADMINISTRATOR");
		users.insert(users.begin(), "SYSTEM");
	}

	int selected = 3;
	if (selected >= (int)users.size()) selected = 0;
	clearScreen();
	setColor("5b");

	cout << "======================================================================================================================" << endl;
	cout << "                                              " << osName << " LOGON" << endl;
	cout << "======================================================================================================================" << endl;
	cout << "  Use UP/DOWN arrows to select, ENTER to confirm, ESC for Shutdown" << endl;
	cout << "----------------------------------------------------------------------------------------------------------------------" << endl;
	cout << endl;
	int listStartY = 6;
	for (int i = 0; i < (int)users.size(); i++) {
		cout << "    ";
		if (users[i] == "Shutdown") {
			cout << "[SHUTDOWN] Turn off ARSLANIUS" << endl;
		}
		else if (users[i] == "Reboot") {
			cout << "[REBOOT] Restart ARSLANIUS" << endl;
		}
		else if (users[i] == "Rebootemer") {
			cout << "[EMERGENCY REBOOT] Force restart ARSLANIUS" << endl;
		}
		else if (users[i] == "SYSTEM") {
			cout << "BarOS AUTHORITY\\SYSTEM (System Account)" << endl;
		}
		else if (users[i] == "SYSTEM ADMINISTRATOR") {
			cout << "SYSTEM ADMINISTRATOR (Administrator)" << endl;
		}
		else {
			cout << users[i] << endl;
		}
	}

	cout << endl;
	cout << "----------------------------------------------------------------------------------------------------------------------" << endl;
	cout << "  Attempts: " << loginAttempts << " / " << MAX_LOGIN_ATTEMPTS << endl;
	cout << "======================================================================================================================" << endl;

	HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	GetConsoleScreenBufferInfo(hConsole, &csbi);

	auto setArrow = [&](int pos, bool active) {
		COORD coord;
		coord.X = 0;
		coord.Y = listStartY + pos;
		SetConsoleCursorPosition(hConsole, coord);
		if (active) {
			SetConsoleTextAttribute(hConsole, 0x5F);
			cout << "  > ";
		}
		else {
			SetConsoleTextAttribute(hConsole, 0x5B);
			cout << "    ";
		}
		SetConsoleTextAttribute(hConsole, 0x5B);
		};
	setArrow(selected, true);

	while (true) {
		int key = _getch();

		if (key == 224) {
			key = _getch();
			int oldSelected = selected;

			if (key == 72) {
				selected--;
				if (selected < 0) selected = (int)users.size() - 1;
			}
			else if (key == 80) {
				selected++;
				if (selected >= (int)users.size()) selected = 0;
			}
			if (selected != oldSelected) {
				setArrow(oldSelected, false);
				setArrow(selected, true);
			}
		}
		else if (key == 13) {  // Enter
			u_in = users[selected];

			if (u_in == "Shutdown") {
				writeLog("SHUTDOWN_FROM_LOGON");
				acpiRequest = 1;
				shutdownScreen();
				return;
			}
			if (u_in == "Reboot") {
				writeLog("REBOOT_FROM_LOGON");
				acpiRequest = 2;
				rebootScreen();
				return;
			}
			if (u_in == "Rebootemer") {
				writeLog("EMERGENCY_REBOOT_FROM_LOGON");
				arslogon("emergency_reboot");
				return;
			}

			failFile = sysServices + "\\fail_" + u_in + ".cnt";
			if (fileExists(failFile)) {
				ifstream f(failFile);
				f >> loginAttempts;
			}

			if (loginAttempts >= MAX_LOGIN_ATTEMPTS) {
				bsod("9");
				return;
			}

			COORD promptCoord;
			promptCoord.X = 0;
			promptCoord.Y = listStartY + (int)users.size() + 4;
			SetConsoleCursorPosition(hConsole, promptCoord);

			cout << "Password for " << u_in << ": ";
			char ch;
			p_in = "";
			while ((ch = _getch()) != '\r') {
				if (ch == '\b') {
					if (!p_in.empty()) {
						p_in.pop_back();
						cout << "\b \b";
					}
				}
				else {
					p_in += ch;
					cout << '*';
				}
			}
			cout << endl;

			arslogon("authorization");
			return;

		}
		else if (key == 27) {
			writeLog("SHUTDOWN_FROM_LOGON");
			acpiRequest = 1;
			shutdownScreen();
			return;
		}
	}
}

void arslogon(string_view authority) {
	if (authority == "authorization") {
		check_AUTHORITY();
		check_kernel();
		string kernel_hash_check = readFile(kernelPath);
		if (kernel_hash_check.find("SYSTEM = " + EXPECTED_SYSTEM_HASH) == string::npos) bsod("2");
		if (requestFromResume == 1) {
			if (currentUser == "BarOS SERVICE\\TrustedInstaller" ||
				currentUser == "BarOS SERVICE\\SysPulse" ||
				currentUser == "BarOS SERVICE\\NetMonitor") interfaceScreen();
		}
		string kernel = readFile(kernelPath);
		istringstream iss(kernel);
		string line;
		bool found = false;
		string storedHash;

		while (getline(iss, line)) {
			line = trim(line);
			if (requestFromResume == 0) {
				if (line.find(u_in + " =") == 0 || line.find(u_in + "=") == 0) {
					size_t eqPos = line.find('=');
					storedHash = trim(line.substr(eqPos + 1));
					found = true;
					break;
				}
			}
			else {
				if (line.find(currentUser + " =") == 0 || line.find(currentUser + "=") == 0) {
					size_t eqPos = line.find('=');
					storedHash = trim(line.substr(eqPos + 1));
					found = true;
					break;
				}
			}
		}
		if (requestFromResume == 0) {
			if (!found) {
				PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
				cout << "[ ERROR ] User not found." << endl;
				pause();
				logonScreen();
				return;
			}
		}

		string inputHash = calculateHash(p_in);

		if (inputHash == storedHash) {
			// Success
			if (requestFromResume == 0) {
				fs::remove(failFile);

				currentUser = u_in;
			}
			if (currentUser == "SYSTEM") {
				if (requestFromResume == 0) {
					userHome = sysProf;
				}
				currentUser = "BarOS AUTHORITY\\SYSTEM";
				regKey = "SYSTEM_COLOR";
			}
			else if (currentUser == "SYSTEM ADMINISTRATOR") {
				if (requestFromResume == 0) {
					userHome = usersRoot + "\\SYSTEM ADMINISTRATOR";
				}
				regKey = "ADMIN_COLOR";
			}
			else {
				if (requestFromResume == 0) {
					userHome = usersRoot + "\\" + currentUser;
				}
				regKey = "USER_COLOR";
			}

			fs::create_directories(userHome);
			SetCurrentDirectoryA(userHome.c_str());

			if (currentUser == "Armsoup") {
				cout << "[ ERROR ] Login denied by the system" << endl;
				pause();
				if (requestFromResume == 0) {
					logonScreen();
				}
				else {
					BarOSkrnl("resume");
				}
			}
			if (lockdown == 1) {
				cout << "[ ERROR ] Login denied by registry policy" << endl;
				pause();
				if (requestFromResume == 0) {
					logonScreen();
				}
				else {
					BarOSkrnl("resume");
				}
			}
			if (currentUser.find("BarOS SERVICE") == 0) {
				cout << "[ ERROR ] Seriously? You decided to join the " << osName << " service? Hahahaha" << endl;
				pause();
				if (requestFromResume == 0) {
					logonScreen();
				}
				else {
					BarOSkrnl("resume");
				}
			}
			// Welcome animation
			if (requestFromResume != 1) {
				UnchangeableUserHome = userHome;
			}
			if (requestFromResume == 1) {
				if (currentUser != "BarOS AUTHORITY\\SYSTEM") {
					UnchangeableUserHome = usersRoot + "\\" + currentUser;
				}
				else {
					UnchangeableUserHome = sysProf;
				}
			}
			string color_welcome_screen;
			PlaySound(MAKEINTRESOURCE(IDR_WAVE2), GetModuleHandle(NULL), SND_RESOURCE | SND_ASYNC);
			if (regKey == "SYSTEM_COLOR") color_welcome_screen = systemColor;
			if (regKey == "ADMIN_COLOR") color_welcome_screen = adminColor;
			if (regKey == "USER_COLOR") color_welcome_screen = userColor;
			for (int i = 1; i <= 9; i++) {
				setColor(color_welcome_screen);
				clearScreen();
				cout << "======================================================================================================================" << endl;
				cout << "                                                            ARSLOGON" << endl;
				cout << "======================================================================================================================" << endl;
				cout << "                                                          " << osName << endl;
				cout << endl;
				cout << "         Build: " << currentBuild << endl;
				cout << "         Kernel: BarOS " << VersionBarOSkrnl << endl;
				cout << "         Uptime: " << getUptime() << endl;
				cout << endl;

				switch (i) {
				case 1: cout << "                                                Applying your personal settings" << endl; break;
				case 2: cout << "                                                Applying your personal settings." << endl; break;
				case 3: cout << "                                                Applying your personal settings.." << endl; break;
				case 4: cout << "                                                Applying your personal settings..." << endl; break;
				case 5: cout << "                                                Applying your personal settings.." << endl; break;
				case 6: cout << "                                                Applying your personal settings." << endl; break;
				case 7: cout << "                                                Applying your personal settings" << endl; break;
				case 8: cout << "                                                Applying your personal settings." << endl; break;
				case 9: cout << "                                                Applying your personal settings.." << endl; break;
				}
				Sleep(500);
			}
			defaultuserHome = UnchangeableUserHome;
			if (regKey == "SYSTEM_COLOR") color_user = systemColor;
			if (regKey == "ADMIN_COLOR") color_user = adminColor;
			if (regKey == "USER_COLOR") color_user = userColor;
			fs::create_directories(UnchangeableUserHome + "\\USER_DATA");
			ConfigPath = UnchangeableUserHome + "\\USER_DATA" + "\\BAROS_USER_DATA.sys";
			if (fileExists(ConfigPath)) {
				ifstream config(ConfigPath);
				string line;
				while (getline(config, line)) {
					size_t sep = line.find('=');
					if (sep == string::npos) continue;
					string key = line.substr(0, sep);
					string value = line.substr(sep + 1);

					if (value.empty()) continue;

					try {
						if (key == "LOGOUT_TIMEOUT") logoutTimeout = stoi(value);
						else if (key == "USER_DEFAULT_HOME") defaultuserHome = value;
						else if (key == "COLOR") color_user = value;
						else if (key == "ENABLE_AUTORUN") autorun = stoi(value);
					}
					catch (...) {
						continue;
					}
				}
				if (requestFromResume != 1) {
					userHome = defaultuserHome;
				}
				fs::create_directories(userHome);
				SetCurrentDirectoryA(userHome.c_str());
			}
			if (requestFromResume == 1) {
				fs::remove(configRoot + "\\hibernate.sys");
			}
			requestFromResume = 0;
			applyColor();
		}
		else {
			if (requestFromResume == 0) {
				loginAttempts++;
				ofstream f(failFile);
				f << loginAttempts;
				f.close();

				PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
				cout << "[ ERROR ] Password incorrect. (Attempt " << loginAttempts << "/" << MAX_LOGIN_ATTEMPTS << ")" << endl;
				if (loginAttempts >= MAX_LOGIN_ATTEMPTS) {
					bsod("9");
					return;
				}
				pause();
				logonScreen();
			}
			else {
				PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
				cout << "[ ERROR ] Password incorrect." << endl;
				pause();
				BarOSkrnl("resume");
			}
		}
	}
	if (authority == "SudoAuth") {
		string a_p;
		sudo_command = 0;
		char ch;
		while ((ch = _getch()) != '\r') {
			if (ch == '\b') {
				if (!a_p.empty()) {
					a_p.pop_back();
					cout << "\b \b";
				}
			}
			else {
				a_p += ch;
				cout << '*';
			}
		}
		cout << endl;

		if (checkHash(a_p, EXPECTED_ADMIN_HASH)) {
			writeLog("SUDO_EXEC: " + t_c + " BY " + currentUser);
			ex_c = t_c;
			sudo_command = 1;
			core(ex_c);
		}
		else {
			sudo_command = 0;
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Access denied." << endl;
		}
		return;
	}
	if (authority == "SecureAS_lockmenu") {
		clearScreen();
		cout << "Secure Settings" << endl;
		cout << endl;
		cout << "                                                 1. Logout" << endl;
		cout << "                                                 2. Passwd" << endl;
		cout << "                                                 3. Shutdown" << endl;
		cout << "                                                 4. Reboot" << endl;
		cout << "                                                 5. Help" << endl;
		cout << "                                                 6. Return" << endl;
		cout << endl;
		cout << endl;
		cout << "Automatically logout after " << logoutTimeout << " seconds..." << endl;
		cout << "Select option (1-6): ";
		DWORD64 startTime = GetTickCount64();
		bool keyPressed = false;
		char ch = '1'; // default

		while (GetTickCount64() - startTime < (DWORD64)(logoutTimeout * 1000)) {
			if (_kbhit()) {
				ch = _getch();
				keyPressed = true;
				break;
			}
			Sleep(100);
		}
		cout << ch << endl;
		switch (ch) {
		case '1': acpiRequest = 0; arslogon("logoutRequest"); break;
		case '2': core("passwd"); break;
		case '3': acpiRequest = 1; arslogon("logoutRequest"); break;
		case '4': acpiRequest = 2; arslogon("logoutRequest"); break;
		case '5': core("help"); break;
		case '6': interfaceScreen();
		}
	}
	if (authority == "waitMode") {
		clearScreen();
		setColor("0f");
		cout << "\n\n                                                  " << osName << "\n\n";
		pause();
		applyColor();
	}
	if (authority == "logoutRequest") {
		clearScreen();
		PlaySound(MAKEINTRESOURCE(IDR_WAVE3), GetModuleHandle(NULL), SND_RESOURCE | SND_ASYNC);
		setColor("1f");
		cout << "                                                  " << osName << endl;
		cout << "\n\n                                             Saving your settings...\n\n";
		ConfigPath = UnchangeableUserHome + "\\USER_DATA" + "\\BAROS_USER_DATA.sys";
		fs::create_directories(UnchangeableUserHome + "\\USER_DATA");
		stringstream ss;
		ss << "LOGOUT_TIMEOUT=" << logoutTimeout << endl;
		ss << "USER_DEFAULT_HOME=" << defaultuserHome << endl;
		ss << "COLOR=" << color_user << endl;
		ss << "ENABLE_AUTORUN=" << autorun << endl;
		writeFile(ConfigPath, ss.str());
		Sleep(2000);
		if (acpiRequest == 1) shutdownScreen();
		else if (acpiRequest == 2) rebootScreen();
		else {
			currentUser = "SYSTEM";
			userHome = sysProf;
			logonScreen();
			return;
		}
	}
	if (authority == "emergency_reboot") {
		clearScreen();
		setColor("5b");
		cout << endl;
		cout << endl;
		cout << "                                                 Please Wait..." << endl;
		Sleep(500);
		cout << "                                             terminating ArsLogon..." << endl;
		Sleep(1000);
		bsod("DIED");
	}
	clearScreen();
	setColor("5b");
	cout << endl;
	cout << endl;
	cout << "                                                 Please Wait..." << endl;
	Sleep(2000);
	cout << "                                 ERROR: Session active, terminating ArsLogon..." << endl;
	Sleep(1500);
	bsod("DIED");
}



void applyColor() {
	string color;
	if (regKey == "SYSTEM_COLOR") color = systemColor;
	if (regKey == "ADMIN_COLOR") color = adminColor;
	if (regKey == "USER_COLOR") color = userColor;
	setColor(color);
	if (fileExists(ConfigPath)) {
		setColor(color_user);
	}
	interfaceScreen();
}

// =====================================================================
// INTERFACE AND COMMAND LOOP
// =====================================================================

void interfaceScreen() {
	if (currentUser != "KERNEL") saveBCD();

	// Start services
	if (safeMode == 0 && rec == 0 && diagnostic == 0 && currentUser != "KERNEL") {
		if (!fileExists(sysServices + "\\SysPulse.active")) {
			cout << "[ KERNEL ] Booting background service: BarOS SERVICE\\SysPulse..." << endl;
			writeFile(sysServices + "\\SysPulse.active", "RUNNING");
			Sleep(1000);
		}
		if (!fileExists(sysServices + "\\NetMonitor.active")) {
			cout << "[ KERNEL ] Booting background service: BarOS SERVICE\\NetMonitor..." << endl;
			writeFile(sysServices + "\\NetMonitor.active", "RUNNING");
			Sleep(1000);
		}
		if (!fileExists(sysServices + "\\TrustedInstaller.active")) {
			cout << "[ KERNEL ] Booting background service: BarOS SERVICE\\TrustedInstaller..." << endl;
			writeFile(sysServices + "\\TrustedInstaller.active", "RUNNING");
			Sleep(1000);
		}
	}

	if (rec == 1) {
		currentUser = "BarOS SERVICE\\TrustedInstaller";
		fs::remove(sysServices + "\\SysPulse.active");
		fs::remove(sysServices + "\\NetMonitor.active");
		userHome = sysServices + "\\TrustedInstaller";
		fs::create_directories(userHome);
	}
	if (diagnostic == 1) {
		currentUser = "BarOS SERVICE\\SysPulse";
		fs::remove(sysServices + "\\TrustedInstaller.active");
		fs::remove(sysServices + "\\NetMonitor.active");
		userHome = sysServices + "\\SysPulse";
		fs::create_directories(userHome);
	}
	if (diagnostic == 2) {
		currentUser = "BarOS SERVICE\\NetMonitor";
		fs::remove(sysServices + "\\SysPulse.active");
		fs::remove(sysServices + "\\TrustedInstaller.active");
		userHome = sysServices + "\\NetMonitor";
		fs::create_directories(userHome);
	}
	if (currentUser == "KERNEL") {
		currentUser = "BarOS\\KERNEL";
		userHome = sysProf;
		fs::create_directories(userHome);
	}

	SetCurrentDirectoryA(userHome.c_str());

	clearScreen();
	if (diagnostic == 2 || diagnostic == 1 || rec == 1 || currentUser == "BarOS\\KERNEL") setColor("0e");
	if (safeMode == 1) setColor("07");

	cout << osName << " [Build " << currentBuild << "] - Session: " << currentUser;
	cout << " (SAFE MODE: " << safeMode << ")" << endl;
	cout << "Profile: " << userHome << endl;
	cout << "Have ideas or found a bug? Visit: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus/discussions" << endl;
	cout << "Or: https://t.me/+8FQ20tOaKI5lNGMy" << endl;
	cout << "----------------------------------------------------------------------------------------------------------------------" << endl;

	// Check autorun
	if (safeMode == 0 && rec == 0 && diagnostic == 0 && currentUser != "BarOS\\KERNEL") {
		string alertFile = UnchangeableUserHome + "\\alert.sys";
		if (fileExists(alertFile)) {
			setColor("4f");
			cout << "======================================================================================================================" << endl;
			cout << "                                                    CRITICAL SYSTEM ALERT" << endl;
			cout << "======================================================================================================================" << endl;
			cout << endl;
			cout << "                                                   " << readFile(alertFile) << endl;
			cout << endl;
			cout << "----------------------------------------------------------------------------------------------------------------------" << endl;
			cout << endl;
			pause();
			fs::remove(alertFile);
			writeLog("ALERT_VIEVED: " + currentUser);
			applyColor();
			interfaceScreen();
		}
		string mailFile = UnchangeableUserHome + "\\mail.txt";
		if (fileExists(mailFile)) {
			cout << "[ MAIL ] You have unread messages! Type \"mail-read\"." << endl;
		}
		if (autorun == 1) {
			string autorunFile = UnchangeableUserHome + "\\autorun.txt";
			if (fileExists(autorunFile)) {
				string cmdLine = trim(readFile(autorunFile));
				if (!cmdLine.empty()) {
					cout << "[ AUTO ] Starting: " << cmdLine << "..." << endl;
					core(cmdLine);
				}
			}
		}
	}

	cmdLoop();
}

void cmdLoop() {
	while (true) {
		// services
		if (safeMode == 0 && rec == 0 && diagnostic == 0 && currentUser != "BarOS\\KERNEL") {
			if (!dirExists(sysServices)) fs::create_directories(sysServices);
			if (!fileExists(sysServices + "\\TrustedInstaller.active")) {
				writeFile(sysServices + "\\TrustedInstaller.active", "RUNNING");
			}
			if (fileExists(sysServices + "\\TrustedInstaller.active")) {
				int ins_err = 0;
				if (!fileExists(kernelPath)) ins_err = 1;
				if (!fileExists(regPath)) ins_err = 1;
				if (!fileExists(configRoot + "\\BCD")) ins_err = 1;

				if (ins_err == 1) {
					cout << "[BarOS SERVICE\\TrustedInstaller] Integrity violation detected!" << endl;
					cout << "[BarOS SERVICE\\TrustedInstaller] Executing background repair..." << endl;
					if (!fileExists(kernelPath)) {
						stringstream kernel_ins;
						kernel_ins << "SYSTEM = 57a98c0544492de7afb6aaa83cfa058c6b445e7c4c24127b13d2cfac748e1150" << endl;
						kernel_ins << "SYSTEM ADMINISTRATOR = 8e5a8afe96e11b2a6921cfd2af1dc2f1b78652a9a7c60de2d69cb2e523ca38da" << endl;
						writeFile(kernelPath, kernel_ins.str());
					}
					if (!fileExists(configRoot + "\\BCD")) {
						saveBCD();
					}
					if (!fileExists(regPath)) {
						stringstream reg_ins;
						reg_ins << "OS_NAME=ARSLANIUS 30" << endl;
						reg_ins << "SYSTEM_COLOR=0e" << endl;
						reg_ins << "ADMIN_COLOR=4f" << endl;
						reg_ins << "USER_COLOR=1f" << endl;
						reg_ins << "ENABLE_LUA=1" << endl;
						reg_ins << "LOCKDOWN=1" << endl;
						reg_ins << "ADMIN_USER=" << endl;
						reg_ins << "SETUP=1" << endl;
						reg_ins << "REG_VERSION=" << REG_VERSION << endl;
						writeFile(regPath, reg_ins.str());
						cout << "[BarOS SERVICE\\TrustedInstaller] System restored." << endl;
						writeLog("BarOS SERVICE\\TrustedInstaller: AUTO_REPAIR_SUCCESS");
					}
				}
			}
			if (fileExists(sysServices + "\\SysPulse.active")) {
				int PulseCheck = rand() % 10;
				if (PulseCheck == 5) {
					writeLog("BarOS SERVICE\\SYSPULSE: System Health OK");
				}
				const size_t MAX_LOG_SIZE_SYS = 10240;
				HANDLE hLogF = CreateFileA(logPath.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
				if (hLogF != INVALID_HANDLE_VALUE) {
					LARGE_INTEGER fileSize;
					if (GetFileSizeEx(hLogF, &fileSize)) {
						if (fileSize.QuadPart > MAX_LOG_SIZE_SYS) {
							CloseHandle(hLogF);
							fs::remove(logPath);
							writeLog("BarOS SERVICE\\SYSPULSE: LOG_CLEARED");
						}
					}
					CloseHandle(hLogF);
				}
			}
			if (fileExists(sysServices + "\\NetMonitor.active")) {
				int NetCheck = rand() % 10;
				if (NetCheck == 5) {
					string host = "github.com";
					string NetCheckS = "ping -n 1 " + host + " >nul 2>&1";
					int NetCheckResult = system(NetCheckS.c_str());
					if (NetCheckResult != 0) {
						cout << "BarOS SERVICE\\NETMONITOR: OFFLINE" << endl;
						writeLog("BarOS SERVICE\\NETMONITOR: OFFLINE");
					}
					else {
						cout << "BarOS SERVICE\\NETMONITOR: ONLINE" << endl;
						writeLog("BarOS SERVICE\\NETMONITOR: ONLINE");

					}
				}
			}
		}
		// Prompt
		sudo_command = 0;
		cout << currentUser << "@ARSLANIUS> ";
		string cmd = "";

		while (true) {
			if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) &&
				(GetAsyncKeyState(VK_MENU) & 0x8000) &&
				(GetAsyncKeyState(VK_SHIFT) & 0x8000)) {

				while (GetAsyncKeyState(VK_SHIFT) & 0x8000) {
					Sleep(50);
				}
				if (currentUser != "BarOS SERVICE\\TrustedInstaller" &&
					currentUser != "BarOS SERVICE\\SysPulse" &&
					currentUser != "BarOS SERVICE\\NetMonitor" &&
					currentUser != "BarOS\\KERNEL") {
					arslogon("SecureAS_lockmenu");
					break;
				}
			}

			if ((GetAsyncKeyState(VK_CONTROL) & 0x8000) &&
				(GetAsyncKeyState(VK_MENU) & 0x8000) &&
				(GetAsyncKeyState('K') & 0x8000)) {

				while (GetAsyncKeyState('K') & 0x8000) {
					Sleep(50);
				}
				if (currentUser != "BarOS SERVICE\\TrustedInstaller" &&
					currentUser != "BarOS SERVICE\\SysPulse" &&
					currentUser != "BarOS SERVICE\\NetMonitor" &&
					currentUser != "BarOS\\KERNEL") {
					BarOSkrnl("reload");
					break;
				}
			}
			if (_kbhit()) {
				char ch = _getch();

				if (ch == '\r' || ch == '\n') {
					cout << endl;
					break;
				}
				else if (ch == '\b') {
					if (!cmd.empty()) {
						cmd.pop_back();
						cout << "\b \b";
					}
				}
				else if (ch >= 32 && ch <= 126) {
					cmd += ch;
					cout << ch;
				}
			}

			Sleep(10);
		}

		cmd = trim(cmd);
		if (cmd.empty()) continue;

		core(cmd);
	}
}

void core(const string& cmd) {
	vector<string> parts = split(cmd, ' ');
	if (parts.empty()) return;

	if (cmd == "arslogon -emergency reboot" || cmd == "rebootemer") {
		arslogon("emergency_reboot");
	}
	if (cmd == "arslogon") {
		if (currentUser != "BarOS SERVICE\\TrustedInstaller" &&
			currentUser != "BarOS SERVICE\\SysPulse" &&
			currentUser != "BarOS SERVICE\\NetMonitor"
			) {
			arslogon("");
		}
	}
	if (cmd == "lockmenu") {
		if (currentUser != "BarOS SERVICE\\TrustedInstaller" &&
			currentUser != "BarOS SERVICE\\SysPulse" &&
			currentUser != "BarOS SERVICE\\NetMonitor" &&
			currentUser != "BarOS\\KERNEL"
			) {
			arslogon("SecureAS_lockmenu");
		}
	}
	string firstWord = parts[0];
	string rest;
	if (parts.size() > 1) {
		rest = parts[1];
		for (size_t i = 2; i < parts.size(); i++) {
			rest += " " + parts[i];
		}
	}

	ex_c = cmd;
	string f_w = firstWord;
	t_c = rest;

	// Handle sudo
	if (f_w == "sudo" || f_w == "Sudo") {
		if (t_c.empty()) {
			cout << "Usage: sudo [command]" << endl;
			return;
		}
		if (currentUser == "BarOS AUTHORITY\\SYSTEM" ||
			currentUser == "SYSTEM ADMINISTRATOR" ||
			currentUser == "BarOS\\KERNEL" ||
			currentUser == "BarOS SERVICE\\TrustedInstaller" ||
			currentUser == "BarOS SERVICE\\SysPulse" ||
			currentUser == "BarOS SERVICE\\NetMonitor" ||
			currentUser == adminUser) {
			ex_c = t_c;
			core(ex_c);
			return;
		}
		cout << "Enter ADMIN password: ";
		arslogon("SudoAuth");
		return;
	}

	// Command routing
	transform(ex_c.begin(), ex_c.end(), ex_c.begin(), ::tolower);

	if (currentUser == "GUEST") {
		bool allowed = false;
		vector<string> guestCmds = { "help", "game.bsodrunner", "lock", "license", "confeditor", "hibernate", "wait_mode", "echo", "ls", "cd",
									 "lockmenu", "report", "cls", "ver", "whoami",
									 "calc", "notepad", "reboot", "shutdown" };
		for (const string& c : guestCmds) {
			if (ex_c == c) { allowed = true; break; }
		}
		if (!allowed) {
			cout << "[ SECURITY ] Guest cannot use this command." << endl;
			return;
		}
	}

	if (currentUser == "BarOS\\KERNEL") {
		bool restricted = false;
		vector<string> kernelCmds = { "lock", "lockmenu" };
		for (const string& c : kernelCmds) {
			if (ex_c == c) { restricted = true; break; }
		}
		if (restricted) {
			cout << "[ SECURITY ] You cannot log out of your account." << endl;
			return;
		}
	}

	if (currentUser == "BarOS SERVICE\\TrustedInstaller") {
		bool allowed = false;
		vector<string> tiCmds = { "help", "mv", "bcdboot", "license", "hibernate", "cp", "rm", "touch", "edit",
								  "echo", "bcdedit", "mkdir", "ls", "cd", "cat", "ren",
								  "reset", "reboot_to_recovery", "cls", "ver", "whoami",
								  "events", "sfc", "adduser", "deluser", "regedit",
								  "reboot", "shutdown" };
		for (const string& c : tiCmds) {
			if (ex_c == c) { allowed = true; break; }
		}
		if (!allowed) {
			cout << "[ SECURITY ] Restricted." << endl;
			return;
		}
	}

	if (currentUser == "BarOS SERVICE\\SysPulse") {
		bool allowed = false;
		vector<string> spCmds = { "help", "ls", "sysinfo", "license", "hibernate", "events", "report", "echo",
								  "taskmgr", "cd", "cat", "reboot", "shutdown",
								  "reboot_to_recovery", "cls", "ver", "whoami" };
		for (const string& c : spCmds) {
			if (ex_c == c) { allowed = true; break; }
		}
		if (!allowed) {
			cout << "[ SECURITY ] Restricted." << endl;
			return;
		}
	}

	if (currentUser == "BarOS SERVICE\\NetMonitor") {
		bool allowed = false;
		vector<string> nmCmds = { "help", "reboot", "ping", "license", "hibernate", "netstat", "ipconfig",
								  "echo", "tracert", "nslookup", "arp", "route",
								  "shutdown", "cls", "whoami" };
		for (const string& c : nmCmds) {
			if (ex_c == c) { allowed = true; break; }
		}
		if (!allowed) {
			cout << "[ SECURITY ] Restricted." << endl;
			return;
		}
	}

	if (safeMode == 1) {
		bool allowed = false;
		vector<string> safeCmds = { "help", "lock", "wait_mode", "license", "hibernate", "lockmenu", "mv", "cp",
									"echo", "bcdboot", "bcdedit", "rm", "touch", "mkdir",
									"ls", "cd", "cat", "ren", "backup", "backup-restore",
									"sysinfo", "reset", "reboot_to_recovery", "report",
									"cls", "ver", "whoami", "events", "sfc", "restore-point",
									"restore", "adduser", "deluser", "regedit", "reboot",
									"shutdown" };
		for (const string& c : safeCmds) {
			if (ex_c == c) { allowed = true; break; }
		}
		if (!allowed) {
			cout << "[ SECURITY ] Safe mode restriction." << endl;
			return;
		}
	}

	if (currentUser == "SYSTEM ADMINISTRATOR") {
		bool allowed = false;
		vector<string> adminCmds = { "help", "calc", "game.bsodrunner", "passwd", "confeditor", "license", "ping", "as-pack", "hibernate", "as-unpack", "wait_mode", "lockmenu",
									 "echo", "autorun", "bcdedit", "bcdboot", "netstat",
									 "ipconfig", "tracert", "nslookup", "arp", "route",
									 "taskmgr", "sysinfo", "cp", "mv", "rm", "reset",
									 "bsod", "touch", "mkdir", "ls", "cd", "cat", "ren",
									 "backup", "backup-restore", "lock", "events",
									 "reboot_to_recovery", "report", "cls", "ver", "whoami",
									 "shutdown", "reboot", "adduser", "start", "sfc",
									 "clean", "mail-read", "mail-send", "edit", "guest-toggle",
									 "regedit", "deluser", "msg-all", "broadcast", "alert", "restore-point",
									 "restore" };
		for (const string& c : adminCmds) {
			if (ex_c == c) { allowed = true; break; }
		}
		if (!allowed) {
			cout << "[ SECURITY ] Restricted context." << endl;
			return;
		}
	}

	if (enableLua == 1 &&
		currentUser != "BarOS AUTHORITY\\SYSTEM" &&
		currentUser != "SYSTEM ADMINISTRATOR" &&
		currentUser != "BarOS\\KERNEL" &&
		currentUser != adminUser &&
		currentUser != "BarOS SERVICE\\TrustedInstaller" &&
		currentUser != "BarOS SERVICE\\SysPulse" &&
		currentUser != "BarOS SERVICE\\NetMonitor" &&
		sudo_command == 0) {
		bool allowed = false;
		vector<string> userCmds = { "help", "arsstore", "game.bsodrunner", "confeditor", "license", "as - pack", "hibernate", "as - unpack", "mkdir", "wait_mode", "echo", "lockmenu",
									"autorun", "ping", "cp", "mv", "touch", "backup",
									"ls", "cd", "cat", "ren", "backup-restore", "passwd",
									"reboot_to_recovery", "lock", "calc", "sysinfo",
									"restore", "restore-point", "mail-send", "mail-read",
									"clean", "report", "cls", "ver", "whoami", "calc",
									"notepad", "reboot", "shutdown" };
		for (const string& c : userCmds) {
			if (ex_c == c) { allowed = true; sudo_command = 0; break; }
		}
		if (!allowed) {
			cout << "Error: Access Denied. Use \"sudo " << ex_c << "\"." << endl;
			sudo_command = 0;
			return;
		}
	}

	if (ex_c == "help" || ex_c == "?") {
		cout << "Apps: Notepad, Calc, taskmgr, confeditor, license, edit, install, regedit, ArsStore, sysinfo, game.bsodrunner" << endl;
		cout << "System: Help, Lock, lockmenu, hibernate, sudo, cls, Shutdown, ver, whoami, reboot, clean, events, restore-point, restore, echo, passwd, backup, backup-restore, ls, wait_mode, cd, cat, ren, mkdir, touch, cp, rebootemer or arslogon -emergency reboot, mv, autorun" << endl;
		cout << "Admin: adduser, deluser, alert, Guest, report, reset, reboot_to_recovery, bsod, rm, netstat, ipconfig, tracert, nslookup, arp, route, bcdboot, bcdedit" << endl;
	}
	else if (ex_c == "cls") interfaceScreen();
	else if (ex_c == "ver") cout << osName << " [Build " << currentBuild << "]" << endl;
	else if (ex_c == "whoami") {
		cout << "Current User: " << currentUser << endl;
		cout << "Path: " << userHome << endl;
	}
	else if (ex_c == "mail-read") {
		string mailFile = UnchangeableUserHome + "\\mail.txt";
		if (fileExists(mailFile)) {
			clearScreen();
			cout << "======================================================================================================================" << endl;
			cout << "                                                        MAILBOX" << endl;
			cout << "======================================================================================================================" << endl;
			cout << endl;
			cout << readFile(mailFile) << endl;
			cout << endl;
			cout << "----------------------------------------------------------------------------------------------------------------------" << endl;
			cout << "Clear mailbox? (Y/N): ";
			char choice = _getch();
			choice = tolower(choice);
			cout << choice << endl;

			switch (choice) {
			case 'y': {
				fs::remove(mailFile);
				cout << "[ OK ] Mailbox cleared." << endl;
				break;
			}
			}
		}
		else {
			cout << "[ INFO ] No mail." << endl;
		}
	}
	else if (ex_c == "license") {
		cout << "======================================================================================================================" << endl;
		cout << "                                                        " << osName << endl;
		cout << "                                                  Copyright © 2026 Armsoup" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "This program is FREE SOFTWARE under the GNU AGPL - 3.0 license." << endl;
		cout << endl;
		cout << "You MAY:" << endl;
		cout << " -Use it for any purpose" << endl;
		cout << " -Modify it" << endl;
		cout << " -Distribute it" << endl;
		cout << endl;
		cout << "You MUST:" << endl;
		cout << " -Keep the original copyright notice(© Armsoup)" << endl;
		cout << " -Disclose ALL source code(including your changes)" << endl;
		cout << " -License your modified version under AGPL - 3.0 as well" << endl;
		cout << endl;
		cout << "======================================================================================================================" << endl;
		cout << "!WARNING!" << endl;
		cout << "If you remove the copyright notice, rename the project, or try to hide its origin:" << endl;
		cout << " -Your license is automatically TERMINATED" << endl;
		cout << " -You are violating DMCA(17 U.S.C.§ 1202)" << endl;
		cout << " -The author(I`m, Armsoup) has the right to sue you" << endl;
		cout << " -Maximum statutory damages: up to $150, 000 per work" << endl;
		cout << "In simple terms: STEAL MY CODE, REMOVE MY NAME = YOU'RE F***ED." << endl;
		cout << endl;
		cout << "Full license: https://www.gnu.org/licenses/agpl-3.0.html" << endl;
		cout << "or: https://github.com/Armsoup/ARSLANIUS_C-Plus_Plus?tab=AGPL-3.0-1-ov-file" << endl;
		cout << "Type 'license' on command line to view this again" << endl;
		cout << "======================================================================================================================" << endl;
	}
	else if (ex_c == "mail-send") {
		string m_to, m_text;
		cout << "To user: ";
		getline(cin, m_to);
		m_to = trim(m_to);
		if (m_to.empty()) {
			cout << "[ ERROR ] Username cannot be empty." << endl;
			return;
		}
		string hkernel = readFile(kernelPath);
		if (hkernel.find(m_to + " =") == string::npos && hkernel.find(m_to + "=") == string::npos && m_to != "SYSTEM" && m_to != "SYSTEM ADMINISTRATOR") {
			cout << "[ ERROR ] User not found." << endl;
			return;
		}
		cout << "Message: ";
		getline(cin, m_text);
		if (m_text.empty()) {
			cout << "[ ERROR ] Message cannot be empty." << endl;
			return;
		}
		string destPath;
		if (m_to == "SYSTEM" || m_to == "BarOS AUTHORITY\\SYSTEM") {
			destPath = sysProf;
		}
		else if (m_to == "SYSTEM ADMINISTRATOR") {
			destPath = usersRoot + "\\SYSTEM ADMINISTRATOR";
		}
		else {
			destPath = usersRoot + "\\" + m_to;
		}
		fs::create_directories(destPath);
		string mailFile = destPath + "\\mail.txt";
		string mailEntry = "[" + getCurrentDateTime() + "] " + "From " + currentUser + ": " + m_text + "\n\n";
		appendFile(mailFile, mailEntry);
		writeLog("MAIL_SENT: " + currentUser);
		cout << "[ OK ] Message sent to " << m_to << "." << endl;
	}
	else if (ex_c == "msg-all" || ex_c == "broadcast") {
		string msgText;
		cout << "Global Message: ";
		getline(cin, msgText);
		if (msgText.empty()) {
			cout << "[ ERROR ] Message cannot be empty." << endl;
			return;
		}
		string mailEntry = "[" + getCurrentDateTime() + "] " + "[GLOBAL] From " + currentUser + ": " + msgText + "\n\n";
		for (const auto& entry : fs::directory_iterator(usersRoot)) {
			if (entry.is_directory()) {
				string mailFile = entry.path().string() + "\\mail.txt";
				appendFile(mailFile, mailEntry);
			}
		}
		string sysMail = sysProf + "\\mail.txt";
		appendFile(sysMail, mailEntry);
		writeLog("BROADCAST: " + currentUser);
		cout << "[ OK ] Broadcast send to all users." << endl;
	}
	else if (ex_c == "alert") {
		string alertText;
		cout << "Alert Message: ";
		getline(cin, alertText);
		if (alertText.empty()) {
			cout << "[ ERROR ] Alert Message cannot be empty." << endl;
			return;
		}
		for (const auto& entry : fs::directory_iterator(usersRoot)) {
			if (entry.is_directory()) {
				string alertFile = entry.path().string() + "\\alert.sys";
				writeFile(alertFile, alertText);
			}
		}
		string sysAlert = sysProf + "\\alert.sys";
		writeFile(sysAlert, alertText);
		writeLog("ALERT_SENT: " + alertText);
		cout << "[ OK ] Alert deployed to all users." << endl;
	}
	else if (ex_c == "as-pack") {
		string zipName;
		cout << "Enter archive name (ex: backup): ";
		getline(cin, zipName);
		zipName = trim(zipName);
		if (zipName.empty()) {
			cout << "[ ERROR ] Archive name cannot be empty." << endl;
			return;
		}
		string zipPath = zipName + ".zip";
		cout << "[ WAIT ] Packing files to " << zipPath << "..." << endl;
		if (fs::exists(zipPath)) fs::remove(zipPath);
		mz_zip_archive zip = {};
		mz_zip_writer_init_file(&zip, zipPath.c_str(), 0);
		for (const auto& entry : fs::directory_iterator(fs::current_path())) {
			if (entry.is_regular_file()) {
				string name = entry.path().filename().string();
				if (name != zipPath && name != "ARSLANIUS.exe") {
					cout << "[ PACK ] Adding: " << name << endl;
					string content = readFile(entry.path().string());
					mz_zip_writer_add_mem(&zip, name.c_str(), content.c_str(), content.size(), MZ_DEFAULT_COMPRESSION);
				}
			}
		}
		mz_zip_writer_finalize_archive(&zip);
		mz_zip_writer_end(&zip);
		writeLog("ARCHIVE_CREATED: " + zipPath);
		cout << "[ OK ] Archive " << zipPath << " created." << endl;
	}
	else if (ex_c == "as-unpack") {
		string zipName;
		cout << "Enter archive to unpack: ";
		getline(cin, zipName);
		zipName = trim(zipName);
		if (!fileExists(zipName)) {
			cout << "[ ERROR ] Archive not found." << endl;
			return;
		}
		cout << "[ WAIT ] Extracting files..." << endl;
		mz_zip_archive zip = {};
		if (!mz_zip_reader_init_file(&zip, zipName.c_str(), 0)) {
			cout << "[ ERROR ] Failed to open archive." << endl;
			return;
		}
		int numFiles = mz_zip_reader_get_num_files(&zip);
		for (int i = 0; i < numFiles; i++) {
			mz_zip_archive_file_stat fileStat;
			if (mz_zip_reader_file_stat(&zip, i, &fileStat)) {
				string fileName = fileStat.m_filename;
				cout << "[ EXTRACT ] Writing: " << fileName << endl;
				size_t uncompSize;
				void* data = mz_zip_reader_extract_to_heap(&zip, i, &uncompSize, 0);
				if (data) {
					string content((char*)data, uncompSize);
					writeFile(fileName, content);
					mz_free(data);
				}
			}
		}
		mz_zip_reader_end(&zip);
		writeLog("ARCHIVE_EXTRACTED: " + zipName);
		cout << "[ OK ] Archive extracted." << endl;
	}
	else if (ex_c == "arsstore") {
		clearScreen();
		cout << "======================================================================================================================" << endl;
		cout << "                                                    ARSLANIUS STORE[v2.0]" << endl;
		cout << "======================================================================================================================" << endl;
		cout << "Available Apps :" << endl;
		cout << " [1] System Scanner(Utility)" << endl;
		cout << " [2] NotePad Lite(Office)" << endl;
		cout << " [3] Calc(Utility)" << endl;
		cout << " [4] Exit Store" << endl;
		cout << "----------------------------------------------------------------------------------------------------------------------" << endl;
		cout << "Select number: ";
		char choice = _getch();
		cout << choice << endl;
		if (choice == '1') installapp("1");
		else if (choice == '2') installapp("2");
		else if (choice == '3') installapp("3");
		else if (choice == '4') interfaceScreen();
		core("arsstore");
	}
	else if (ex_c == "guest-toggle") {
		cout << "Enable Guest Mode? (Y/N): ";
		char g_act = _getch();
		cout << g_act << endl;
		if (toupper(g_act) == 'Y') {
			string kernel = readFile(kernelPath);
			if (kernel.find("GUEST =") != string::npos || kernel.find("GUEST=") != string::npos) {
				cout << "[ ERROR ] GUEST already exists." << endl;
				return;
			}
			string hash = calculateHash("GUEST");
			appendFile(kernelPath, "GUEST = " + hash + "\n");
			fs::create_directories(usersRoot + "\\GUEST");
			writeLog("GUEST_ENABLED");
			cout << "[ OK ] Guest mode ACTIVE. Login: GUEST / Pass: GUEST" << endl;
		}
		else {
			string kernel = readFile(kernelPath);
			istringstream iss(kernel);
			string line, newKernel;
			while (getline(iss, line)) {
				if (line.find("GUEST =") != 0 && line.find("GUEST=") != 0) {
					newKernel += line + "\n";
				}
			}
			writeFile(kernelPath, newKernel);
			string guestDir = usersRoot + "\\GUEST";
			if (fs::exists(guestDir)) {
				fs::remove_all(guestDir);
			}
			writeLog("GUEST_DISABLED");
			cout << "[ OK ] Guest mode DISABLED. Profile wiped." << endl;
		}
	}
	else if (ex_c == "ls") system("dir /w");
	else if (ex_c == "cd") {
		string newPath;
		cout << "Enter path: ";
		getline(cin, newPath);
		newPath = trim(newPath);
		if (!newPath.empty()) {
			if (SetCurrentDirectoryA(newPath.c_str())) {
				userHome = newPath;
				cout << "[ OK ] Directory changed to " << userHome << endl;
			}
			else {
				PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
				cout << "[ ERROR ] Invalid path." << endl;
			}
		}
	}
	else if (ex_c == "cat") {
		string targetFile;
		cout << "Enter filename: ";
		getline(cin, targetFile);
		targetFile = trim(targetFile);
		if (fileExists(targetFile)) {
			cout << readFile(targetFile) << endl;
		}
		else {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] File not found." << endl;
		}
	}
	else if (ex_c == "autorun") {
		string autorunCmd;
		cout << "Command to autorun: ";
		getline(cin, autorunCmd);
		autorunCmd = trim(autorunCmd);
		if (autorunCmd.empty()) {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Command cannot be empty." << endl;
			return;
		}
		writeFile(UnchangeableUserHome + "\\autorun.txt", autorunCmd);
		writeLog("AUTORUN_SET: " + autorunCmd + " BY " + currentUser);
		cout << "[ OK ] Autorun set: " << autorunCmd << endl;
	}
	else if (ex_c == "mkdir") {
		string folderName;
		cout << "Enter folder name: ";
		getline(cin, folderName);
		folderName = trim(folderName);
		if (fs::create_directory(folderName)) {
			cout << "[ OK ] Folder created." << endl;
		}
		else {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Failed to create folder." << endl;
		}
	}
	else if (ex_c == "report") {
		cout << "[ WAIT ] Generating HTML Report..." << endl;
		string reportPath = rootPath + "\\Report.html";
		ofstream report(reportPath);
		if (!report.is_open()) {
			cout << "[ ERROR ] Failed to create report file." << endl;
			return;
		}
		report << "<html><body style='background:#111;color:#0f0;font-family:monospace'>" << endl;
		report << "<h1>" << osName << " - SYSTEM REPORT</h1>" << endl;
		report << "<hr>" << endl;
		report << "<p>Build: " << currentBuild << "</p>" << endl;
		report << "<p>Kernel: BarOS " << VersionBarOSkrnl << "</p>" << endl;
		report << "<p>Active User: " << currentUser << "</p>" << endl;
		report << "<p>Safe Mode: " << safeMode << "</p>" << endl;
		report << "<h2>Registered Users:</h2><pre>" << endl;
		report << readFile(kernelPath) << endl;
		report << "</pre>" << endl;
		report << "<h2>System Log (last 50 lines):</h2><pre>" << endl;
		string log = readFile(logPath);
		istringstream iss(log);
		string line;
		vector<string> lines;
		while (getline(iss, line)) lines.push_back(line);
		int start = max(0, (int)lines.size() - 50);
		for (int i = start; i < (int)lines.size(); i++) {
			report << lines[i] << endl;
		}
		report << "</pre></body></html>" << endl;
		report.close();
		writeLog("REPORT_GENERATED");
		cout << "[ OK ] Report generated: " << reportPath << endl;
		string cmd = "start \"\" \"" + reportPath + "\"";
		system(cmd.c_str());
	}
	else if (ex_c == "touch") {
		string touchFile;
		cout << "Enter filename: ";
		getline(cin, touchFile);
		touchFile = trim(touchFile);
		if (fileExists(touchFile)) {
			cout << "[ ERROR ] File exists. Overwrite? (Y/N): ";
			char c = _getch();
			cout << c << endl;
			if (toupper(c) == 'Y') writeFile(touchFile, "");
		}
		else {
			writeFile(touchFile, "");
			cout << "[ OK ] File created." << endl;
		}
	}
	else if (ex_c == "cp") {
		string src, dst;
		cout << "Source file: ";
		getline(cin, src);
		src = trim(src);
		cout << "Destination file: ";
		getline(cin, dst);
		dst = trim(dst);
		if (fs::copy_file(src, dst)) {
			cout << "[ OK ] Copied." << endl;
		}
		else {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Copy failed." << endl;
		}
	}
	else if (ex_c == "mv") {
		string src, dst;
		cout << "Source file: ";
		getline(cin, src);
		src = trim(src);
		cout << "Destination file: ";
		getline(cin, dst);
		dst = trim(dst);
		if (MoveFileA(src.c_str(), dst.c_str())) {
			cout << "[ OK ] Moved." << endl;
		}
		else {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Move failed." << endl;
		}
	}
	else if (ex_c == "rm") {
		string targetFile;
		cout << "File to delete: ";
		getline(cin, targetFile);
		targetFile = trim(targetFile);
		if (fs::remove(targetFile)) {
			cout << "[ OK ] Deleted." << endl;
		}
		else {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Delete failed." << endl;
		}
	}
	else if (ex_c == "ren") {
		string oldName, newName;
		cout << "Old name: ";
		getline(cin, oldName);
		oldName = trim(oldName);
		cout << "New name: ";
		getline(cin, newName);
		newName = trim(newName);
		if (rename(oldName.c_str(), newName.c_str()) == 0) {
			cout << "[ OK ] Renamed." << endl;
		}
		else {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Rename failed." << endl;
		}
	}
	else if (ex_c == "echo") {
		string text;
		cout << "Enter text: ";
		getline(cin, text);
		cout << text << endl;
	}
	else if (ex_c == "confeditor") {
		string AUTORUN = to_string(autorun);
		auto sanitize = [](string& s, string def) {
			if (s.empty()) { s = def; return; }
			for (char c : s) {
				if ((unsigned char)c < 32 && c != '\n' && c != '\r') {
					s = def;
					return;
				}
			}
			};

		sanitize(defaultuserHome, defaultuserHome);
		sanitize(color_user, color_user);
		sanitize(AUTORUN, "1");
		cout << "[ SECURITY ] Press enter." << endl;
		if (cin.peek() == EOF || cin.peek() == '\n') cin.ignore();
		cin.ignore(cin.rdbuf()->in_avail(), '\n');
		if (cin.peek() == '\n') cin.ignore();
		string input;
		cout << "Enter new Default Home (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) defaultuserHome = t;
		}
		cout << "Enter new color (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) color_user = t;
		}
		cout << "Enter new autorun enable/disable (0 - disabled, 1 - enabled) (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) AUTORUN = t;
		}
		if (defaultuserHome.empty()) defaultuserHome = UnchangeableUserHome;
		if (color_user.empty()) color_user = color_user;
		if (AUTORUN.empty()) AUTORUN = "1";
		autorun = stoi(AUTORUN);

		stringstream config;
		config << "LOGOUT_TIMEOUT=" << logoutTimeout << endl;
		config << "USER_DEFAULT_HOME=" << defaultuserHome << endl;
		config << "COLOR=" << color_user << endl;
		config << "ENABLE_AUTORUN=" << autorun << endl;
		writeFile(ConfigPath, config.str());
		cout << "[ DONE ] user config updated." << endl;
	}
	else if (ex_c == "game.bsodrunner") BSOD_Runner();
	else if (ex_c == "reset") {
		cout << "WARNING: This will delete ALL users and reset system to defaults. " << endl;
		cout << "Type YES to continue: ";
		string confirm;
		getline(cin, confirm);
		confirm = trim(confirm);
		if (confirm == "YES") {
			startupRepair();
			userHome = rootPath;
			SetCurrentDirectoryA(userHome.c_str());
			try {
				fs::path pathToRemove = rootPath + "\\Users";
				if (fs::exists(pathToRemove)) {
					fs::remove_all(pathToRemove);
				}
				cout << "[ OK ] System reset completed. Shutting Down..." << endl;
			}
			catch (const fs::filesystem_error& e) {
				bsod("");
			}
			pause();
			acpiRequest = 1;
			shutdownScreen();
		}
		else {
			cout << "Canceled." << endl;
		}
	}
	else if (ex_c == "shutdown") {
		acpiRequest = 1;
		arslogon("logoutRequest");
	}
	else if (ex_c == "hibernate") {
		BarOSkrnl("hibernate");
	}
	else if (ex_c == "reboot") {
		acpiRequest = 2;
		arslogon("logoutRequest");
	}
	else if (ex_c == "lock") {
		acpiRequest = 0;
		arslogon("logoutRequest");
	}
	else if (ex_c == "bsod") bsod("666");
	else if (ex_c == "wait_mode") arslogon("waitMode");
	else if (ex_c == "adduser") {
		string nu, np;
		cout << "Username: ";
		getline(cin, nu);
		nu = trim(nu);
		if (nu == "SYSTEM" || nu == "BarOS AUTHORITY\\SYSTEM" || nu == "SYSTEM ADMINISTRATOR") {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Reserved username." << endl;
			return;
		}
		string user_exists = readFile(kernelPath);
		if (user_exists.find(nu + " =") != string::npos) {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] User already exists." << endl;
			return;
		}
		cout << "Password: ";
		char ch;
		while ((ch = _getch()) != '\r') {
			if (ch == '\b') {
				if (!np.empty()) {
					np.pop_back();
					cout << "\b \b";
				}
			}
			else {
				np += ch;
				cout << '*';
			}
		}
		cout << endl;

		string hash = calculateHash(np);
		appendFile(kernelPath, nu + " = " + hash + "\n");
		fs::create_directories(usersRoot + "\\" + nu);
		writeLog("NEW_USER_CREATED: " + nu);
		cout << "[ OK ] User created." << endl;
	}
	else if (ex_c == "deluser") {
		string du;
		cout << "Enter username: ";
		getline(cin, du);
		du = trim(du);
		if (du == "SYSTEM" || du == "SYSTEM ADMINISTRATOR") {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Restricted." << endl;
			return;
		}

		string kernel = readFile(kernelPath);
		istringstream iss(kernel);
		string line, newKernel;
		while (getline(iss, line)) {
			if (line.find(du + " =") != 0 && line.find(du + "=") != 0) {
				newKernel += line + "\n";
			}
		}
		writeFile(kernelPath, newKernel);
		RemoveDirectoryA((usersRoot + "\\" + du).c_str());
		cout << "[ OK ] User removed." << endl;
	}
	else if (ex_c == "passwd") {
		if (currentUser == "BarOS AUTHORITY\\SYSTEM" ||
			currentUser.find("BarOS SERVICE") == 0) {
			cout << "Cannot change this account's password." << endl;
			return;
		}
		string old, new1, new2;
		cout << "Current password: ";
		char ch;
		while ((ch = _getch()) != '\r') {
			if (ch == '\b') {
				if (!old.empty()) {
					old.pop_back();
					cout << "\b \b";
				}
			}
			else { old += ch; cout << '*'; }
		}
		cout << endl;
		string inputHash = calculateHash(old);

		string kernel_passwd = readFile(kernelPath);
		istringstream isspasswd(kernel_passwd);
		string line_passwd;
		bool found = false;
		string storedHash;

		while (getline(isspasswd, line_passwd)) {
			line_passwd = trim(line_passwd);
			if (line_passwd.find(currentUser + " =") == 0 || line_passwd.find(u_in + "=") == 0) {
				size_t eqPos = line_passwd.find('=');
				storedHash = trim(line_passwd.substr(eqPos + 1));
				found = true;
				break;
			}
		}
		if (inputHash == storedHash) {
		}
		else {
			PlaySoundA("SystemHand", NULL, SND_ALIAS | SND_ASYNC);
			cout << "[ ERROR ] Password incorrect." << endl;
			pause();
			cmdLoop();
		}

		cout << "New password: ";
		while ((ch = _getch()) != '\r') {
			if (ch == '\b') {
				if (!new1.empty()) {
					new1.pop_back();
					cout << "\b \b";
				}
			}
			else { new1 += ch; cout << '*'; }
		}
		cout << endl;

		cout << "Confirm: ";
		while ((ch = _getch()) != '\r') {
			if (ch == '\b') {
				if (!new2.empty()) {
					new2.pop_back();
					cout << "\b \b";
				}
			}
			else { new2 += ch; cout << '*'; }
		}
		cout << endl;

		if (new1 != new2) {
			cout << "Passwords do not match." << endl;
			return;
		}

		// Update kernel
		string kernel = readFile(kernelPath);
		string displayName = currentUser;
		if (displayName == "BarOS AUTHORITY\\SYSTEM") displayName = "SYSTEM";

		istringstream iss(kernel);
		string line, newKernel;
		while (getline(iss, line)) {
			if (line.find(displayName + " =") == 0 || line.find(displayName + "=") == 0) {
				newKernel += displayName + " = " + calculateHash(new1) + "\n";
			}
			else {
				newKernel += line + "\n";
			}
		}
		writeFile(kernelPath, newKernel);
		cout << "[ OK ] Password changed." << endl;
	}
	else if (ex_c == "restore-point") {
		ensureDirectories();
		if (!dirExists(restoreRoot)) fs::create_directories(restoreRoot);

		string rpName = "RP_" + getCurrentDateTime();
		for (auto& c : rpName) if (c == ' ' || c == ':') c = '_';

		string rpDir = restoreRoot + "\\" + rpName;
		fs::create_directories(rpDir);
		fs::copy_file(kernelPath, rpDir + "\\SAM", fs::copy_options::overwrite_existing);
		fs::copy_file(regPath, rpDir + "\\REG.cfg", fs::copy_options::overwrite_existing);
		fs::copy_file(logPath, rpDir + "\\system.log", fs::copy_options::overwrite_existing);

		writeLog("RESTORE_POINT_CREATED: " + rpName);
		cout << "[ OK ] Restore point created: " << rpName << endl;
	}
	else if (ex_c == "restore") {
		restoreMenu();
	}
	else if (ex_c == "backup") {
		string backupDir = rootPath + "\\Backup";
		if (fs::exists(backupDir)) {
			fs::remove_all(backupDir);
		}
		fs::create_directories(backupDir);
		for (const auto& entry : fs::directory_iterator(rootPath)) {
			string name = entry.path().filename().string();
			if (name != "Backup") {
				if (entry.is_directory()) {
					fs::copy(entry.path(), backupDir + "\\" + name, fs::copy_options::recursive);
				}
				else {
					fs::copy_file(entry.path(), backupDir + "\\" + name, fs::copy_options::overwrite_existing);
				}
			}
		}
		writeLog("SYSTEM_BACKUP_EXECUTED");
		cout << "[ OK ] Backup created." << endl;
	}
	else if (ex_c == "backup-restore") {
		imageRecovery();
	}
	else if (ex_c == "sfc") {
		cout << "[ SYSTEM ] Beginning system file check..." << endl;
		bool errors = false;
		if (!fileExists(configRoot + "\\BCD")) { cout << "[ FAIL ] BCD MISSING" << endl; errors = true; }
		else cout << "[ OK ] BCD" << endl;
		if (!fileExists(kernelPath)) { cout << "[ FAIL ] SAM MISSING" << endl; errors = true; }
		else cout << "[ OK ] SAM" << endl;
		if (!fileExists(regPath)) { cout << "[ FAIL ] REG.cfg MISSING" << endl; errors = true; }
		else cout << "[ OK ] REG.cfg" << endl;

		if (errors) {
			cout << "[ WARN ] Integrity violations found. Repair? (Y/N): ";
			char c = _getch();
			cout << c << endl;
			if (toupper(c) == 'Y') startupRepair();
		}
		else {
			cout << "[ DONE ] All system files healthy." << endl;
		}
	}
	else if (ex_c == "sysinfo") {
		clearScreen();
		cout << "======================================================================================================================" << endl;
		cout << "                                                ARSLANIUS SYSTEM INFORMATION" << endl;
		cout << "======================================================================================================================" << endl;
		cout << endl;
		cout << "[USER]" << endl;
		cout << "  Current User  : " << currentUser << endl;
		cout << "  Home          : " << UnchangeableUserHome << endl;
		cout << "  Path          : " << userHome << endl;
		cout << endl;
		cout << "[SYSTEM]" << endl;
		cout << "  OS Name       : " << osName << endl;
		cout << "  Build         : " << currentBuild << endl;
		cout << "  Kernel        : BarOS " << VersionBarOSkrnl << endl;
		cout << "  Uptime        : " << getUptime() << endl;
		cout << "  Safe Mode     : " << safeMode << endl;
		cout << endl;
		cout << "[SERVICES]" << endl;
		if (fileExists(sysServices + "\\SysPulse.active")) {
			cout << "  BarOS SERVICE\\SysPulse          : ONLINE" << endl;
		}
		else {
			cout << "  BarOS SERVICE\\SysPulse          : OFFLINE" << endl;
		}
		if (fileExists(sysServices + "\\TrustedInstaller.active")) {
			cout << "  BarOS SERVICE\\TrustedInstaller  : ONLINE" << endl;
		}
		else {
			cout << "  BarOS SERVICE\\TrustedInstaller  : OFFLINE" << endl;
		}
		if (fileExists(sysServices + "\\NetMonitor.active")) {
			cout << "  BarOS SERVICE\\NetMonitor        : ONLINE" << endl;
		}
		else {
			cout << "  BarOS SERVICE\\NetMonitor        : OFFLINE" << endl;
		}
		pause();
	}
	else if (ex_c == "reboot_to_recovery") {
		recoveryRequest = "1";
		acpiRequest = 2;
		arslogon("logoutRequest");
	}
	else if (ex_c == "edit") {
		string ef, et;
		cout << "File: ";
		getline(cin, ef);
		ef = trim(ef);
		cout << "Text: ";
		getline(cin, et);
		appendFile(ef, et + "\n");
	}
	else if (ex_c == "bcdedit") {
		cout << "Enter new timeout (or Enter to skip): ";
		string input;
		getline(cin, input);
		input = trim(input);
		if (!input.empty()) bootTimeout = stoi(input);

		cout << "Enter Default Mode (ex: 1): ";
		getline(cin, input);
		input = trim(input);
		if (!input.empty()) defaultMode = stoi(input);

		cout << "Enter value DRIVER_LOAD_OFF (ex: 0): ";
		getline(cin, input);
		input = trim(input);
		if (!input.empty()) DriverloadOFF = stoi(input);

		saveBCD();
		cout << "[ DONE ] Configuration saved." << endl;
	}
	else if (ex_c == "bcdboot") {
		saveBCD();
		cout << "[ OK ] BCD created." << endl;
	}
	else if (ex_c == "regedit") {
		string ENABLELUA = to_string(enableLua);
		auto sanitize = [](string& s, string def) {
			if (s.empty()) { s = def; return; }
			for (char c : s) {
				if ((unsigned char)c < 32 && c != '\n' && c != '\r') {
					s = def;
					return;
				}
			}
			};

		sanitize(osName, "ARSLANIUS 30");
		sanitize(systemColor, "0e");
		sanitize(adminColor, "4f");
		sanitize(userColor, "1f");
		sanitize(ENABLELUA, "1");
		sanitize(adminUser, "");
		cout << "[ SECURITY ] Press enter." << endl;
		if (cin.peek() == EOF || cin.peek() == '\n') cin.ignore();
		cin.ignore(cin.rdbuf()->in_avail(), '\n');
		if (cin.peek() == '\n') cin.ignore();
		string input;
		cout << "Enter new OS Name (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) osName = t;
		}
		cout << "Enter new system color (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) systemColor = t;
		}
		cout << "Enter new admin color (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) adminColor = t;
		}
		cout << "Enter new user color (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) userColor = t;
		}
		cout << "Enter new admin user (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) adminUser = t;
		}
		cout << "Enter new value EnableLUA (or Enter to skip): ";
		input = "";
		if (getline(cin, input)) {
			string t = trim(input);
			if (!t.empty()) ENABLELUA = t;
		}
		if (osName.empty()) osName = "ARSLANIUS 30";
		if (systemColor.empty()) systemColor = "0e";
		if (adminColor.empty()) adminColor = "4f";
		if (userColor.empty()) userColor = "1f";
		if (ENABLELUA.empty()) ENABLELUA = "1";
		if (osName.length() > 50) osName = "ARSLANIUS 30";
		if (systemColor.length() > 2) systemColor = "0e";
		if (adminColor.length() > 2) adminColor = "4f";
		if (userColor.length() > 2) userColor = "1f";
		if (ENABLELUA.length() > 1) ENABLELUA = "1";
		enableLua = stoi(ENABLELUA);

		stringstream reg;
		reg << "OS_NAME=" << osName << endl;
		reg << "SYSTEM_COLOR=" << systemColor << endl;
		reg << "ADMIN_COLOR=" << adminColor << endl;
		reg << "USER_COLOR=" << userColor << endl;
		reg << "ENABLE_LUA=" << enableLua << endl;
		reg << "LOCKDOWN=0" << endl;
		reg << "ADMIN_USER=" << adminUser << endl;
		reg << "SETUP=0" << endl;
		reg << "REG_VERSION=" << REG_VERSION << endl;
		writeFile(regPath, reg.str());
		cout << "[ DONE ] Registry updated." << endl;
	}
	else if (ex_c == "taskmgr") {
		int cpu = rand() % 15 + 1;
		cout << "[ CORE ] BarOS " << VersionBarOSkrnl << " (CPU: " << cpu << "%)" << endl;
		cout << "[ UPTIME ] " << getUptime() << endl;
	}
	else if (ex_c == "events") {
		cout << readFile(logPath) << endl;
	}
	else if (ex_c == "clean") {
		system("for /d %i in (NewFolder*) do rd /s /q \"%i\" 2>nul");
		cout << "[ OK ] Cleaned." << endl;
	}
	else if (ex_c == "alt+f4") {
		cout << "ARSLANIUS is not Windows :)" << endl;
	}
	else if (ex_c == "notepad") {
		system("notepad.exe");
	}
	else if (ex_c == "calc") {
		string calcPath = programsRoot + "\\Calc.bat";
		string command = "start \"\" \"" + calcPath + "\"";
		system(command.c_str());
	}
	else if (ex_c == "ping") {
		cout << "Enter host: ";
		string host;
		getline(cin, host);
		host = trim(host);
		string cmd = "ping -n 4 " + host;
		system(cmd.c_str());
	}
	else if (ex_c == "ipconfig") {
		system("ipconfig /all");
	}
	else if (ex_c == "arp") {
		system("arp -a");
	}
	else if (ex_c == "route") {
		system("route print");
	}
	else if (ex_c == "netstat") {
		system("netstat -an");
	}
	else if (ex_c == "nslookup") {
		system("nslookup");
	}
	else {
		auto it = driverCommands.find(ex_c);
		if (it != driverCommands.end()) {
			it->second(rest);
		}
		else {
			cout << "\"" << ex_c << "\" is not recognized." << endl;
		}
	}
}

void shutdownScreen() {
	clearScreen();
	setColor("9f");
	cout << "\n\n\n\n\n\n\n\n\n                                               SHUTTING DOWN\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	cout << "                                               " << osName << endl;
	Sleep(3000);
	fs::remove(sysServices + "\\SysPulse.active");
	fs::remove(sysServices + "\\TrustedInstaller.active");
	fs::remove(sysServices + "\\NetMonitor.active");
	BarOSkrnl("ACPI");
}

void rebootScreen() {
	clearScreen();
	setColor("9f");
	cout << "\n\n\n\n\n\n\n\n\n                                               SHUTTING DOWN\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";
	cout << "                                               " << osName << endl;
	Sleep(3000);
	fs::remove(sysServices + "\\SysPulse.active");
	fs::remove(sysServices + "\\TrustedInstaller.active");
	fs::remove(sysServices + "\\NetMonitor.active");
	BarOSkrnl("ACPI");
}

// =====================================================================
// MAIN AND KERNEL
// =====================================================================

void AntiHack_BSOD() {
	bsod("6");
}

void AntiHack_CheckProcesses() {
	DWORD pids[1024], cb;
	if (!EnumProcesses(pids, sizeof(pids), &cb)) return;

	DWORD ourPid = GetCurrentProcessId();
	DWORD count = cb / sizeof(DWORD);

	for (DWORD i = 0; i < count; i++) {
		if (pids[i] == 0 || pids[i] == ourPid) continue;

		HANDLE hProc = OpenProcess(PROCESS_QUERY_INFORMATION, FALSE, pids[i]);
		if (!hProc) continue;

		char name[MAX_PATH];
		if (GetModuleFileNameExA(hProc, NULL, name, MAX_PATH)) {
			string proc = name;
			transform(proc.begin(), proc.end(), proc.begin(), ::tolower);

			if (proc.find("cheat engine") != string::npos ||
				proc.find("cheatengine") != string::npos ||
				proc.find("cheat") != string::npos ||
				proc.find("ollydbg") != string::npos ||
				proc.find("x64dbg") != string::npos) {
				writeLog("SUSPICIOUS PROCESS DETECTED: " + proc);
				AntiHack_BSOD();
				return;
			}
		}
	}
}

DWORD WINAPI AntiHack_Thread(LPVOID) {
	while (g_AntiHackRunning) {
		if (IsDebuggerPresent()) {
			AntiHack_BSOD();
		}

		PPEB64 peb = (PPEB64)__readgsqword(0x60);
		if (peb) {
			DWORD flags = *(DWORD*)((BYTE*)peb + 0x68);
			if (flags & 0x70) {
				AntiHack_BSOD();
			}
		}

		static int counter = 0;
		if (++counter >= 2) {
			counter = 0;
			AntiHack_CheckProcesses();
		}

		Sleep(500);
	}
	return 0;
}

void AntiHack_Init() {
	HANDLE hThread = CreateThread(NULL, 0, AntiHack_Thread, NULL, 0, NULL);
	if (hThread) CloseHandle(hThread);
}

void BarOSkrnl(string_view Kernel_mode) {
	if (Kernel_mode == "initPath") {
		HMODULE hMod = GetModuleHandleW(L"ntdll.dll");
		if (hMod) {
			RtlGetVersionPtr pRtlGetVersion = (RtlGetVersionPtr)GetProcAddress(hMod, "RtlGetVersion");

			if (pRtlGetVersion) {
				RTL_OSVERSIONINFOW osvi = { 0 };
				osvi.dwOSVersionInfoSize = sizeof(osvi);

				if (pRtlGetVersion(&osvi) == 0) {
					if (osvi.dwMajorVersion < 10) {
						cout << "Sorry, but ARSLANIUS requires Windows 10 or later to work :(" << endl;
						cout << endl;
						cout << "Do you want to download Windows 10?" << endl;
						cout << "Y/N: ";
						char choice = _getch();
						choice = tolower(choice);
						cout << choice << endl;

						switch (choice) {
						case 'y': {
							system("start \"\" https://www.microsoft.com/en-us/software-download/windows10"); break;
						}
						case 'n': {
							exit(0);
						}
						}
						exit(0);
					}
				}
			}
		}
		VersionBarOSkrnl = "24.1";
		char buffer[MAX_PATH];
		GetModuleFileNameA(NULL, buffer, MAX_PATH);
		string_view exePath(buffer);
		size_t lastSlash = exePath.find_last_of("\\/");
		rootPath = exePath.substr(0, lastSlash);

		configRoot = rootPath + "\\Settings And System Files";
		kernelPath = configRoot + "\\SAM";
		usersRoot = rootPath + "\\Users";
		programsRoot = rootPath + "\\Programs";
		sysProf = configRoot + "\\systemprofile";
		sysServices = sysProf;
		regPath = configRoot + "\\REG.cfg";
		logPath = configRoot + "\\system.log";
		restoreRoot = rootPath + "\\RestorePoints";
		string OldKernelPath = rootPath + "\\Settings And System Files" + "\\kernel.dll";
		if (fileExists(OldKernelPath)) fs::rename(OldKernelPath, kernelPath);

		userHome = sysProf;
		currentUser = "KERNEL";
		kernelStartTime = GetTickCount64();
		AntiHack_Init();

		if (!dirExists(configRoot)) {
			ensureDirectories();
			loader_errors("1a");
		}
		return;
	}
	if (Kernel_mode == "loading") {
		loadBCD();
		loadRegistry();
		userHome = sysProf;
		currentUser = "KERNEL";
		auto checkFileSize = [](string_view path, size_t maxSize, string_view bsodCode) -> bool {
			HANDLE hFile = CreateFileA(path.data(), GENERIC_READ, FILE_SHARE_READ,
				NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
			if (hFile != INVALID_HANDLE_VALUE) {
				LARGE_INTEGER fileSize;
				if (GetFileSizeEx(hFile, &fileSize)) {
					if (fileSize.QuadPart > static_cast<LONGLONG>(maxSize)) {
						DWORD64 size = static_cast<DWORD64>(fileSize.QuadPart);
						CloseHandle(hFile);
						ptr = new DWORD64(size);
						bsod(bsodCode.data());
						return false;
					}
				}
				CloseHandle(hFile);
			}
			return true;
			};

		if (!checkFileSize(kernelPath, MAX_KERNEL_SIZE, "10")) return;
		if (!checkFileSize(regPath, MAX_REGISTRY_SIZE, "11")) return;
		if (!checkFileSize(logPath, MAX_LOG_SIZE, "12")) return;

		if (DriverloadOFF != 1) {
			clearScreen();
			setColor("0f");
			g_api.register_command = register_driver_command;
			g_api.print = [](const char* text) { cout << text; };
			g_api.print_slow = [](const char* text) { print_slow(text); };
			g_api.read_registry = [](const char* key) -> const char* {
				static string value;
				string content = readFile(regPath);
				istringstream iss(content);
				string line;
				while (getline(iss, line)) {
					size_t eq = line.find('=');
					if (eq != string::npos) {
						string k = trim(line.substr(0, eq));
						if (k == key) {
							value = trim(line.substr(eq + 1));
							return value.c_str();
						}
					}
				}
				value = "";
				return value.c_str();
				};
			g_api.write_registry = [](const char* key, const char* value) {
				string content = readFile(regPath);
				istringstream iss(content);
				string line, newContent;
				bool found = false;
				while (getline(iss, line)) {
					size_t eq = line.find('=');
					if (eq != string::npos) {
						string k = trim(line.substr(0, eq));
						if (k == key) {
							newContent += string(key) + "=" + value + "\n";
							found = true;
						}
						else {
							newContent += line + "\n";
						}
					}
					else {
						newContent += line + "\n";
					}
				}
				if (!found) {
					newContent += string(key) + "=" + value + "\n";
				}
				writeFile(regPath, newContent);
				};
			g_api.write_log = [](const char* message) { writeLog(message); };
			g_api.file_exists = [](const char* path) -> bool { return fileExists(path); };
			g_api.read_file = [](const char* path) -> const char* {
				static string content;
				content = readFile(path);
				return content.c_str();
				};
			g_api.write_file = [](const char* path, const char* content) {
				writeFile(path, content);
				};
			g_api.get_current_user = []() -> const char* {
				static string user;
				user = currentUser;
				return user.c_str();
				};
			g_api.clear_screen = []() { clearScreen(); };
			g_api.set_color = [](const char* color) { setColor(color); };
			g_api.pause = []() { pause(); };
			g_api.delete_registry = [](const char* key) {
				string content = readFile(regPath);
				istringstream iss(content);
				string line, newContent;
				while (getline(iss, line)) {
					size_t eq = line.find('=');
					if (eq != string::npos && trim(line.substr(0, eq)) == key) continue;
					newContent += line + "\n";
				}
				writeFile(regPath, newContent);
				};
			g_api.dir_exists = [](const char* path) -> bool { return dirExists(path); };
			g_api.append_file = [](const char* path, const char* content) { appendFile(path, content); };
			g_api.delete_file = [](const char* path) -> bool { return DeleteFileA(path); };
			g_api.create_directory = [](const char* path) -> bool { return CreateDirectoryA(path, NULL); };
			g_api.unregister_command = [](const char* name) {
				string cmd_name = name;
				transform(cmd_name.begin(), cmd_name.end(), cmd_name.begin(), ::tolower);
				driverCommands.erase(cmd_name);
				};
			g_api.execute_command = [](const char* cmd) { core(string(cmd)); };
			g_api.get_os_name = []() -> const char* { return osName.c_str(); };
			g_api.get_build = []() -> const char* { return currentBuild.c_str(); };
			g_api.get_safe_mode = []() -> int { return safeMode; };
			g_api.shell_execute = [](const char* cmd) -> int { return system(cmd); };
			g_api.get_root_path = []() -> const char* { return rootPath.c_str(); };
			g_api.get_config_path = []() -> const char* { return configRoot.c_str(); };
			g_api.get_users_path = []() -> const char* { return usersRoot.c_str(); };
			g_api.get_drivers_path = []() -> const char* {
				static string dp = configRoot + "\\ServiceDriverRoot";
				return dp.c_str();
				};
			g_api.get_driver_home = [](const char* driver_name) -> const char* {
				static string home;
				home = configRoot + "\\ServiceDriverRoot\\" + driver_name;
				if (!dirExists(home)) {
					fs::create_directories(home);
					fs::create_directories(home + "\\logs");
				}
				return home.c_str();
				};
			g_api.calculate_hash = [](const char* input) -> const char* {
				static string hash;
				hash = calculateHash(input);
				return hash.c_str();
				};
			g_api.user_exists = [](const char* username) -> bool {
				string k = readFile(kernelPath);
				string u = username;
				return k.find(u + " =") != string::npos || k.find(u + "=") != string::npos;
				};
			string driversRoot = configRoot + "\\Drivers";
			if (!dirExists(driversRoot)) {
				fs::create_directories(driversRoot);
				return;
			}

			driverCommands.clear();
			HMODULE hMods[1024];
			DWORD cbNeeded;
			if (EnumProcessModules(GetCurrentProcess(), hMods, sizeof(hMods), &cbNeeded)) {
				for (unsigned int i = 0; i < (cbNeeded / sizeof(HMODULE)); i++) {
					char modName[MAX_PATH];
					if (GetModuleFileNameA(hMods[i], modName, sizeof(modName))) {
						string_view name(modName);
						if (name.find(".asd") != string_view::npos) {
							FreeLibrary(hMods[i]);
						}
					}
				}
			}

			WIN32_FIND_DATAA fd;
			string searchPath = driversRoot + "\\*.asd";
			HANDLE hFind = FindFirstFileA(searchPath.c_str(), &fd);

			if (hFind == INVALID_HANDLE_VALUE) {
				return;
			}

			cout << endl << "[ BOOT MANAGER ] Loading drivers..." << endl;

			int loaded = 0, failed = 0;

			do {
				if (!(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) {
					string driverPath = driversRoot + "\\" + fd.cFileName;

					HMODULE hMod = LoadLibraryA(driverPath.c_str());
					if (!hMod) {
						DWORD err = GetLastError();
						cout << "[ DRIVER ] " << fd.cFileName << " - FAILED (LoadLibrary error: " << err << ")" << endl;
						failed++;
						continue;
					}

					DriverInitFunc init = (DriverInitFunc)GetProcAddress(hMod, "asd_init");
					if (!init) {
						DWORD err = GetLastError();
						cout << "[ DRIVER ] " << fd.cFileName << " - FAILED (No asd_init, error: " << err << ")" << endl;
						FreeLibrary(hMod);
						failed++;
						continue;
					}

					cout << "[ DRIVER ] " << fd.cFileName << "..." << endl;
					int res = 0;
					try {
						int result = init(&g_api);

						if (result == BAROS_SUCCESS) {
							loaded++;
						}
						else if (result == BAROS_CRITICAL) {
							cout << "FAILED (BAROSSTATUS: CRITICAL)" << endl;
							FreeLibrary(hMod);
							failed++;
							pause();
							loader_errors("15");
						}
						else {
							cout << "FAILED (Init returned: " << result << ")" << endl;
							FreeLibrary(hMod);
							failed++;
						}
						res = result;
					}
					catch (...) {
						cout << "[ CRTICAL ERROR ] FAILED (Init returned: " << res << ")" << endl;
						FreeLibrary(hMod);
					}
				}
			} while (FindNextFileA(hFind, &fd));

			FindClose(hFind);

			cout << "[ BOOT MANAGER ] Drivers: " << loaded
				<< " loaded, " << failed << " failed" << endl;
			pause();
		}
		return;
	}
	if (Kernel_mode == "ACPI") {
		if (acpiRequest == 1) {
			if (fastBoot == 1) BarOSkrnl("hibernate");
			exit(0);
		}
		if (acpiRequest == 2) { BarOSkrnl("initPath"); bootMenu(); }
		setColor("0f");
		clearScreen();
		cout << "ERROR: CRITICAL ACPI ERROR" << endl;
		pause();
		bsod("16");
	}
	if (Kernel_mode == "hibernate") {
		string hiberPath = configRoot + "\\hibernate.sys";
		if (fileExists(hiberPath)) fs::remove(hiberPath);
		stringstream ss;
		ss << "USER=" << currentUser << endl;
		ss << "USER_HOME=" << userHome << endl;
		ss << "SAFE_MODE=" << safeMode << endl;
		ss << "REC=" << rec << endl;
		ss << "DIAG=" << diagnostic << endl;
		ss << "DATE=" << getCurrentDateTime() << endl;
		writeFile(hiberPath, ss.str());
		exit(0);
	}
	if (Kernel_mode == "resume") {
		if (fileExists(configRoot + "\\hibernate.sys")) {
			string hiberPath = configRoot + "\\hibernate.sys";

			ifstream hiber(hiberPath);
			string line;
			while (getline(hiber, line)) {
				size_t sep = line.find('=');
				if (sep == string::npos) continue;
				string key = line.substr(0, sep);
				string value = line.substr(sep + 1);

				if (value.empty()) continue;

				try {
					if (key == "USER") currentUser = value;
					else if (key == "USER_HOME") userHome = value;
					else if (key == "SAFE_MODE") safeMode = stoi(value);
					else if (key == "REC") rec = stoi(value);
					else if (key == "DIAG") diagnostic = stoi(value);
				}
				catch (...) {
					continue;
				}
			}
		}
		for (int i = 1; i <= 12; i++) {
			clearScreen();
			setColor("0f");
			cout << "======================================================================================================================" << endl;
			cout << "                                                 ARSLANIUS BOOT MANAGER" << endl;
			cout << "======================================================================================================================" << endl;
			cout << "                                                  Resuming " << osName << "..." << endl;
			cout << endl;
			cout << "         Build: " << currentBuild << endl;
			cout << "         Kernel: BarOS " << VersionBarOSkrnl << endl;
			cout << "         © Armsoup 2026" << endl;
			cout << endl;
			cout << "                                                     _____________" << endl;

			switch (i) {
			case 12: cout << "                                                    |..           |" << endl; break;
			case 11: cout << "                                                    |...          |" << endl; break;
			case 10: cout << "                                                    | ...         |" << endl; break;
			case 9: cout << "                                                    |  ...        |" << endl; break;
			case 8: cout << "                                                    |   ...       |" << endl; break;
			case 7: cout << "                                                    |    ...      |" << endl; break;
			case 6: cout << "                                                    |     ...     |" << endl; break;
			case 5: cout << "                                                    |      ...    |" << endl; break;
			case 4: cout << "                                                    |       ...   |" << endl; break;
			case 3: cout << "                                                    |        ...  |" << endl; break;
			case 2: cout << "                                                    |         ... |" << endl; break;
			case 1: cout << "                                                    |          ...|" << endl; break;
			}
			cout << "                                                     -------------" << endl;
			Sleep(230);
		}
		if (currentUser == "BarOS SERVICE\\TrustedInstaller" ||
			currentUser == "BarOS SERVICE\\SysPulse" ||
			currentUser == "BarOS SERVICE\\NetMonitor") {
			fs::remove(configRoot + "\\hibernate.sys");
			interfaceScreen();
		}
		if (currentUser == "BarOS AUTHORITY\\SYSTEM") currentUser = "SYSTEM";
		clearScreen();
		setColor("5b");
		cout << "Enter password for " << currentUser << ": ";
		// Hide password input
		char ch;
		p_in = "";
		while ((ch = _getch()) != '\r') {
			if (ch == '\b') {
				if (!p_in.empty()) {
					p_in.pop_back();
					cout << "\b \b";
				}
			}
			else {
				p_in += ch;
				cout << '*';
			}
		}
		cout << endl;
		requestFromResume = 1;
		arslogon("authorization");
	}
	if (Kernel_mode == "EARLY_LAUNCH_CONSOLE") {
		interfaceScreen();
		return;
	}
	if (Kernel_mode == "reload") {
		string oldUser = currentUser;
		string oldPath = userHome;
		BarOSkrnl("loading");
		userHome = oldPath;
		currentUser = oldUser;
		applyColor();
		interfaceScreen();
		return;
	}
	loader_errors("16");
}

int main(int argc, char* argv[]) {
	srand(static_cast<unsigned int>(time(0)));

	SetConsoleTitleA("ARSLANIUS 30 Alpha 1");

	SetConsoleWidthOnly(120);

	SetConsoleOutputCP(65001);

	BarOSkrnl("initPath");
	for (int i = 1; i < argc; ++i) {
		string arg = argv[i];

		if (arg == "-earlyconsole") {
			BarOSkrnl("EARLY_LAUNCH_CONSOLE");
		}
	}

	bootMenu();

	return 0;
};