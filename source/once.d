module once;

class NotYetAssignedException : Exception {
	this(string msg, int line = __LINE__, string file = __FILE__) {
		super(msg, file, line);
	}
}

class AlreadyAssignedException : Exception {
	this(string msg, int line = __LINE__, string file = __FILE__) {
		super(msg, file, line);
	}
}

struct Once(T) {
	import std.traits : Unqual, CopyConstness;
	static if(is(Unqual!(T) == struct)) {
		ubyte[T.sizeof] buffer;
	} else static if(is(Unqual!(T) == class)) {
		T buffer;
	} else {
		T buffer;
	}

	bool wasAssigned = false;

	alias get this;

	ref CopyConstness!(S,T) get(this S)() {
		if(this.wasAssigned) {
			static if(is(Unqual!(T) == struct)) {
				return *cast(CopyConstness!(S,T*))(this.buffer.ptr);
			} else {
				return this.buffer;
			}
		} else {
			throw new NotYetAssignedException(
					typeof(this).stringof ~ " was not yet assgined"
				);
		}
	}

	void opAssign(T elem) {
		if(this.wasAssigned) {
			throw new AlreadyAssignedException(
					typeof(this).stringof ~ " was already assgined"
				);
		}
		static if(is(Unqual!(T) == struct)) {
			*(cast(T*)this.buffer.ptr) = elem;
		} else static if(is(Unqual!(T) == class)) {
			this.buffer = elem;
		} else {
			this.buffer = elem;
		}
		this.wasAssigned = true;
	}


}

unittest {
	import std.exception : assertThrown;

	Once!(int) i;

	assertThrown!(NotYetAssignedException)(i.get());
}

unittest {
	import std.exception : assertThrown;

	Once!(int) i;
	i = 10;

	assert(i == 10);	
	assert(i.get() == 10);	

	assertThrown!(AlreadyAssignedException)(() {
				i = 11;
			}()
		);
}

unittest {
	import std.math : approxEqual;
	struct Foo {
		int i;
		float j;
	}

	Once!Foo f;
	f = Foo(10, 13.37);

	assert(f.i == 10);
	assert(approxEqual(f.j, 13.37));
}
