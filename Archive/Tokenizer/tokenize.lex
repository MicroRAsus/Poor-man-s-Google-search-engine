%{
#include <string>
#include <dirent.h>
#include <ctime>
using namespace std;

char toLower(char text);
void toLowerArray(char* text, int leng);
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
URL (http:\/\/www\.|https:\/\/www\.|http:\/\/WWW\.|https:\/\/WWW\.|http:\/\/|https:\/\/)?{ALPHANO}+([\-\.]{1}{ALPHANO}+)*\.{ALPHANO}{2,5}(:[0-9]{1,5})?(\/[^< >"\n]*)?
FORWARDSLASH [\/]
PROPERTY {INDENTATION}+(([A-Za-z\-_]+)?{INDENTATION}*=?{INDENTATION}*((\"[^\"]*\")|({ALPHANO}+)|({URL})){INDENTATION}*)+{INDENTATION}*
STARTTAG <!?{ALPHANO}+{PROPERTY}*{FORWARDSLASH}?>
ENDTAG <{FORWARDSLASH}{ALPHANO}+>
%%
{EMAIL}	{ECHO; fputs("\n", yyout);}
{URL}	{ECHO; fputs("\n", yyout);}
{PHONENUMBER}	{ECHO; fputs("\n", yyout);}
{FLOATNUMBER}	{ECHO; fputs("\n", yyout);}
{NUMBER}	{ECHO; fputs("\n", yyout);}
{VERSIONNO}	{ECHO; fputs("\n", yyout);}
{STARTTAG}	; //consume tags
{ENDTAG}	; //consume tags
{CAPWORD}	{	
				toLowerArray(yytext, yyleng);
				ECHO;
				fputs("\n", yyout);
			}
{ABBRWORD} 	{ //abbreviated words
				toLowerArray(yytext, yyleng);
				ECHO;
				fputs("\n", yyout);
			}
{COMBINEDWORD} 	{
					for(int i = 0; i < yyleng; i++) {
						if(yytext[i] <= 'Z' && yytext[i] >= 'A') {
							yytext[i] = toLower(yytext[i]);
						} else if (yytext[i] == '-') {
							yytext[i] = '\n';
						}
					}
					ECHO;
					fputs("\n", yyout);
				}
{WORD}	{
			if(yytext[0] <= 'Z' && yytext[0] >= 'A') {
				yytext[0] = toLower(yytext[0]);
			}
			ECHO;
			fputs("\n", yyout);
		}

[\n\t ]	;
.	;
%%
int main(int argc, char **argv) {
	if (argc < 2) { //check if argument is valid
		perror ("Invalid argument.\n");
		return 1;
	}
	
	DIR* dir;
	struct dirent *dirEntry;
	//clock_t startTime = clock();
	//int counter = 0;

	if((dir = opendir(argv[1])) != NULL) { //if file directory exist
		string fileDirectory(argv[1]);
		while((dirEntry = readdir(dir)) != NULL) { //loop over each files in directory
			if((strcmp(dirEntry->d_name,".") != 0) && (strcmp(dirEntry->d_name,"..") != 0) && (strstr(dirEntry->d_name,".html") != NULL)) {
				string fileName(dirEntry->d_name);
				FILE *inFile = fopen((fileDirectory + "/" + fileName).c_str(),"r");
				yyout = fopen(("./output/" + fileName + ".out").c_str(), "w");
				if(inFile == NULL || yyout == NULL) {
					perror ("Failed open input or output file. Make sure output folder is in current directory.\n");
					return 1;
				}
                yyrestart(inFile); //set yyin to new input file and reset the lexer engine
				yylex(); //start scanning
				fclose(inFile); //close input file handle
				fclose(yyout); //close output file handle
				//timing
				//printf("%s%4d%s%10f%s\n", "Run time for processing ", ++counter, " files: ", (clock() - startTime) / (CLOCKS_PER_SEC / 1000.0), " millisecond.");
			}
		}                         
		closedir(dir);
		return 0;
    } else {
		perror ("Could not open directory.\n");
		return 1;
    }
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
