import { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'

function InventoryForm({ item, onSave, onCancel }) {
  const { hasRole } = useAuth()
  const [formData, setFormData] = useState({
    sku: '',
    name: '',
    qty: 0,
    location: '',
  })
  const [errors, setErrors] = useState({})
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Check if user can edit (MANAGER or ADMIN)
  const canEdit = hasRole('MANAGER') || hasRole('ADMIN')

  useEffect(() => {
    if (item) {
      setFormData({
        sku: item.sku || '',
        name: item.name || '',
        qty: item.qty || 0,
        location: item.location || '',
      })
    }
  }, [item])

  const validate = () => {
    const newErrors = {}
    if (!formData.sku || formData.sku.trim() === '') {
      newErrors.sku = 'SKU is required'
    }
    if (!formData.name || formData.name.trim() === '') {
      newErrors.name = 'Name is required'
    }
    if (formData.qty < 0) {
      newErrors.qty = 'Quantity must be 0 or greater'
    }
    if (!formData.location || formData.location.trim() === '') {
      newErrors.location = 'Location is required'
    }
    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!validate()) {
      return
    }

    setIsSubmitting(true)
    try {
      await onSave(formData)
    } catch (error) {
      setErrors({ submit: error.message || 'Failed to save item' })
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: name === 'qty' ? parseInt(value) || 0 : value,
    }))
    // Clear error for this field when user starts typing
    if (errors[name]) {
      setErrors((prev) => {
        const newErrors = { ...prev }
        delete newErrors[name]
        return newErrors
      })
    }
  }

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div className="mt-3">
          <h3 className="text-lg font-medium text-gray-900 mb-4">
            {item ? 'Edit Inventory Item' : 'Create New Inventory Item'}
          </h3>
          <form onSubmit={handleSubmit}>
            <div className="mb-4">
              <label htmlFor="sku" className="block text-sm font-medium text-gray-700">
                SKU *
              </label>
              <input
                type="text"
                id="sku"
                name="sku"
                value={formData.sku}
                onChange={handleChange}
                disabled={!!item || !canEdit}
                className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm ${
                  errors.sku ? 'border-red-300' : ''
                } ${(item || !canEdit) ? 'bg-gray-100 cursor-not-allowed' : ''}`}
              />
              {errors.sku && <p className="mt-1 text-sm text-red-600">{errors.sku}</p>}
            </div>

            <div className="mb-4">
              <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                Name *
              </label>
              <input
                type="text"
                id="name"
                name="name"
                value={formData.name}
                onChange={handleChange}
                disabled={!canEdit}
                className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm ${
                  errors.name ? 'border-red-300' : ''
                } ${!canEdit ? 'bg-gray-100 cursor-not-allowed' : ''}`}
              />
              {errors.name && <p className="mt-1 text-sm text-red-600">{errors.name}</p>}
            </div>

            <div className="mb-4">
              <label htmlFor="qty" className="block text-sm font-medium text-gray-700">
                Quantity *
              </label>
              <input
                type="number"
                id="qty"
                name="qty"
                min="0"
                value={formData.qty}
                onChange={handleChange}
                disabled={!canEdit}
                className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm ${
                  errors.qty ? 'border-red-300' : ''
                } ${!canEdit ? 'bg-gray-100 cursor-not-allowed' : ''}`}
              />
              {errors.qty && <p className="mt-1 text-sm text-red-600">{errors.qty}</p>}
            </div>

            <div className="mb-4">
              <label htmlFor="location" className="block text-sm font-medium text-gray-700">
                Location *
              </label>
              <input
                type="text"
                id="location"
                name="location"
                value={formData.location}
                onChange={handleChange}
                disabled={!canEdit}
                className={`mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm ${
                  errors.location ? 'border-red-300' : ''
                } ${!canEdit ? 'bg-gray-100 cursor-not-allowed' : ''}`}
              />
              {errors.location && <p className="mt-1 text-sm text-red-600">{errors.location}</p>}
            </div>

            {errors.submit && (
              <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-md">
                <p className="text-sm text-red-600">{errors.submit}</p>
              </div>
            )}

            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={onCancel}
                disabled={isSubmitting}
                className="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting || !canEdit}
                title={!canEdit ? 'You do not have permission to save items' : ''}
                className={`px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 ${
                  canEdit
                    ? 'bg-blue-600 hover:bg-blue-700 disabled:opacity-50'
                    : 'bg-gray-400 cursor-not-allowed opacity-50'
                }`}
              >
                {isSubmitting ? 'Saving...' : item ? 'Update' : 'Create'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

export default InventoryForm

