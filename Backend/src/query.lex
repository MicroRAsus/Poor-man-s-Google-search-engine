%{
#include <vector>
#include <string>
#include <algorithm>
#include <iostream>
#include <fstream>
#include <iomanip>
#include "./include/AccumulatorNode.hpp"
#include "./include/hashtable.h"

using namespace std;

const int localHTSize = 50; //query tokens ht size
HashTable localHT(localHTSize); //store query tokens. key field stores query token, data1 stores freq of the query token
const int postingRecSize = 18; //# of char in a posting record
const int DictRecSize = 32; //# of char in a dict file record
const int mapRecSize = 17; //# of char in a map file record
const int numOfResult = 10; //toggle how many top result are shown
const int stopListSize = 18;
//we can implement stop list with regex rule for higher efficiency
string stoplist[stopListSize] = {"the", "and", "of", "to", "in", "for", "is", "on", "be", "this", "are", "will", "by", "that", "you", "with", "as", "or"};
char toLower(char text);
void toLowerArray(char* text, int leng);
bool inStopList(char* text);
int find(const string Key, ifstream &dictFile, const int size, int &numDoc); //find query token position in the dict file.
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
{EMAIL}	{localHT.Insert(string(yytext));} //insert matched token into localHT
{URL}	{localHT.Insert(string(yytext));}
{PHONENUMBER}	{localHT.Insert(string(yytext));}
{FLOATNUMBER}	{localHT.Insert(string(yytext));}
{NUMBER}	{
				if(yyleng > 1) {
					localHT.Insert(string(yytext));
				}
			}
{VERSIONNO}	{localHT.Insert(string(yytext));}
{STARTTAG}	; //consume tags
{ENDTAG}	; //consume tags
{CAPWORD}	{
				if(yyleng > 1){
					toLowerArray(yytext, yyleng);
					if(!inStopList(yytext)) {
						localHT.Insert(string(yytext));
					}
				}
			}
{ABBRWORD} 	{ //abbreviated words
				toLowerArray(yytext, yyleng);
				localHT.Insert(string(yytext));
			}
{COMBINEDWORD} 	{
					char *word = strtok(yytext, "-");
					while(word != NULL){
						if (strlen(word) > 1) {
							toLowerArray(word, strlen(word));
							if(!inStopList(word)) {
								localHT.Insert(string(word));
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
					localHT.Insert(string(yytext));
				}
			}
		}
[\n\t ]	;
.	;
%%
int main(int argc, char **argv) {
	if (argc < 2) { //check if argument is valid
		perror ("Invalid argument.\n");
		return 1;
	}
	
	ifstream dictFile("./DictFile.out");
	ifstream postFile("./posting.out");
	ifstream mapFile("./MappingFile.out");
	if(!dictFile || !postFile || !mapFile) { //inverted file open status check
		perror ("Failed opening dict, mapFile, or post file.\n");
		return 1;
	}

	string query;
	for(int i = 1; i < argc; i++){ //combine broken down query arguments
		query.append(argv[i]);
		query.append(" ");
	}
	
	YY_BUFFER_STATE buffer = yy_scan_string(query.c_str()); //tokenize string from buffer instead from a file.
	yylex();
	yy_delete_buffer(buffer);
	
	mapFile.seekg(0, mapFile.end);
	int totalDocCount = mapFile.tellg() / mapRecSize; //calculate number of document
	dictFile.seekg(0, dictFile.end);
	int sizeOfDict = dictFile.tellg() / DictRecSize; //calculate number of records in the dict file
	
	AccumulatorNode weight[totalDocCount]; //weight accumulator
	vector<StringIntPair> record;
	localHT.getNonEmptyEntries(record); //get uniq record
	
	for(int i = 0; i < record.size(); i++) { //process each uniq query token
		int numDoc = 0;
		int startLoc = find(record.at(i).key, dictFile, sizeOfDict, numDoc);
		if(startLoc >= 0) { //if query token is found in dict file
			postFile.seekg(postingRecSize * startLoc);
			int queryTokenFreq = record.at(i).data1; //query token freq
			int docID = 0, freq = 0;
			double wt = 0.0;
			for(int j = 0; j < numDoc; j++) { //read num doc amount of record from posting file
				postFile >> docID >> freq >> wt;
				weight[docID].docId = docID;
				weight[docID].weight = weight[docID].weight + wt * queryTokenFreq;
			}
		}
	}
	
	sort(weight, weight + totalDocCount, [](const AccumulatorNode &a, const AccumulatorNode &b) -> bool {
		return a.weight > b.weight;
	}); //sort best result
	
	if(weight[0].weight != 0.0) { //if there is a query result
		cout << setw(7) << "Ranking" << " " << setw(6) << "Doc ID" << " " << setw(13) << "Document name" << " " << setw(8) << "Weight" << endl;
		for(int i = 0; i < numOfResult; i++) { //loop till hard limit of result displayed
			if(weight[i].weight == 0.0) { //break loop when all result displayed
				break;
			}
			mapFile.seekg(mapRecSize * weight[i].docId);
			int docID;
			string docName;
			mapFile >> docID >> docName;
			cout << setw(7) << i << " " << setw(6) << docID << " " << setw(13) << docName << " " << setw(8) << weight[i].weight << endl;
		}
	} else {
		cout << "No search result found! X_X" << endl;
	}
	
	dictFile.close(); //close file handle
	postFile.close();
	mapFile.close();
}

int find(const string Key, ifstream &dictFile, const int size, int &numDoc) { //return start position of the posting file. -1 means query token is not in the dict file
	unsigned long Sum = 0;
	unsigned long Index;
	
	for (int i = 0; i < Key.length(); i++) {
		Sum = (Sum * 29) + Key[i]; // Mult sum by 29, add byte value of char
	}
	
	Index = Sum % size;
	
	dictFile.seekg(Index * DictRecSize);
	
	string key = "";
	int start = 0;
	double idf = 0.0;
	dictFile >> key >> numDoc >> start >> idf;
	while(key != Key.substr(0, 10) && key != "!null!" && !dictFile.eof()) { //loop till either key is found, empty record, or end of file.
		dictFile >> key >> numDoc >> start >> idf;
	}
	
	if(key != Key.substr(0, 10)) {
		return -1;
	}
	return start;
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