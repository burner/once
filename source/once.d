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
	import std.traits : Unqual, CopyConstness, hasElaborateDestructor;
	static if(is(Unqual!(T) == struct)) {
		align(8) void[T.sizeof] buffer;
	} else static if(is(Unqual!(T) == class)) {
		align(8) T buffer;
	} else {
		T buffer;
	}

	~this() {
		static if(is(Unqual!T == struct) && hasElaborateDestructor!T) {
			if(this.wasAssigned) {
				(*cast(Unqual!(T)*)(this.buffer.ptr)).__dtor();
			}
		}
	}

	bool wasAssigned = false;

	@property const(bool) initialized() const @safe pure nothrow @nogc {
		return this.wasAssigned;
	}

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

	static if(is(Unqual!(T) == struct)) {
		void emplace(Args...)(auto ref Args args) {
			if(this.wasAssigned) {
				throw new AlreadyAssignedException(
						typeof(this).stringof ~ " was not yet assgined"
					);
			}
			static import std.conv;
			//*(cast(T*)this.buffer.ptr) = 
				std.conv.emplace!T(this.buffer, args);
			this.wasAssigned = true;
		}
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
	assert(!i.initialized);
	i = 10;
	assert(i.initialized);

	assert(i == 10);	
	assert(i.get() == 10);	

	assertThrown!(AlreadyAssignedException)(() {
				i = 11;
			}()
		);
}

unittest {
	import std.math : approxEqual;
	import std.format : format;
	struct Foo {
		int i;
		float j;
		int* ex;

		this(int i, float j, int* ex) {
			this.i = i;
			this.j = j;
			this.ex = ex;
		}

		~this() {
			if(this.ex !is null) {
				++(*this.ex);
			}
		}
	}

	int ex = 0;
	{
		Once!Foo f;
		assert(!f.initialized);
		f = Foo(10, 13.37, &ex);
		assert(f.initialized);

		assert(f.i == 10);
		assert(approxEqual(f.j, 13.37));
	}
	assert(ex == 2);

	{
		import std.exception : assertThrown;
		Once!Foo g;
		g.emplace(1, 23.47, &ex);
		assert(g.i == 1);
		assert(approxEqual(g.j, 23.47));

		assertThrown!(AlreadyAssignedException)(g.emplace(2,3.3, &ex));
	}
	assert(ex == 3);
}
