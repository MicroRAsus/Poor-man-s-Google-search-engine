/* Filename:  hashtable.cpp
 * Author:    Susan Gauch
string  * Date:      2/11/2010
 * Purpose:   The implementation file for a hash table of words and numbers.
*/

#include <assert.h> 
#include <iostream> 
#include <fstream>
#include <vector>


#include "hashtable.h"

using namespace std;
/*-------------------------- Constructors/Destructors ----------------------*/

/* : HashTable
 * Author: seg
 * Parameters:  ht: the hashtable to copy
 * Purpose:     copy a hashtable 
 *              NOTE:  this is crucial to include since it is invoked
 *              by call-by-value parameter passing
 * Returns:     nothing
 */
HashTable::HashTable(const HashTable & ht) {
    size = ht.size; // set the size of the array
    if ((hashtable = new StringIntPair[size]()) == NULL)
        cout << "Out of memory at HashTable::HashTable(const HashTable)" << endl;
    assert(hashtable != 0);

    for (unsigned long i = 0; i < size; i++) // make a _copy_ of the array elements
    {
        hashtable[i].key = ht.hashtable[i].key;
        hashtable[i].data1 = ht.hashtable[i].data1;
        hashtable[i].data2 = ht.hashtable[i].data2;
	}
}

/* Name:  HashTable
 * Author: seg
 * Parameters:  none
 * Purpose:     allocate a hashtable for an expected number of keys
 *              initializes all values to null (0)
 * Returns:     pointer to the created HashTable or 0 if out of memory
 */
HashTable::HashTable(const unsigned long NumKeys) {
    // allocate space for the table, init to null key
    size = NumKeys * 3; // we want the hash table to be 2/3 empty
    used = 0;
    collisions = 0;
    lookups = 0;
    if ((hashtable = new StringIntPair[size]()) == NULL) //create hash table array
        cout << "Out of memory at HashTable::HashTable(unsigned long)" << endl;
    assert(hashtable != 0);

    // initialize the hashtable
    // for (unsigned long i=0; i < size; i++)
    // {
    // hashtable[i].key = "";
    // hashtable[i].data1 = -1;
    // hashtable[i].data2 = -1;
    // }
}

HashTable::HashTable(const string filename) { //initialize with a file
    //allocate space for the table, init to null key
	ifstream fin(filename.c_str());
	
    fin >> size;
    used = 0;
    collisions = 0;
    lookups = 0;
    if ((hashtable = new StringIntPair[size]()) == NULL) //create hash table array
        cout << "Out of memory at HashTable::HashTable(unsigned long)" << endl;
    assert(hashtable != 0);

    //initialize the hashtable
    for (unsigned long i=0; i < size; i++)
    {
		fin >> hashtable[i].key >> hashtable[i].data1 >> hashtable[i].data2;
		if(hashtable[i].key == "!null!") { //if it's empty record
			hashtable[i].key = "";
			hashtable[i].data1 = -1;
			hashtable[i].data2 = -1;
		}
    }
	fin.close();
}

/* Name:  ~HashTable
 * Author: seg
 * Parameters:  none
 * Purpose:     deallocate a hash table
 * Returns:     nothing
 */
HashTable::~HashTable() {
    delete[] hashtable;
}

/*-------------------------- Accessors ------------------------------------*/

/* Name:  Print
 * Author: seg
 * Parameters:  none
 * Purpose:     print the contents of the hash table
 *              currently, only prints non-null entries
 * Returns:     nothing
 */
void HashTable::Print(const char * filename) const {
    ofstream fpout(filename);
	
	fpout << size << "\n";
    for (unsigned long i = 0; i < size; i++) {
        if (!(hashtable[i].key == "")) //empty record was initialized as empty string
            fpout << hashtable[i].key << " " <<
            hashtable[i].data1 << " " << hashtable[i].data2 << "\n";
        else //keep the empty record
            fpout << "!null! " << hashtable[i].data1 << " " << hashtable[i].data2 << "\n";
    }
    fpout.close();
    cout << "Collisions: " << collisions << ", Used: " << used <<
        ", Lookups: " << lookups << "\n";
}

void HashTable::getNonEmptyEntries(vector<StringIntPair> &records, HashTable &global) const { //push non empty record to vector
	for (unsigned long i = 0; i < size; i++) {
        if (hashtable[i].key != "") {
			records.push_back(StringIntPair(hashtable[i]));
			global.Insert(hashtable[i].key, 1, -1, true);
		}
    }
}

/* Name: Insert
 * Author: sgauch
 * Parameter:
 * 		key : The target of context words to be stored
 * 		frequency: Total frequency count
 * Purpose: 	insert or add a word with its frequency count in hashtable
 * Return:	nothing
 */
void HashTable::Insert(const string Key, const int Data1, const int Data2, bool global) {
    unsigned long Index;

    if (used >= size)
        cerr << "The hashtable is full; cannot insert.\n";
    else {
        Index = Find(Key);
		
		// If not already in the table, insert it
		if (hashtable[Index].key == "") {
			hashtable[Index].key = Key;
			hashtable[Index].data1 = Data1;
			hashtable[Index].data2 = Data2;
			used++;
		} else { // else it's already in the table
			if(global) {
				hashtable[Index].data1++; //numdocs++
			} else {
				hashtable[Index].data2++; //freq++
			}
		}
    }
}

/* Name: GetData
 * Author: sgauch
 * Parameters:	key: the string
 * Purpose:	return the record if Key is found.
 * Return:	return a stringIntPair pointer
 */
StringIntPair* HashTable::GetData(const string Key) {
    unsigned long Index;

    lookups++;
    Index = Find(Key);
    if (hashtable[Index].key == "")
        return NULL;
    else
        return hashtable+Index;
}

/* Name: GetUsage
 * Author: S. Gauch
 * Parameters:	None
 * Purpose:	return the number of collisions
 * Return:	return a char *
 */
void HashTable::GetUsage(int & Used, int & Collisions, int & Lookups) const {
    Used = used;
    Collisions = collisions;
    Lookups = lookups;
}

/*-------------------------- Private Functions ----------------------------*/
/* Name:  Find
 * Author: seg
 * Parameters:  key: the word to be located
 * Purpose:     return the index of the word in the table, or
 *              the index of the free space in which to store the word
 * Returns:     index of the word's actual or desired location
 */
unsigned long HashTable::Find(const string Key) {
    unsigned long Sum = 0;
    unsigned long Index;

    // add all the characters of the key together
    for (int i = 0; i < Key.length(); i++)
        Sum = (Sum * 29) + Key[i]; // Mult sum by 19, add byte value of char

    Index = Sum % size;

    // Check to see if word is in that location
    // If not there, do linear probing until word found
    // or empty location found.
    while (((hashtable[Index].key) != Key) &&
        ((hashtable[Index].key) != "")) {
        Index = (Index + 1) % size;
        collisions++;
    }

    return Index;
}