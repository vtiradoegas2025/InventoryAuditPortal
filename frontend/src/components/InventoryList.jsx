import { useState, useEffect, useCallback } from 'react'
import { useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { inventoryApi } from '../services/api'
import SearchBar from './SearchBar'
import InventoryForm from './InventoryForm'
import Pagination from './Pagination'

function InventoryList() {
  const location = useLocation()
  const { hasRole } = useAuth()
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [page, setPage] = useState(0)
  const [size, setSize] = useState(50)
  const [sortBy, setSortBy] = useState('updatedAt')
  const [sortDir, setSortDir] = useState('DESC')
  const [totalPages, setTotalPages] = useState(0)
  const [totalElements, setTotalElements] = useState(0)
  const [showForm, setShowForm] = useState(false)
  const [editingItem, setEditingItem] = useState(null)
  const [searchMode, setSearchMode] = useState(null) // 'sku' or 'name'
  const [searchTerm, setSearchTerm] = useState('')
  const [locationFilter, setLocationFilter] = useState(location.state?.locationFilter || '')
  const [locations, setLocations] = useState([])
  const [successMessage, setSuccessMessage] = useState(null)

  // Check if user can edit/delete (MANAGER or ADMIN)
  const canEdit = hasRole('MANAGER') || hasRole('ADMIN')
  const canCreate = canEdit

  const fetchItems = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      let data
      if (searchMode === 'sku' && searchTerm) {
        data = await inventoryApi.searchBySku(searchTerm, page, size)
      } else if (searchMode === 'name' && searchTerm) {
        data = await inventoryApi.searchByName(searchTerm, page, size)
      } else if (locationFilter) {
        data = await inventoryApi.getByLocation(locationFilter, page, size, sortBy, sortDir)
      } else {
        data = await inventoryApi.getAll(page, size, sortBy, sortDir)
      }
      setItems(data.content || [])
      setTotalPages(data.totalPages || 0)
      setTotalElements(data.totalElements || 0)
    } catch (err) {
      setError(err.message || 'Failed to fetch inventory items')
      setItems([])
    } finally {
      setLoading(false)
    }
  }, [page, size, sortBy, sortDir, searchMode, searchTerm, locationFilter])

  const fetchLocations = useCallback(async () => {
    try {
      const summary = await inventoryApi.getLocationSummary()
      const locationList = summary.map(([location]) => location).filter(Boolean)
      setLocations(locationList)
    } catch (err) {
      console.error('Failed to fetch locations:', err)
    }
  }, [])

  useEffect(() => {
    fetchItems()
  }, [fetchItems])

  useEffect(() => {
    fetchLocations()
  }, [fetchLocations])

  const handleSearch = useCallback((term, type) => {
    setSearchTerm(term)
    setSearchMode(type)
    setPage(0)
  }, [])

  const handleSearchClear = useCallback(() => {
    setSearchTerm('')
    setSearchMode(null)
    setPage(0)
  }, [])

  const handleSort = (field) => {
    if (sortBy === field) {
      setSortDir(sortDir === 'ASC' ? 'DESC' : 'ASC')
    } else {
      setSortBy(field)
      setSortDir('ASC')
    }
    setPage(0)
  }

  const handleLocationFilter = (location) => {
    setLocationFilter(location)
    setPage(0)
  }

  const handleCreate = () => {
    setEditingItem(null)
    setShowForm(true)
  }

  const handleEdit = (item) => {
    setEditingItem(item)
    setShowForm(true)
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this item?')) {
      return
    }
    try {
      await inventoryApi.delete(id)
      setSuccessMessage('Item deleted successfully')
      setTimeout(() => setSuccessMessage(null), 3000)
      fetchItems()
    } catch (err) {
      setError(err.message || 'Failed to delete item')
      setTimeout(() => setError(null), 5000)
    }
  }

  const handleSave = async (formData) => {
    try {
      if (editingItem) {
        await inventoryApi.update(editingItem.id, formData)
        setSuccessMessage('Item updated successfully')
      } else {
        await inventoryApi.create(formData)
        setSuccessMessage('Item created successfully')
      }
      setShowForm(false)
      setEditingItem(null)
      setTimeout(() => setSuccessMessage(null), 3000)
      fetchItems()
    } catch (err) {
      throw err
    }
  }

  const handleCancel = () => {
    setShowForm(false)
    setEditingItem(null)
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

  return (
    <div className="px-4 sm:px-6 lg:px-8">
      <div className="sm:flex sm:items-center">
        <div className="sm:flex-auto">
          <h1 className="text-2xl font-semibold text-gray-900">Inventory Items</h1>
          <p className="mt-2 text-sm text-gray-700">
            Manage your inventory items. Total: {totalElements} items
          </p>
        </div>
        <div className="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
          <button
            onClick={handleCreate}
            disabled={!canCreate}
            title={!canCreate ? 'You do not have permission to create items' : ''}
            className={`block rounded-md px-3 py-2 text-center text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 ${
              canCreate
                ? 'bg-blue-600 hover:bg-blue-500 focus-visible:outline-blue-600'
                : 'bg-gray-400 cursor-not-allowed opacity-50'
            }`}
          >
            Add Item
          </button>
        </div>
      </div>

      {successMessage && (
        <div className="mt-4 rounded-md bg-green-50 p-4">
          <div className="flex">
            <div className="ml-3">
              <p className="text-sm font-medium text-green-800">{successMessage}</p>
            </div>
          </div>
        </div>
      )}

      {error && (
        <div className="mt-4 rounded-md bg-red-50 p-4">
          <div className="flex">
            <div className="ml-3">
              <p className="text-sm font-medium text-red-800">{error}</p>
            </div>
          </div>
        </div>
      )}

      <div className="mt-6 space-y-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <div className="flex gap-2">
              <div className="flex-1">
                <SearchBar
                  onSearch={(term) => handleSearch(term, 'sku')}
                  onClear={handleSearchClear}
                  searchType="sku"
                />
              </div>
              <div className="flex-1">
                <SearchBar
                  onSearch={(term) => handleSearch(term, 'name')}
                  onClear={handleSearchClear}
                  searchType="name"
                />
              </div>
            </div>
          </div>
          <div className="sm:w-48">
            <select
              value={locationFilter}
              onChange={(e) => handleLocationFilter(e.target.value)}
              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
            >
              <option value="">All Locations</option>
              {locations.map((loc) => (
                <option key={loc} value={loc}>
                  {loc}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="mt-8 text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <p className="mt-2 text-sm text-gray-600">Loading...</p>
        </div>
      ) : items.length === 0 ? (
        <div className="mt-8 text-center">
          <p className="text-gray-500">No items found.</p>
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
                        onClick={() => handleSort('sku')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>SKU</span>
                          <SortIcon field="sku" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('name')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>Name</span>
                          <SortIcon field="name" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('qty')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>Quantity</span>
                          <SortIcon field="qty" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('location')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>Location</span>
                          <SortIcon field="location" />
                        </div>
                      </th>
                      <th
                        scope="col"
                        className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900 cursor-pointer"
                        onClick={() => handleSort('updatedAt')}
                      >
                        <div className="flex items-center space-x-1">
                          <span>Updated</span>
                          <SortIcon field="updatedAt" />
                        </div>
                      </th>
                      <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-0">
                        <span className="sr-only">Actions</span>
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 bg-white">
                    {items.map((item) => (
                      <tr key={item.id}>
                        <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                          {item.id}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{item.sku}</td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{item.name}</td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{item.qty}</td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">{item.location}</td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {formatDate(item.updatedAt)}
                        </td>
                        <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                          <button
                            onClick={() => handleEdit(item)}
                            disabled={!canEdit}
                            title={!canEdit ? 'You do not have permission to edit items' : ''}
                            className={`mr-4 ${
                              canEdit
                                ? 'text-blue-600 hover:text-blue-900'
                                : 'text-gray-400 cursor-not-allowed opacity-50'
                            }`}
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleDelete(item.id)}
                            disabled={!canEdit}
                            title={!canEdit ? 'You do not have permission to delete items' : ''}
                            className={
                              canEdit
                                ? 'text-red-600 hover:text-red-900'
                                : 'text-gray-400 cursor-not-allowed opacity-50'
                            }
                          >
                            Delete
                          </button>
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

      {showForm && (
        <InventoryForm
          item={editingItem}
          onSave={handleSave}
          onCancel={handleCancel}
        />
      )}
    </div>
  )
}

export default InventoryList

