%{
#include <string>
#include <dirent.h>
#include <vector>
#include <algorithm>
#include <assert.h> 

#include "./include/hashtable.h"

using namespace std;

const int localHTSize = 8669; //calculated from top most uniq token document
const int totalUniqTokenSize = 63709;
const int top10DocTokenSize = 9000;
HashTable *localHT = NULL;
HashTable globalHT(totalUniqTokenSize);
int currentDoc = 0; //doc id
char toLower(char text);
void toLowerArray(char* text, int leng);
string buildTempFileName(int currentIndex, int mergeNumber);
bool fileOpenStatusCheck(FILE *file, string ifFailMSG);
void printPass1TempFile(vector<StringIntPair> &records, int mergeNumber);
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
URL (http:\/\/www\.|https:\/\/www\.|http:\/\/WWW\.|https:\/\/WWW\.|http:\/\/|https:\/\/)?{ALPHANO}+([\-\.]{1}{ALPHANO}+)*\.{ALPHANO}{2,5}(:[0-9]{1,5})?(\/[^< >"]*)?
FORWARDSLASH [\/]
PROPERTY {INDENTATION}+(([A-Za-z\-_]+)?{INDENTATION}*=?{INDENTATION}*((\"[^\"]*\")|({ALPHANO}+)|({URL})){INDENTATION}*)+{INDENTATION}*
STARTTAG <!?{ALPHANO}+{PROPERTY}*{FORWARDSLASH}?>
ENDTAG <{FORWARDSLASH}{ALPHANO}+>
%%
{EMAIL}	;//{localHT->Insert(string(yytext), currentDoc, 1, false);} //insert matched token into localHT
{URL}	;//{localHT->Insert(string(yytext), currentDoc, 1, false);}
{PHONENUMBER}	{localHT->Insert(string(yytext), currentDoc, 1, false);}
{FLOATNUMBER}	{localHT->Insert(string(yytext), currentDoc, 1, false);}
{NUMBER}	{localHT->Insert(string(yytext), currentDoc, 1, false);}
{VERSIONNO}	{localHT->Insert(string(yytext), currentDoc, 1, false);}
{STARTTAG}	; //consume tags
{ENDTAG}	; //consume tags
{CAPWORD}	{	
				toLowerArray(yytext, yyleng);
				localHT->Insert(string(yytext), currentDoc, 1, false);
			}
{ABBRWORD} 	{ //abbreviated words
				toLowerArray(yytext, yyleng);
				localHT->Insert(string(yytext), currentDoc, 1, false);
			}
{COMBINEDWORD} 	{
					toLowerArray(yytext, yyleng);
					localHT->Insert(string(yytext), currentDoc, 1, false);
				}
{WORD}	{
			if(yytext[0] <= 'Z' && yytext[0] >= 'A') {
				yytext[0] = toLower(yytext[0]);
			}
			localHT->Insert(string(yytext), currentDoc, 1, false);
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
	
	if((dir = opendir(argv[1])) != NULL) { //if file directory exist
		string fileDirectory(argv[1]);
		FILE *mapfile = fopen("./MappingFile.out", "w");
		assert(fileOpenStatusCheck(mapfile, "Failed to create MappingFile.\n") == true); //file open check
		
		vector<StringIntPair> records;
		records.reserve(top10DocTokenSize);
		while((dirEntry = readdir(dir)) != NULL) { //loop over each files in directory
			if((strcmp(dirEntry->d_name,".") != 0) && (strcmp(dirEntry->d_name,"..") != 0) && (strstr(dirEntry->d_name,".html") != NULL)) {
				string fileName(dirEntry->d_name);
				FILE *inFile = fopen((fileDirectory + "/" + fileName).c_str(),"r");
				assert(fileOpenStatusCheck(inFile, "Failed to open input file. Make sure input file folder is in current directory.\n") == true); //file open check

				fputs((to_string(currentDoc) + " " + fileName + "\n").c_str(), mapfile); //write mapping file
				localHT = new HashTable(localHTSize); //create a new local hash table
                yyrestart(inFile); //set yyin to new input file and reset the lexer engine
				yylex(); //start scanning
				localHT->getNonEmptyEntries(records, globalHT); //insert non empty entries into vector and global ht
				fclose(inFile); //close input file handle
				delete localHT; //delete ht for current input file
				
				currentDoc++;
				if(currentDoc % mergeNumber == 0) { //if match merge number, write temp file
					printPass1TempFile(records, mergeNumber);
				}
				//after parsing all token in single doc, we get token+docid+freq, we make a function in hashtable to get non empty entries, 
				//insert them into vector of stringintpair
				//after looping, files count equal to # specified by arg2, we do sort by key, after that, we have sorted tokens of files, loop vector to print out the pass one file
				
				//after every yylex(), get non empty entries, insert into global ht, if key = "", set key = key and data1(numdoc) = 1
				//else key is in table, data1++
				//after all file process, print global ht(keep blank)
				
				//in pass 2, unmarshall the gloabal ht and load in to ht, load tokens, docid, freq into buffer using >>, get alphabetic first token in buffer
				//look up in till new token,
				//update the posting
			}
		}
		int remainder = currentDoc % mergeNumber;
		if(remainder != 0) { //file number is not fully divisible by the merge number, some records are not printed out to temp file
			printPass1TempFile(records, remainder); // print remainder temp file
		}
		//write global ht
		
		globalHT.Print("./tempDictFile.out");
		
		fclose(mapfile);
		closedir(dir);
		return 0;
    } else {
		perror ("Could not open directory.\n");
		return 1;
    }
}

string buildTempFileName(int currentIndex, int mergeNumber) {
	string s = to_string(currentIndex - 1);
	for(int i = currentIndex - 2; i >= currentIndex - mergeNumber; i--) {
		s = to_string(i) + "_" + s;
	}
	return s;
}

bool fileOpenStatusCheck(FILE *file, string ifFailMSG) {
	if(file == NULL) {
		perror(ifFailMSG.c_str());
		return false;
	}
	return true;
}

void printPass1TempFile(vector<StringIntPair> &records, int mergeNumber) {
	sort(records.begin(), records.end()); //sort tokens
	FILE *pass1TempFile = fopen(("./temp/" + buildTempFileName(currentDoc, mergeNumber) + ".out").c_str(), "w");
	assert(fileOpenStatusCheck(pass1TempFile, "Failed to write temp file. Make sure temp folder is in current directory.\n") == true); //file open check
	for(int i = 0; i < records.size(); i++) { //write all sorted records to temp file
		StringIntPair record = records.at(i);
		fputs((record.key + " " + to_string(record.data1) + " " + to_string(record.data2) + "\n").c_str(), pass1TempFile);
	}
	fclose(pass1TempFile);
	records.clear(); //delete all elements
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
