function Pagination({ page, totalPages, size, onPageChange, onSizeChange }) {
  const handlePrevious = () => {
    if (page > 0) {
      onPageChange(page - 1);
    }
  };

  const handleNext = () => {
    if (page < totalPages - 1) {
      onPageChange(page + 1);
    }
  };

  const handleSizeChange = (e) => {
    onSizeChange(parseInt(e.target.value));
  };

  if (totalPages === 0) {
    return null;
  }

  return (
    <div className="flex items-center justify-between border-t border-gray-200 bg-white px-4 py-3 sm:px-6">
      <div className="flex flex-1 justify-between sm:hidden">
        <button
          onClick={handlePrevious}
          disabled={page === 0}
          className={`relative inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium ${
            page === 0
              ? 'text-gray-300 cursor-not-allowed'
              : 'text-gray-700 hover:bg-gray-50'
          }`}
        >
          Previous
        </button>
        <button
          onClick={handleNext}
          disabled={page >= totalPages - 1}
          className={`relative ml-3 inline-flex items-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium ${
            page >= totalPages - 1
              ? 'text-gray-300 cursor-not-allowed'
              : 'text-gray-700 hover:bg-gray-50'
          }`}
        >
          Next
        </button>
      </div>
      <div className="hidden sm:flex sm:flex-1 sm:items-center sm:justify-between">
        <div>
          <p className="text-sm text-gray-700">
            Page <span className="font-medium">{page + 1}</span> of{' '}
            <span className="font-medium">{totalPages}</span>
          </p>
        </div>
        <div className="flex items-center space-x-4">
          <div className="flex items-center">
            <label htmlFor="page-size" className="text-sm text-gray-700 mr-2">
              Items per page:
            </label>
            <select
              id="page-size"
              value={size}
              onChange={handleSizeChange}
              className="rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
            >
              <option value={10}>10</option>
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>
          </div>
          <nav className="isolate inline-flex -space-x-px rounded-md shadow-sm" aria-label="Pagination">
            <button
              onClick={handlePrevious}
              disabled={page === 0}
              className={`relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 ${
                page === 0
                  ? 'cursor-not-allowed bg-gray-50'
                  : 'hover:bg-gray-50 focus:z-20 focus:outline-offset-0'
              }`}
            >
              <span className="sr-only">Previous</span>
              <svg className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fillRule="evenodd" d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z" clipRule="evenodd" />
              </svg>
            </button>
            <button
              onClick={handleNext}
              disabled={page >= totalPages - 1}
              className={`relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 ${
                page >= totalPages - 1
                  ? 'cursor-not-allowed bg-gray-50'
                  : 'hover:bg-gray-50 focus:z-20 focus:outline-offset-0'
              }`}
            >
              <span className="sr-only">Next</span>
              <svg className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                <path fillRule="evenodd" d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z" clipRule="evenodd" />
              </svg>
            </button>
          </nav>
        </div>
      </div>
    </div>
  );
}

export default Pagination;

