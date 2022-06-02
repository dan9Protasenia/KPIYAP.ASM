#define ARRAY_LENGTH 5

#include <iostream>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

using namespace std;

double getnum()
{
	double num = 0;
	while (1)
	{
		cin >> num;
		cin.ignore(32767, '\n');
		if (cin.fail())
		{
			cin.clear();
			cin.ignore(32767, '\n');
			cout << "Incorrect value... Try again!" << endl;
		}
		else return num;
	}
}

int main()
{
	double ar[ARRAY_LENGTH], result[ARRAY_LENGTH];
	cout << "Enter " << ARRAY_LENGTH << " numbers: " << endl;
	for (int i = 0; i < ARRAY_LENGTH; i++)
	{
		ar[i] = getnum();
	}
	for (int i = 0; i < ARRAY_LENGTH; i++)
	{
		if (ar[i] > 0)
			result[i] = ar[i] * ar[i] * ar[i];
		else
			result[i] = ar[i] * ar[i];
	}
	cout << "C: ";
	for (int i = 0; i < ARRAY_LENGTH; i++)
	{
		cout << result[i] << "  ";
		result[i] = 0;
	}
	cout << endl;
	_asm
	{
		finit
		xor esi, esi
		mov ebx, ARRAY_LENGTH

		array_loop :
		fld ar[esi]
			fldz
			fcompp
			fstsw ax
			and ah, 00000001b //8,10,14 - c0, c2, c3, > - 001
			jnz positive

			negative :
		fld ar[esi]
			fmul ar[esi]
			jmp array_loop_end

			positive :
		fld ar[esi]
			fmul ar[esi]
			fmul ar[esi]

			array_loop_end :
			fstp result[esi]

			add esi, 8
			dec ebx
			cmp ebx, 0
			jne array_loop
			fwait
	}
	cout << "FPU: ";
	for (int i = 0; i < ARRAY_LENGTH; i++)
	{
		cout << result[i] << "  ";
	}
	cout << endl;
	system("pause");
}