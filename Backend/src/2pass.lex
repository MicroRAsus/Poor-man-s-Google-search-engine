%{
#include <string>
#include <dirent.h>
#include <vector>
#include <algorithm>
#include <assert.h> 
#include <cstring>
#include <cmath>
#include <iostream>
#include <fstream>
#include <iomanip>
#include "./include/hashtable.h"
#include "./include/BufferNode.hpp"

using namespace std;

const int localHTSize = 8669; //calculated from top most uniq token document
const int totalUniqTokenSize = 63709;
const int top10DocTokenSize = 9000;
HashTable *localHT = NULL;
HashTable globalHT(totalUniqTokenSize);
int currentDoc = 0; //doc id
const int stopListSize = 18;
//we can implement stop list with regex rule for higher efficiency
string stoplist[stopListSize] = {"the", "and", "of", "to", "in", "for", "is", "on", "be", "this", "are", "will", "by", "that", "you", "with", "as", "or"};
char toLower(char text);
void toLowerArray(char* text, int leng);
string buildTempFileName(int currentIndex, int mergeNumber);
bool fileOpenStatusCheck(FILE *file, string ifFailMSG);
void printPass1TempFile(vector<StringIntPair> &records, int mergeNumber);
bool inStopList(char* text);
void readToBuffer(vector<ifstream *> tempFileHandles, vector<BufferNode> &buffer, const int startIndex, StringIntPair* globalRecord, int &currentPostIndex, ofstream &postingFile);
int alphabetFirstTokenIndex(vector<BufferNode> &buffer);
%}
DIGIT [0-9]
LETTER [A-Za-z]
ALPHANO [A-Za-z0-9]
UPPERCASE [A-Z]
LOWERCASE [a-z]
CAPWORD [A-Z0-9][A-Z0-9]*
COMBINEDWORD {LETTER}+(\-{LETTER}+)+
ABBRWORD {LETTER}+\.({LETTER}+\.)+
WORD {LETTER}{LOWERCASE}*
INDENTATION [ \n\t]
NEXTLINE [\n]
VERSIONNO {DIGIT}+\.{DIGIT}+(\.{DIGIT}+)+
PHONENUMBER {DIGIT}{3}-{DIGIT}{3}-{DIGIT}{4}
FLOATNUMBER {DIGIT}*\.{DIGIT}+
NUMBER {DIGIT}+(,{DIGIT}+)*
EMAIL [A-Za-z0-9_\-\.]+@([A-Za-z0-9_\-]+\.)+[A-Za-z0-9_\-]{2,4}
URL (http:\/\/www\.|https:\/\/www\.|http:\/\/WWW\.|https:\/\/WWW\.|http:\/\/|https:\/\/)?{ALPHANO}+([\-\.]{1}{ALPHANO}+)*\.{ALPHANO}{2,5}(:[0-9]{1,5})?(\/{ALPHANO}*)*
FORWARDSLASH [\/]
PROPERTY {INDENTATION}+(([A-Za-z\-_]+)?{INDENTATION}*=?{INDENTATION}*((\"[^\"]*\")|({ALPHANO}+)|({URL})){INDENTATION}*)+{INDENTATION}*
STARTTAG <!?{ALPHANO}+{PROPERTY}*{FORWARDSLASH}?>
ENDTAG <{FORWARDSLASH}{ALPHANO}+>
%%
{EMAIL}	{localHT->Insert(string(yytext), currentDoc, 1, false);} //insert matched token into localHT
{URL}	{localHT->Insert(string(yytext), currentDoc, 1, false);}
{PHONENUMBER}	{localHT->Insert(string(yytext), currentDoc, 1, false);}
{FLOATNUMBER}	{localHT->Insert(string(yytext), currentDoc, 1, false);}
{NUMBER}	{
				if(yyleng > 1) {
					localHT->Insert(string(yytext), currentDoc, 1, false);
				}
			}
{VERSIONNO}	{localHT->Insert(string(yytext), currentDoc, 1, false);}
{STARTTAG}	; //consume tags
{ENDTAG}	; //consume tags
{CAPWORD}	{	
				if(yyleng > 1){
					toLowerArray(yytext, yyleng);
					if(!inStopList(yytext)) {
						localHT->Insert(string(yytext), currentDoc, 1, false);
					}
				}
			}
{ABBRWORD} 	{ //abbreviated words
				toLowerArray(yytext, yyleng);
				localHT->Insert(string(yytext), currentDoc, 1, false);
			}
{COMBINEDWORD} 	{
					char *word = strtok(yytext, "-");
					while(word != NULL){
						if (strlen(word) > 1) {
							toLowerArray(word, strlen(word));
							if(!inStopList(word)) {
								localHT->Insert(string(word), currentDoc, 1, false);
							}
						}
						word = strtok(NULL, "-");
					}
				}
{WORD}	{
			if (yyleng > 1) {
				if(yytext[0] <= 'Z' && yytext[0] >= 'A') {
					yytext[0] = toLower(yytext[0]);
				}
				if(!inStopList(yytext)) {
					localHT->Insert(string(yytext), currentDoc, 1, false);
				}
			}
		}
[\n\t ]	;
.	;
%%
int main(int argc, char **argv) {
	if (argc < 3) { //check if argument is valid
		perror ("Invalid argument.\n");
		return 1;
	}
	int mergeNumber = atoi(argv[2]);
	if(mergeNumber > 10 || mergeNumber < 1) {
		perror ("Only 1 to 10 files can be merged at a time.\n");
		return 1;
	}
	
	DIR* dir;
	struct dirent *dirEntry;
	
	if((dir = opendir(argv[1])) != NULL) { //pass1
		string fileDirectory(argv[1]);
		ofstream mapfile("./MappingFile.out");
		if(!mapfile) { //file open check
			perror ("Failed to create MappingFile.\n");
			return 1;
		}
		
		vector<StringIntPair> records;
		records.reserve(top10DocTokenSize);
		while((dirEntry = readdir(dir)) != NULL) { //loop over each files in directory
			if((strcmp(dirEntry->d_name,".") != 0) && (strcmp(dirEntry->d_name,"..") != 0) && (strstr(dirEntry->d_name,".html") != NULL)) {
				string fileName(dirEntry->d_name);
				FILE *inFile = fopen((fileDirectory + "/" + fileName).c_str(),"r");
				assert(fileOpenStatusCheck(inFile, "Failed to open input file. Make sure input file folder is in current directory.\n") == true); //file open check

				mapfile << setw(4) << to_string(currentDoc) << " " << setw(11) << fileName << endl; //write mapping file
				localHT = new HashTable(localHTSize); //create a new local hash table
                yyrestart(inFile); //set yyin to new input file and reset the lexer engine
				yylex(); //start scanning
				
				int recordFirstIndex = records.size();
				int totalUniqTokens = localHT->getNonEmptyEntries(records, globalHT); //insert non empty entries into vector and global ht
				for(unsigned long i = recordFirstIndex; i < records.size(); i++) { //calculate rtf for each uniq tokens in a doc
					records.at(i).data3 = (double) records.at(i).data2 / totalUniqTokens;
				}
				fclose(inFile); //close input file handle
				delete localHT; //delete ht for current input file
				
				currentDoc++;
				if(currentDoc % mergeNumber == 0) { //if match merge number, write temp file
					printPass1TempFile(records, mergeNumber);
				}
			}
		}
		int remainder = currentDoc % mergeNumber;
		if(remainder != 0) { //file number is not fully divisible by the merge number, some records are not printed out to temp file
			printPass1TempFile(records, remainder); // print remainder temp file
		}
		mapfile.close();
		closedir(dir);
    } else {
		perror ("Could not open directory.\n");
		return 1;
    }
	
	const int maxTempFileNumber = 1019; //pass2
	if((dir = opendir("./temp")) != NULL) { 
		vector<ifstream *> tempFileHandles;
		vector<BufferNode> buffer;
		tempFileHandles.reserve(maxTempFileNumber);
		buffer.reserve(maxTempFileNumber);
		while((dirEntry = readdir(dir)) != NULL) { //loop over each files in directory, add all file handles to vector
			if((strcmp(dirEntry->d_name,".") != 0) && (strcmp(dirEntry->d_name,"..") != 0) && (strstr(dirEntry->d_name,".out") != NULL)) {
				ifstream *inFile = new ifstream(("./temp/" + string(dirEntry->d_name)).c_str());
				tempFileHandles.push_back(inFile);
			}
		}
					
		for(int i = 0; i < tempFileHandles.size(); i++) { //read first line into buffer
			StringIntPair record;
			*(tempFileHandles.at(i)) >> record.key >> record.data1 >> record.data2 >> record.data3; //key, doc id, freq, rtf
			buffer.push_back(BufferNode(record, i));
		}
					
		int currentPostIndex = 0; //producing posting file
		ofstream postingFile("./posting.out");
		while(!buffer.empty()) {//buffer not empty
			int lowestIndex = alphabetFirstTokenIndex(buffer);
			StringIntPair* globalRecord = globalHT.GetData(buffer.at(lowestIndex).record.key);
			if(globalRecord != NULL) {
				globalRecord->data2 = currentPostIndex; //start position
				globalRecord->data3 = log10((double)currentDoc / globalRecord->data1); //calculate idf for this token
				readToBuffer(tempFileHandles, buffer, lowestIndex, globalRecord, currentPostIndex, postingFile);
			}
		}
		
		postingFile.close();
		for(int i = 0; i < tempFileHandles.size(); i++) {
			(*(tempFileHandles.at(i))).close();
		}
		tempFileHandles.clear();
		globalHT.Print("./DictFile.out", true); //print out final dict file.
	} else {
		perror ("Could not open temp file directory.\n");
		return 1;
	}
	return 0;
}

void readToBuffer(vector<ifstream *> tempFileHandles, vector<BufferNode> &buffer, const int startIndex, StringIntPair* globalRecord, int &currentPostIndex, ofstream &postingFile) {
	for(int i = startIndex; i < buffer.size(); i++) { //loop from first occurance of alphabetically first token
		StringIntPair &record = buffer.at(i).record;
		if(record.key == globalRecord->key){
			postingFile << setw(4) << record.data1 << " " << setw(3) << record.data2 << " " << setw(8) << to_string(record.data3 * globalRecord->data3).substr(0, 8) << endl; // write posting
			currentPostIndex++;
			bool readSuccess = (*(tempFileHandles.at(buffer.at(i).bufferIndex))) >> record.key >> record.data1 >> record.data2 >> record.data3;
			while(readSuccess && record.key == globalRecord->key) { //if next token in the buffer is the same, keep reading.
				postingFile << setw(4) << record.data1 << " " << setw(3) << record.data2 << " " << setw(8) << to_string(record.data3 * globalRecord->data3).substr(0, 8) << endl; // write posting
				currentPostIndex++;
				readSuccess = (*(tempFileHandles.at(buffer.at(i).bufferIndex))) >> record.key >> record.data1 >> record.data2 >> record.data3;
			}
			if(!readSuccess) {//end of file, delete this buffer
				buffer.erase(buffer.begin() + i);
				i--; //compensate the deleted buffer
			}
		}
	}
}

int alphabetFirstTokenIndex(vector<BufferNode> &buffer) { //not efficient, we could use a min binary tree design to save much time O(lgN)
	int lowestIndex = 0;
	for(int i = 1; i < buffer.size(); i++) { //ahh... this is so slow! but I don't have time to implement min tree. avg case: O(n)
		if(buffer.at(i).record.key < buffer.at(lowestIndex).record.key) {
			lowestIndex = i;
		}
	}
	return lowestIndex;
}

string buildTempFileName(int currentIndex, int mergeNumber) {
	string s = to_string(currentIndex - 1);
	for(int i = currentIndex - 2; i >= currentIndex - mergeNumber; i--) {
		s = to_string(i) + "_" + s;
	}
	return s;
}

void printPass1TempFile(vector<StringIntPair> &records, int mergeNumber) {
	sort(records.begin(), records.end()); //sort tokens
	FILE *pass1TempFile = fopen(("./temp/" + buildTempFileName(currentDoc, mergeNumber) + ".out").c_str(), "w");
	assert(fileOpenStatusCheck(pass1TempFile, "Failed to write temp file. Make sure temp folder is in current directory.\n") == true); //file open check
	for(int i = 0; i < records.size(); i++) { //write all sorted records to temp file
		StringIntPair record = records.at(i);
		fputs((record.key + " " + to_string(record.data1) + " " + to_string(record.data2) + " " + to_string(record.data3) + "\n").c_str(), pass1TempFile);
	}
	fclose(pass1TempFile);
	records.clear(); //delete all elements
}

bool fileOpenStatusCheck(FILE *file, string ifFailMSG) {
	if(file == NULL) {
		perror(ifFailMSG.c_str());
		return false;
	}
	return true;
}

char toLower(char text) {
	return text - 'A' + 'a';
}

void toLowerArray(char* text, int leng) {
	for(int i = 0; i < leng; i++) {
		if(text[i] <= 'Z' && text[i] >= 'A')
			text[i] = toLower(text[i]);
	}
}

bool inStopList(char* text) {
	string txt(text);
	for(int i = 0; i < stopListSize; i++) {
		if(txt == stoplist[i]) {
			return true;
		}
	}
	return false;
}
