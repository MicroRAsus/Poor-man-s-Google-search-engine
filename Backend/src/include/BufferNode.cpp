#include "BufferNode.hpp"

using namespace std;

BufferNode::BufferNode(StringIntPair Record, int BufferIndex) {
	record = StringIntPair(Record);
	bufferIndex = BufferIndex;
}