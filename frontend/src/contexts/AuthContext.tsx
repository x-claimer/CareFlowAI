import { createContext, useContext, useState, useEffect } from 'react'
import type { ReactNode } from 'react'
import { api } from '../lib/api'

export type UserRole = 'patient' | 'doctor' | 'receptionist'

export interface User {
  id: string
  name: string
  email: string
  role: UserRole
}

interface AuthContextType {
  user: User | null
  signup: (name: string, email: string, password: string) => Promise<void>
  login: (email: string, password: string, role: UserRole) => Promise<void>
  logout: () => void
  isAuthenticated: boolean
  loading: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Check if user is already logged in on mount
  useEffect(() => {
    const checkAuth = async () => {
      try {
        const token = localStorage.getItem('access_token')
        if (token) {
          const userData = await api.getCurrentUser()
          setUser({
            id: userData.id,
            name: userData.name,
            email: userData.email,
            role: userData.role as UserRole,
          })
        }
      } catch (error) {
        // Token is invalid or expired, clear it
        localStorage.removeItem('access_token')
      } finally {
        setLoading(false)
      }
    }

    checkAuth()
  }, [])

  const signup = async (name: string, email: string, password: string) => {
    try {
      const response = await api.signup({ name, email, password })
      setUser({
        id: response.user.id,
        name: response.user.name,
        email: response.user.email,
        role: response.user.role as UserRole,
      })
    } catch (error) {
      throw error
    }
  }

  const login = async (email: string, password: string, role: UserRole) => {
    try {
      const response = await api.login({ email, password, role })
      setUser({
        id: response.user.id,
        name: response.user.name,
        email: response.user.email,
        role: response.user.role as UserRole,
      })
    } catch (error) {
      throw new Error('Login failed. Please check your credentials.')
    }
  }

  const logout = async () => {
    try {
      await api.logout()
    } catch (error) {
      // Ignore logout errors
      console.error('Logout error:', error)
    } finally {
      setUser(null)
    }
  }

  return (
    <AuthContext.Provider value={{
      user,
      signup,
      login,
      logout,
      isAuthenticated: !!user,
      loading,
    }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
