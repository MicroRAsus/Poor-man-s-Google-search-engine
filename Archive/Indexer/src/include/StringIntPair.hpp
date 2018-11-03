#include <string>
#pragma once
using namespace std;

struct StringIntPair // the datatype stored in the hashtable
{
	string key;
    int data1;
    int data2;

    StringIntPair();
    StringIntPair(const StringIntPair &pair); //copy constructor for deep copying records
	StringIntPair(const string Key, const int Data1, const int Data2);
    bool operator < (const StringIntPair &node) const; //for sorting
};
