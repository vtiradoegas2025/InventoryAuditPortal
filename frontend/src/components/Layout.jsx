import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

function Layout({ children }) {
  const location = useLocation()
  const navigate = useNavigate()
  const { user, logout } = useAuth()

  const isActive = (path) => location.pathname === path

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const getRoleBadgeColor = (role) => {
    switch (role) {
      case 'ADMIN':
        return 'bg-red-100 text-red-800'
      case 'MANAGER':
        return 'bg-yellow-100 text-yellow-800'
      case 'USER':
        return 'bg-blue-100 text-blue-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-blue-600 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex">
              <div className="flex-shrink-0 flex items-center">
                <h1 className="text-white text-xl font-bold">Inventory Audit Portal</h1>
              </div>
              <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                <Link
                  to="/"
                  className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                    isActive('/')
                      ? 'border-white text-white'
                      : 'border-transparent text-blue-100 hover:border-blue-300 hover:text-white'
                  }`}
                >
                  Inventory
                </Link>
                <Link
                  to="/audit"
                  className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                    isActive('/audit')
                      ? 'border-white text-white'
                      : 'border-transparent text-blue-100 hover:border-blue-300 hover:text-white'
                  }`}
                >
                  Audit Events
                </Link>
                <Link
                  to="/summary"
                  className={`inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium ${
                    isActive('/summary')
                      ? 'border-white text-white'
                      : 'border-transparent text-blue-100 hover:border-blue-300 hover:text-white'
                  }`}
                >
                  Location Summary
                </Link>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              {user && (
                <div className="flex items-center space-x-2">
                  <span className="text-blue-100 text-sm">{user.username}</span>
                  {user.roles && user.roles.length > 0 && (
                    <span className={`px-2 py-1 rounded text-xs font-medium ${getRoleBadgeColor(user.roles[0])}`}>
                      {user.roles[0]}
                    </span>
                  )}
                  <button
                    onClick={handleLogout}
                    className="text-blue-100 hover:text-white text-sm font-medium"
                  >
                    Logout
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Mobile menu */}
        <div className="sm:hidden">
          <div className="pt-2 pb-3 space-y-1">
            <Link
              to="/"
              className={`block pl-3 pr-4 py-2 border-l-4 text-base font-medium ${
                isActive('/')
                  ? 'bg-blue-50 border-blue-500 text-blue-700'
                  : 'border-transparent text-blue-100 hover:bg-blue-50 hover:border-blue-300 hover:text-blue-700'
              }`}
            >
              Inventory
            </Link>
            <Link
              to="/audit"
              className={`block pl-3 pr-4 py-2 border-l-4 text-base font-medium ${
                isActive('/audit')
                  ? 'bg-blue-50 border-blue-500 text-blue-700'
                  : 'border-transparent text-blue-100 hover:bg-blue-50 hover:border-blue-300 hover:text-blue-700'
              }`}
            >
              Audit Events
            </Link>
            <Link
              to="/summary"
              className={`block pl-3 pr-4 py-2 border-l-4 text-base font-medium ${
                isActive('/summary')
                  ? 'bg-blue-50 border-blue-500 text-blue-700'
                  : 'border-transparent text-blue-100 hover:bg-blue-50 hover:border-blue-300 hover:text-blue-700'
              }`}
            >
              Location Summary
            </Link>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  )
}

export default Layout

