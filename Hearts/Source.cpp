#include <iostream>
#include <windows.h>
using namespace std;
extern "C" void _main();
int main() {
	_main();
	HANDLE handle = GetStdHandle(-11);
	PCONSOLE_SCREEN_BUFFER_INFO test = new CONSOLE_SCREEN_BUFFER_INFO;
	GetConsoleScreenBufferInfo(handle, test);
	SetConsoleTextAttribute(handle, 4);
	GetConsoleScreenBufferInfo(handle, test);

	std::cout << test;
}


/*
void play() {
	int currentPlayer = 0; // set to player with 2C
	for (int i = 0;i < 1;i++) {
		trick();
	}
}

void trick() {
	for (int i = 0;i < 4;i++) {
		if (currentPlayer == 0) {
			humanPlay();
		}
		else {
			botPlay(currentPlayer);
		}
		currentPlayer++;
		if (currentPlayer==4) {
			currentPlayer = 0;
		}
	}
	
}

void botPlay(currentPlayer) {

}

void humanPlay() {
	SetConsoleTextAttribute for valid cards;
	read console input

}

bool removeCard(card_name,player) {
	SCASB card in player list
		if not found return 0
			check length
			for (int i = scasb index+1;i < length;i++) {
				mov tmp,array[i]
				mov array[i-1],tmp
	}return 1
}
*/
extern "C" void printCard(char card) {
	string name = "";
	switch (card & 0x30) {
	case 0x0:
		name += 'C';
		break;
	case 0x10:
		name += 'D';
		break;
case 0x20:
	name += 'S';
	break;
	case 0x30:
		name += 'H';
		break;
	}
	cout << name;
}