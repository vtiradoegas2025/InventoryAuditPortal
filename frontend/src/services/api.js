const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api';

// Get token from localStorage
const getToken = () => {
  return localStorage.getItem('token');
};

// Handle 401 responses (unauthorized) - trigger logout
const handleUnauthorized = () => {
  localStorage.removeItem('token');
  // Redirect to login if not already there
  if (window.location.pathname !== '/login') {
    window.location.href = '/login';
  }
};

const getHeaders = () => {
  const headers = {
    'Content-Type': 'application/json',
  };
  
  const token = getToken();
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  
  return headers;
};

const handleResponse = async (response) => {
  if (response.status === 401) {
    handleUnauthorized();
    throw new Error('Unauthorized - please log in again');
  }
  
  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'An error occurred' }));
    throw new Error(error.message || `HTTP error! status: ${response.status}`);
  }
  return response.json();
};

// Inventory Item API
export const inventoryApi = {
  // Get paginated list of items
  getAll: async (page = 0, size = 50, sortBy = 'updatedAt', sortDir = 'DESC') => {
    const params = new URLSearchParams({
      page: page.toString(),
      size: size.toString(),
      sortBy,
      sortDir,
    });
    const response = await fetch(`${API_BASE_URL}/inventory?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get item by ID
  getById: async (id) => {
    const response = await fetch(`${API_BASE_URL}/inventory/${id}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get item by SKU
  getBySku: async (sku) => {
    const response = await fetch(`${API_BASE_URL}/inventory/sku/${sku}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get items by location
  getByLocation: async (location, page = 0, size = 50, sortBy = 'updatedAt', sortDir = 'DESC') => {
    const params = new URLSearchParams({
      page: page.toString(),
      size: size.toString(),
      sortBy,
      sortDir,
    });
    const response = await fetch(`${API_BASE_URL}/inventory/location/${location}?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Search by SKU pattern
  searchBySku: async (pattern, page = 0, size = 50) => {
    const params = new URLSearchParams({
      pattern,
      page: page.toString(),
      size: size.toString(),
    });
    const response = await fetch(`${API_BASE_URL}/inventory/search/sku?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Search by name pattern
  searchByName: async (pattern, page = 0, size = 50) => {
    const params = new URLSearchParams({
      pattern,
      page: page.toString(),
      size: size.toString(),
    });
    const response = await fetch(`${API_BASE_URL}/inventory/search/name?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get location summary
  getLocationSummary: async () => {
    const response = await fetch(`${API_BASE_URL}/inventory/summary/location`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Create item
  create: async (item) => {
    const response = await fetch(`${API_BASE_URL}/inventory`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify(item),
    });
    return handleResponse(response);
  },

  // Create batch
  createBatch: async (items) => {
    const response = await fetch(`${API_BASE_URL}/inventory/batch`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify(items),
    });
    return handleResponse(response);
  },

  // Update item
  update: async (id, item) => {
    const response = await fetch(`${API_BASE_URL}/inventory/${id}`, {
      method: 'PUT',
      headers: getHeaders(),
      body: JSON.stringify(item),
    });
    return handleResponse(response);
  },

  // Delete item
  delete: async (id) => {
    const response = await fetch(`${API_BASE_URL}/inventory/${id}`, {
      method: 'DELETE',
      headers: getHeaders(),
    });
    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'An error occurred' }));
      throw new Error(error.message || `HTTP error! status: ${response.status}`);
    }
    return null;
  },
};

// Audit Event API
export const auditApi = {
  // Get paginated list of events
  getAll: async (page = 0, size = 50, sortBy = 'timestamp', sortDir = 'DESC') => {
    const params = new URLSearchParams({
      page: page.toString(),
      size: size.toString(),
      sortBy,
      sortDir,
    });
    const response = await fetch(`${API_BASE_URL}/audit-events?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get event by ID
  getById: async (id) => {
    const response = await fetch(`${API_BASE_URL}/audit-events/${id}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get events by entity
  getByEntity: async (entityType, entityId, page = 0, size = 50, sortBy = 'timestamp', sortDir = 'DESC') => {
    const params = new URLSearchParams({
      page: page.toString(),
      size: size.toString(),
      sortBy,
      sortDir,
    });
    const response = await fetch(`${API_BASE_URL}/audit-events/entity/${entityType}/${entityId}?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get events by entity type
  getByEntityType: async (entityType, page = 0, size = 50, sortBy = 'timestamp', sortDir = 'DESC') => {
    const params = new URLSearchParams({
      page: page.toString(),
      size: size.toString(),
      sortBy,
      sortDir,
    });
    const response = await fetch(`${API_BASE_URL}/audit-events/entity-type/${entityType}?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get events by event type
  getByEventType: async (eventType, page = 0, size = 50, sortBy = 'timestamp', sortDir = 'DESC') => {
    const params = new URLSearchParams({
      page: page.toString(),
      size: size.toString(),
      sortBy,
      sortDir,
    });
    const response = await fetch(`${API_BASE_URL}/audit-events/event-type/${eventType}?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Get events by user ID
  getByUserId: async (userId, page = 0, size = 50, sortBy = 'timestamp', sortDir = 'DESC') => {
    const params = new URLSearchParams({
      page: page.toString(),
      size: size.toString(),
      sortBy,
      sortDir,
    });
    const response = await fetch(`${API_BASE_URL}/audit-events/user/${userId}?${params}`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Create event (manual)
  create: async (event) => {
    const response = await fetch(`${API_BASE_URL}/audit-events`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify(event),
    });
    return handleResponse(response);
  },
};

// Authentication API
export const authApi = {
  // Register new user
  register: async (username, email, password, role = 'USER') => {
    const response = await fetch(`${API_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify({ username, email, password, role }),
    });
    return handleResponse(response);
  },

  // Login
  login: async (username, password) => {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify({ username, password }),
    });
    return handleResponse(response);
  },

  // Get current user
  getCurrentUser: async () => {
    const response = await fetch(`${API_BASE_URL}/auth/me`, {
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Logout
  logout: async () => {
    const response = await fetch(`${API_BASE_URL}/auth/logout`, {
      method: 'POST',
      headers: getHeaders(),
    });
    return handleResponse(response);
  },

  // Forgot password
  forgotPassword: async (email) => {
    const response = await fetch(`${API_BASE_URL}/auth/forgot-password`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify({ email }),
    });
    return handleResponse(response);
  },

  // Reset password
  resetPassword: async (token, newPassword) => {
    const response = await fetch(`${API_BASE_URL}/auth/reset-password`, {
      method: 'POST',
      headers: getHeaders(),
      body: JSON.stringify({ token, newPassword }),
    });
    return handleResponse(response);
  },
};

