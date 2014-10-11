// execinfo.h
// Dummy routines that implement execinfo
//
// http://www.gnu.org/software/libc/manual/html_node/Backtraces.html
//

int backtrace (void **buffer, int size)
{
	return 0;
}

char ** backtrace_symbols (void *const *buffer, int size)
{
	return 0;
}

void backtrace_symbols_fd (void *const *buffer, int size, int fd)
{
}
