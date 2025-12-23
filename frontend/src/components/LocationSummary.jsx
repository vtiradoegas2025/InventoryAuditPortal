import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { inventoryApi } from '../services/api'

function LocationSummary() {
  const [summary, setSummary] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const navigate = useNavigate()

  useEffect(() => {
    fetchSummary()
  }, [])

  const fetchSummary = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await inventoryApi.getLocationSummary()
      // Data format: [[location, count, totalQty], ...]
      const formatted = data.map(([location, count, totalQty]) => ({
        location: location || 'Unknown',
        count: count || 0,
        totalQty: totalQty || 0,
      }))
      setSummary(formatted)
    } catch (err) {
      setError(err.message || 'Failed to fetch location summary')
      setSummary([])
    } finally {
      setLoading(false)
    }
  }

  const handleLocationClick = (location) => {
    // Navigate to inventory list with location filter
    // We'll need to pass this via URL params or state
    navigate('/', { state: { locationFilter: location } })
  }

  const totalLocations = summary.length
  const totalItems = summary.reduce((sum, item) => sum + item.count, 0)
  const totalQuantity = summary.reduce((sum, item) => sum + item.totalQty, 0)

  if (loading) {
    return (
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="text-center mt-8">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-2 text-sm text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="px-4 sm:px-6 lg:px-8">
        <div className="mt-4 rounded-md bg-red-50 p-4">
          <div className="flex">
            <div className="ml-3">
              <p className="text-sm font-medium text-red-800">{error}</p>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      <div className="sm:flex sm:items-center">
        <div className="sm:flex-auto">
          <h1 className="text-2xl font-semibold text-gray-900">Location Summary</h1>
          <p className="mt-2 text-sm text-gray-700">
            Overview of inventory distribution across locations
          </p>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-3">
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg
                  className="h-6 w-6 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Total Locations</dt>
                  <dd className="text-lg font-medium text-gray-900">{totalLocations}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg
                  className="h-6 w-6 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                  />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Total Items</dt>
                  <dd className="text-lg font-medium text-gray-900">{totalItems}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg
                  className="h-6 w-6 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Total Quantity</dt>
                  <dd className="text-lg font-medium text-gray-900">{totalQuantity.toLocaleString()}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Location Details Table */}
      <div className="mt-8">
        <h2 className="text-lg font-medium text-gray-900 mb-4">Location Details</h2>
        {summary.length === 0 ? (
          <div className="text-center py-8">
            <p className="text-gray-500">No location data available.</p>
          </div>
        ) : (
          <div className="bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
              {summary.map((item, index) => (
                <li key={index}>
                  <button
                    onClick={() => handleLocationClick(item.location)}
                    className="block hover:bg-gray-50 w-full"
                  >
                    <div className="px-4 py-4 sm:px-6">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <div className="flex-shrink-0">
                            <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
                              <span className="text-blue-600 font-semibold">
                                {item.location.charAt(0).toUpperCase()}
                              </span>
                            </div>
                          </div>
                          <div className="ml-4">
                            <div className="text-sm font-medium text-gray-900">{item.location}</div>
                            <div className="text-sm text-gray-500">
                              {item.count} {item.count === 1 ? 'item' : 'items'}
                            </div>
                          </div>
                        </div>
                        <div className="ml-4 flex-shrink-0">
                          <div className="text-sm font-medium text-gray-900">
                            {item.totalQty.toLocaleString()} units
                          </div>
                          <div className="text-sm text-gray-500">
                            Avg: {item.count > 0 ? Math.round(item.totalQty / item.count) : 0} per item
                          </div>
                        </div>
                        <div className="ml-4">
                          <svg
                            className="h-5 w-5 text-gray-400"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              strokeLinecap="round"
                              strokeLinejoin="round"
                              strokeWidth={2}
                              d="M9 5l7 7-7 7"
                            />
                          </svg>
                        </div>
                      </div>
                    </div>
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </div>
  )
}

export default LocationSummary

