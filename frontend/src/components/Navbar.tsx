import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'
import { LogOut, Activity, Sparkles } from 'lucide-react'

export function Navbar() {
  const { isAuthenticated, user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  return (
    <nav className="sticky top-0 z-50 bg-gray-900/95 backdrop-blur-lg border-b border-gray-800/50 shadow-lg">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-8">
            <Link to="/" className="flex items-center space-x-3 group">
              <div className="relative">
                <div className="absolute inset-0 bg-blue-500/20 rounded-full blur-md group-hover:blur-lg transition-all duration-300"></div>
                <Activity className="w-8 h-8 text-blue-500 relative group-hover:scale-110 transition-transform duration-300" />
              </div>
              <span className="text-2xl font-bold bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
                CareFlowAI
              </span>
              <Sparkles className="w-4 h-4 text-yellow-400 animate-pulse" />
            </Link>

            <div className="flex space-x-2">
              <Link
                to="/"
                className="relative text-gray-300 hover:text-white px-4 py-2 rounded-lg text-sm font-medium transition-all duration-300 group overflow-hidden"
              >
                <span className="absolute inset-0 bg-gradient-to-r from-blue-600/0 via-blue-600/10 to-purple-600/0 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></span>
                <span className="relative">Home</span>
              </Link>
              {isAuthenticated && (
                <Link
                  to="/schedule"
                  className="relative text-gray-300 hover:text-white px-4 py-2 rounded-lg text-sm font-medium transition-all duration-300 group overflow-hidden"
                >
                  <span className="absolute inset-0 bg-gradient-to-r from-blue-600/0 via-blue-600/10 to-purple-600/0 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></span>
                  <span className="relative">Schedule</span>
                </Link>
              )}
            </div>
          </div>

          <div className="flex items-center space-x-4">
            {isAuthenticated ? (
              <>
                <div className="bg-gray-800/50 backdrop-blur-sm px-4 py-2 rounded-lg border border-gray-700/50">
                  <span className="text-gray-300 text-sm">
                    {user?.name}{' '}
                    <span className="inline-block px-2 py-0.5 bg-blue-500/20 text-blue-400 rounded-full text-xs font-medium border border-blue-500/30">
                      {user?.role}
                    </span>
                  </span>
                </div>
                <button
                  onClick={handleLogout}
                  className="flex items-center space-x-2 bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 text-white px-4 py-2 rounded-lg text-sm font-medium transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-red-500/50"
                >
                  <LogOut className="w-4 h-4" />
                  <span>Logout</span>
                </button>
              </>
            ) : (
              <Link
                to="/login"
                className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white px-6 py-2 rounded-lg text-sm font-semibold transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-blue-500/50"
              >
                Login
              </Link>
            )}
          </div>
        </div>
      </div>
    </nav>
  )
}
