#include "StringIntPair.hpp"
using namespace std;

struct BufferNode // the datatype stored in the buffer
{
	StringIntPair record;
	int bufferIndex;
	
	BufferNode(StringIntPair Record, int BufferIndex);
};