/* Filename:  hashtable.h
 * Author:    Susan Gauch
 * Date:      2/25/10
 * Purpose:   The header file for a hash table of strings and ints. 
 */
#include "StringIntPair.hpp"
using namespace std;

class HashTable {
    public:
    HashTable(const HashTable & ht); // constructor for a copy
    HashTable(const unsigned long NumKeys); // constructor of hashtable 
	HashTable(const string filename);
    ~HashTable(); // destructor
    void Print(const char * filename, bool truncated) const;
    void Insert(const string Key, const int Data1, const int Data2, bool global);
    StringIntPair* GetData(const string Key);
    void GetUsage(int & Used, int & Collisions, int & Lookups) const;
    int getNonEmptyEntries(vector<StringIntPair> &records, HashTable &global) const;
    void Insert(const string Key);
    void getNonEmptyEntries(vector<StringIntPair> &records) const;
	
	protected:
    unsigned long Find(const string Key, const bool truncated = false); // the index of the ddr in the hashtable
    
	private:
    StringIntPair * hashtable; // the hashtable array itself
    unsigned long size; // the hashtable size
    unsigned long used;
    unsigned long collisions;
    unsigned long lookups;
};
