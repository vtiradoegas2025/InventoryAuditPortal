import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { auditApi } from '../services/api'
import Pagination from './Pagination'

function AuditEventViewer() {
  const { user, hasRole } = useAuth()
  const [events, setEvents] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [page, setPage] = useState(0)
  const [size, setSize] = useState(50)
  const [sortBy, setSortBy] = useState('timestamp')
  const [sortDir, setSortDir] = useState('DESC')
  const [totalPages, setTotalPages] = useState(0)
  const [totalElements, setTotalElements] = useState(0)
  
  // Filters
  const [entityTypeFilter, setEntityTypeFilter] = useState('')
  const [eventTypeFilter, setEventTypeFilter] = useState('')
  const [userIdFilter, setUserIdFilter] = useState('')

  // USER role can only see their own events
  const isUserRole = hasRole('USER') && !hasRole('MANAGER') && !hasRole('ADMIN')
  const effectiveUserIdFilter = isUserRole ? user?.username : userIdFilter

  const fetchEvents = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      let data
      // USER role: always filter by their own userId
      if (isUserRole) {
        data = await auditApi.getByUserId(user?.username, page, size, sortBy, sortDir)
      } else if (entityTypeFilter && eventTypeFilter) {
        // If both filters are set, we'll use entity type filter (more specific)
        data = await auditApi.getByEntityType(entityTypeFilter, page, size, sortBy, sortDir)
      } else if (entityTypeFilter) {
        data = await auditApi.getByEntityType(entityTypeFilter, page, size, sortBy, sortDir)
      } else if (eventTypeFilter) {
        data = await auditApi.getByEventType(eventTypeFilter, page, size, sortBy, sortDir)
      } else if (effectiveUserIdFilter) {
        data = await auditApi.getByUserId(effectiveUserIdFilter, page, size, sortBy, sortDir)
      } else {
        data = await auditApi.getAll(page, size, sortBy, sortDir)
      }
      setEvents(data.content || [])
      setTotalPages(data.totalPages || 0)
      setTotalElements(data.totalElements || 0)
    } catch (err) {
      setError(err.message || 'Failed to fetch audit events')
      setEvents([])
    } finally {
      setLoading(false)
    }
  }, [page, size, sortBy, sortDir, entityTypeFilter, eventTypeFilter, effectiveUserIdFilter, isUserRole, user])

  useEffect(() => {
    fetchEvents()
  }, [fetchEvents])

  const handleSort = (field) => {
    if (sortBy === field) {
      setSortDir(sortDir === 'ASC' ? 'DESC' : 'ASC')
    } else {
      setSortBy(field)
      setSortDir('ASC')
    }
    setPage(0)
  }

  const handleFilterChange = (filterType, value) => {
    if (filterType === 'entityType') {
      setEntityTypeFilter(value)
    } else if (filterType === 'eventType') {
      setEventTypeFilter(value)
    } else if (filterType === 'userId') {
      setUserIdFilter(value)
    }
    setPage(0)
  }

  const clearFilters = () => {
    setEntityTypeFilter('')
    setEventTypeFilter('')
    setUserIdFilter('')
    setPage(0)
  }

  const formatDate = (dateString) => {
    if (!dateString) return ''
    return new Date(dateString).toLocaleString()
  }

  const SortIcon = ({ field }) => {
    if (sortBy !== field) {
      return (
        <svg className="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4" />
        </svg>
      )
    }
    return sortDir === 'ASC' ? (
      <svg className="w-4 h-4 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
      </svg>
    ) : (
      <svg className="w-4 h-4 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
      </svg>
    )
  }

  const getEventTypeBadgeColor = (eventType) => {
    switch (eventType?.toUpperCase()) {
      case 'CREATE':
        return 'bg-green-100 text-green-800'
      case 'UPDATE':
        return 'bg-blue-100 text-blue-800'
      case 'DELETE':
        return 'bg-red-100 text-red-800'
      case 'READ':
        return 'bg-gray-100 text-gray-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      <div className="sm:flex sm:items-center">
        <div className="sm:flex-auto">
          <h1 className="text-2xl font-semibold text-gray-900">Audit Events</h1>
          <p className="mt-2 text-sm text-gray-700">
            {isUserRole 
              ? `View your audit events. Total: ${totalElements} events`
              : `View all audit events and track changes. Total: ${totalElements} events`
            }
          </p>
        </div>
      </div>

      {error && (
        <div className="mt-4 rounded-md bg-red-50 p-4">
          <div className="flex">
            <div className="ml-3">
              <p className="text-sm font-medium text-red-800">{error}</p>
            </div>
          </div>
        </div>
      )}

      <div className="mt-6 bg-white shadow rounded-lg p-4">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label htmlFor="entityType" className="block text-sm font-medium text-gray-700 mb-1">
              Entity Type
            </label>
            <input
              type="text"
              id="entityType"
              value={entityTypeFilter}
              onChange={(e) => handleFilterChange('entityType', e.target.value)}
              placeholder="e.g., INVENTORY_ITEM"
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
            />
          </div>
          <div>
            <label htmlFor="eventType" className="block text-sm font-medium text-gray-700 mb-1">
              Event Type
            </label>
            <select
              id="eventType"
              value={eventTypeFilter}
              onChange={(e) => handleFilterChange('eventType', e.target.value)}
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
            >
              <option value="">All Types</option>
              <option value="CREATE">CREATE</option>
              <option value="UPDATE">UPDATE</option>
              <option value="DELETE">DELETE</option>
              <option value="READ">READ</option>
            </select>
          </div>
          <div>
            <label htmlFor="userId" className="block text-sm font-medium text-gray-700 mb-1">
              User ID
            </label>
            <input
              type="text"
              id="userId"
              value={isUserRole ? user?.username : userIdFilter}
              onChange={(e) => handleFilterChange('userId', e.target.value)}
              placeholder={isUserRole ? 'Your events only' : 'Filter by user'}
              disabled={isUserRole}
              title={isUserRole ? 'You can only view your own audit events' : ''}
              className={`block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm ${
                isUserRole ? 'bg-gray-100 cursor-not-allowed opacity-50' : ''
              }`}
            />
          </div>
          <div className="flex items-end">
            <button
              onClick={clearFilters}
              className="w-full rounded-md bg-gray-200 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
            >
              Clear Filters
            </button>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="mt-8 text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-2 text-sm text-gray-600">Loading...</p>
        </div>
      ) : events.length === 0 ? (
        <div className="mt-8 text-center">
          <p className="text-gray-500">No audit events found.</p>
        </div>
      ) : (
        <>
          <div className="mt-8 flow-root">
            <div className="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div className="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                <table className="min-w-full divide-y divide-gray-300">
                  <thead>
                    <tr>
                      <th
                        scope="col"
                        className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0 cursor-pointer"
                        onClick={() => handleSort('id')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>ID</span>
                          <SortIcon field="id" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('eventType')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>Event Type</span>
                          <SortIcon field="eventType" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('entityType')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>Entity Type</span>
                          <SortIcon field="entityType" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('entityId')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>Entity ID</span>
                          <SortIcon field="entityId" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('userId')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>User ID</span>
                          <SortIcon field="userId" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('timestamp')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>Timestamp</span>
                          <SortIcon field="timestamp" />
                        </div>
                      </th>
                      <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                        Details
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 bg-white">
                    {events.map((event) => (
                      <tr key={event.id}>
                        <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                          {event.id}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm">
                          <span className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${getEventTypeBadgeColor(event.eventType)}`}>
                            {event.eventType}
                          </span>
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{event.entityType}</td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{event.entityId}</td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{event.userId || '-'}</td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {formatDate(event.timestamp)}
                        </td>
                        <td className="px-3 py-4 text-sm text-gray-500">
                          {event.details ? (
                            <details className="cursor-pointer">
                              <summary className="text-blue-600 hover:text-blue-800">View Details</summary>
                              <pre className="mt-2 text-xs bg-gray-50 p-2 rounded overflow-auto max-w-md">
                                {event.details}
                              </pre>
                            </details>
                          ) : (
                            '-'
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <Pagination
            page={page}
            totalPages={totalPages}
            size={size}
            onPageChange={setPage}
            onSizeChange={(newSize) => {
              setSize(newSize)
              setPage(0)
            }}
          />
        </>
      )}
    </div>
  )
}

export default AuditEventViewer

