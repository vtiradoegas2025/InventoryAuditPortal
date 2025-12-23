import { createContext, useContext, useState, useEffect } from 'react';
import { authApi } from '../services/api';

const AuthContext = createContext(null);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('token'));
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is logged in on mount
    if (token) {
      loadUser();
    } else {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  const loadUser = async () => {
    try {
      const userData = await authApi.getCurrentUser();
      setUser(userData);
    } catch (error) {
      console.error('Failed to load user:', error);
      logout();
    } finally {
      setLoading(false);
    }
  };

  const login = async (username, password) => {
    try {
      const response = await authApi.login(username, password);
      setToken(response.token);
      setUser({
        id: response.id,
        username: response.username,
        email: response.email,
        roles: response.roles
      });
      localStorage.setItem('token', response.token);
      return response;
    } catch (error) {
      throw error;
    }
  };

  const register = async (username, email, password, role = 'USER') => {
    try {
      await authApi.register(username, email, password, role);
      // After registration, automatically log in
      return await login(username, password);
    } catch (error) {
      throw error;
    }
  };

  const logout = () => {
    setToken(null);
    setUser(null);
    localStorage.removeItem('token');
  };

  const hasRole = (role) => {
    return user?.roles?.includes(role) || false;
  };

  const isAuthenticated = !!token && !!user;

  const value = {
    user,
    token,
    login,
    register,
    logout,
    isAuthenticated,
    hasRole,
    loading
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

