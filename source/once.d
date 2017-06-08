module once;

struct Once(T) {
	T value;
	bool wasAssigned = false;
}
