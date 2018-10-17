#include <string>
#include <fstream>
#include <cstring>
#include <dirent.h>
#include <assert.h>
#include <vector>
#include <iostream>
#include "./include/BufferNode.hpp"
#include "./include/hashtable.h"

using namespace std;

void readToBuffer(vector<ifstream *> tempFileHandles, vector<BufferNode> &buffer, const int startIndex, const string key, int &currentPostIndex, ofstream &postingFile) {
	for(int i = startIndex; i < buffer.size(); i++) {
		StringIntPair &record = buffer.at(i).record;
		if(record.key == key){
			postingFile << record.data1 << " " << record.data2 << endl; // write posting
			currentPostIndex++;
			if((*(tempFileHandles.at(i))).peek() != EOF) {

				(*(tempFileHandles.at(i))) >> record.key >> record.data1 >> record.data2;
				//cout << "I'm in " << record.key << " " << record.data1 << " " << record.data2 << " " << endl;
				//cout << "I'm in " << buffer.at(i).record.key << " " << buffer.at(i).record.data1 << " " << buffer.at(i).record.data2 << " " << endl;
				while(record.key == key && ((*(tempFileHandles.at(i))).peek() != EOF)) {
					postingFile << record.data1 << " " << record.data2 << endl; // write posting
					currentPostIndex++;
					(*(tempFileHandles.at(i))) >> record.key >> record.data1 >> record.data2;
					//cout << "reading buffer index: " << i << " " << "No eof: " << ((*(tempFileHandles.at(i))).peek() != EOF) << endl;
					//cout << "posting: " << record.key <<" "<< record.data1 << " " << record.data2<<endl;
				}
			} else {
				//cout << "end of file\n";
				buffer.erase(buffer.begin() + i);
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

int main(int argc, char **argv) {
	const int maxTempFileNumber = 1019;
	HashTable globalHT("./tempDictFile.out"); //reload global ht
	DIR* dir;
	struct dirent *dirEntry;

	if((dir = opendir("./temp")) != NULL) { //if file directory exist
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
			//if(*(tempFileHandles.at(i)) ) { //if read successful
				*(tempFileHandles.at(i)) >> record.key >> record.data1 >> record.data2; //key, doc id, freq
				buffer.push_back(BufferNode(record, i));
			//} //else end of file, do not push to vector
		}
		
		int currentPostIndex = 0;
		ofstream postingFile("./posting.out");
		while(!buffer.empty()) {//buffer not empty
			int lowestIndex = alphabetFirstTokenIndex(buffer);
			//cout << "low index: " << lowestIndex << " process " << buffer.at(lowestIndex).record.key << endl;
			StringIntPair* globalRecord = globalHT.GetData(buffer.at(lowestIndex).record.key);
			if(globalRecord != NULL) {
				//cout << "record before: " << globalRecord->data2 << endl;
				globalRecord->data2 = currentPostIndex; //start position
				//cout << "record after: " << globalRecord->data2 << endl << "process "<< globalRecord->key << endl;
				readToBuffer(tempFileHandles, buffer, lowestIndex, globalRecord->key, currentPostIndex, postingFile);
			}
			//cout << "Size of buffer: " << buffer.size() << endl;
		}
		postingFile.close();
		for(int i = 0; i < tempFileHandles.size(); i++) {
			(*(tempFileHandles.at(i))).close();
		}
		tempFileHandles.clear();
		globalHT.Print("./FinalDictFile.out");
	} else {
		perror ("Could not open temp file directory.\n");
		return 1;
    }
}
