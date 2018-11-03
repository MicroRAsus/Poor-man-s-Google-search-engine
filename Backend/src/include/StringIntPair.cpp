#include "StringIntPair.hpp"

using namespace std;

StringIntPair::StringIntPair()
{
	key = "";
	data1 = -1;
	data2 = -1;
	data3 = 0.0;
}
	
StringIntPair::StringIntPair(const StringIntPair &pair) //copy constructor for deep copying records
{
	key = pair.key;
	data1 = pair.data1;
	data2 = pair.data2;
	data3 = pair.data3;
}

StringIntPair::StringIntPair(const string Key, const int Data1, const int Data2, const double Data3) //copy constructor
{
	key = Key;
	data1 = Data1;
	data2 = Data2;
	data3 = Data3;
}

bool StringIntPair::operator < (const StringIntPair &node) const //for sorting
{
	return (key < node.key);
}
