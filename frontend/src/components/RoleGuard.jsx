import { useAuth } from '../contexts/AuthContext';

function RoleGuard({ children, roles, fallback = null }) {
  const { hasRole } = useAuth();

  const hasRequiredRole = roles.some(role => hasRole(role));

  if (!hasRequiredRole) {
    return fallback;
  }

  return children;
}

export default RoleGuard;


