import { useState, useEffect } from 'react'
import { AppointmentCard } from '../components/AppointmentCard'
import type { Appointment, Comment } from '../components/AppointmentCard'
import { useAuth } from '../contexts/AuthContext'
import { Plus, Filter, Calendar as CalendarIcon, Sparkles, Database, TestTube } from 'lucide-react'
import { api } from '../lib/api'

// Mock data for testing
const MOCK_APPOINTMENTS: Appointment[] = [
  {
    id: '1',
    patientName: 'John Doe',
    doctorName: 'Smith',
    date: '2024-01-15',
    time: '10:00 AM',
    status: 'scheduled',
    reason: 'Annual checkup',
    comments: [
      {
        id: 'c1',
        userId: '1',
        userName: 'Dr. Smith',
        userRole: 'doctor',
        content: 'Patient has been regular with checkups. Review previous reports before appointment.',
        timestamp: new Date('2024-01-10')
      }
    ]
  },
  {
    id: '2',
    patientName: 'Jane Smith',
    doctorName: 'Johnson',
    date: '2024-01-15',
    time: '2:00 PM',
    status: 'scheduled',
    reason: 'Follow-up consultation',
    comments: []
  },
  {
    id: '3',
    patientName: 'Bob Wilson',
    doctorName: 'Smith',
    date: '2024-01-14',
    time: '11:30 AM',
    status: 'completed',
    reason: 'Blood pressure check',
    comments: []
  }
]

export function Schedule() {
  const { user } = useAuth()
  const [useMockData, setUseMockData] = useState(false)
  const [appointments, setAppointments] = useState<Appointment[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [showNewAppointmentForm, setShowNewAppointmentForm] = useState(false)
  const [filterStatus, setFilterStatus] = useState<string>('all')

  // Transform API response to match component format
  const transformAppointment = (apiAppointment: any): Appointment => ({
    id: apiAppointment.id,
    patientName: apiAppointment.patient_name,
    doctorName: apiAppointment.doctor_name,
    date: apiAppointment.date,
    time: apiAppointment.time,
    reason: apiAppointment.reason,
    status: apiAppointment.status as 'scheduled' | 'completed' | 'cancelled',
    comments: apiAppointment.comments || []
  })

  // Fetch appointments from API or use mock data
  useEffect(() => {
    const fetchAppointments = async () => {
      if (useMockData) {
        setAppointments(MOCK_APPOINTMENTS)
        setError(null)
        return
      }

      try {
        setLoading(true)
        setError(null)
        const data = await api.getAppointments()
        const transformedData = data.map(transformAppointment)
        setAppointments(transformedData)
      } catch (err) {
        console.error('Failed to fetch appointments:', err)
        setError('Failed to load appointments from server. Using mock data.')
        setAppointments(MOCK_APPOINTMENTS)
      } finally {
        setLoading(false)
      }
    }

    fetchAppointments()
  }, [useMockData])

  const [newAppointment, setNewAppointment] = useState({
    patientName: '',
    doctorName: '',
    date: '',
    time: '',
    reason: ''
  })

  const canCreateAppointment = user?.role === 'doctor' || user?.role === 'receptionist'

  const handleAddComment = (appointmentId: string, commentContent: string) => {
    if (!user) return

    const newComment: Comment = {
      id: Date.now().toString(),
      userId: user.id,
      userName: user.name,
      userRole: user.role,
      content: commentContent,
      timestamp: new Date()
    }

    setAppointments(appointments.map(apt =>
      apt.id === appointmentId
        ? { ...apt, comments: [...apt.comments, newComment] }
        : apt
    ))
  }

  const handleDeleteAppointment = (appointmentId: string) => {
    if (confirm('Are you sure you want to delete this appointment?')) {
      setAppointments(appointments.filter(apt => apt.id !== appointmentId))
    }
  }

  const handleCreateAppointment = () => {
    if (!newAppointment.patientName || !newAppointment.doctorName || !newAppointment.date || !newAppointment.time) {
      alert('Please fill in all required fields')
      return
    }

    const appointment: Appointment = {
      id: Date.now().toString(),
      ...newAppointment,
      status: 'scheduled',
      comments: []
    }

    setAppointments([appointment, ...appointments])
    setNewAppointment({
      patientName: '',
      doctorName: '',
      date: '',
      time: '',
      reason: ''
    })
    setShowNewAppointmentForm(false)
  }

  const filteredAppointments = filterStatus === 'all'
    ? appointments
    : appointments.filter(apt => apt.status === filterStatus)

  return (
    <div className="min-h-screen bg-gray-950 relative overflow-hidden">
      {/* Animated background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-1/4 w-96 h-96 bg-blue-500/5 rounded-full blur-3xl animate-pulse-slow"></div>
        <div className="absolute bottom-1/4 left-1/4 w-80 h-80 bg-purple-500/5 rounded-full blur-3xl animate-pulse-slow" style={{ animationDelay: '1s' }}></div>
      </div>

      <div className="container mx-auto px-4 py-10 relative z-10">
        <div className="flex items-center justify-between mb-10 animate-fade-in">
          <div>
            <div className="flex items-center gap-3 mb-2">
              <div className="p-2 bg-blue-500/10 rounded-lg">
                <CalendarIcon className="w-8 h-8 text-blue-400" />
              </div>
              <h1 className="text-4xl font-bold text-white flex items-center gap-2">
                Appointment Schedule
                <Sparkles className="w-6 h-6 text-yellow-400 animate-pulse" />
              </h1>
            </div>
            <p className="text-gray-400 ml-14">
              {user?.role === 'patient'
                ? 'View your appointments and communicate with your healthcare team'
                : 'Manage patient appointments and schedules'}
            </p>
          </div>

          <div className="flex items-center gap-3">
            {canCreateAppointment && (
              <button
                onClick={() => setShowNewAppointmentForm(!showNewAppointmentForm)}
                className="flex items-center space-x-2 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white px-6 py-3 rounded-xl font-semibold transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-blue-500/50"
              >
                <Plus className="w-5 h-5" />
                <span>New Appointment</span>
              </button>
            )}
          </div>
        </div>

        {/* Data Source Toggle */}
        <div className="bg-gradient-to-br from-gray-900 to-gray-900/80 border border-gray-800/50 rounded-xl p-5 mb-6 backdrop-blur-sm shadow-xl animate-slide-up">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className={`p-2 rounded-lg ${useMockData ? 'bg-orange-500/10' : 'bg-green-500/10'}`}>
                {useMockData ? (
                  <TestTube className="w-5 h-5 text-orange-400" />
                ) : (
                  <Database className="w-5 h-5 text-green-400" />
                )}
              </div>
              <div>
                <h3 className="text-white font-semibold">
                  Data Source: {useMockData ? 'Mock Data' : 'Live Database'}
                </h3>
                <p className="text-gray-400 text-sm">
                  {useMockData
                    ? 'Using hardcoded sample appointments for testing'
                    : 'Connected to backend API - showing real appointments'}
                </p>
              </div>
            </div>
            <button
              onClick={() => setUseMockData(!useMockData)}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-lg font-semibold transition-all duration-300 transform hover:scale-105 ${
                useMockData
                  ? 'bg-green-600 hover:bg-green-700 text-white'
                  : 'bg-orange-600 hover:bg-orange-700 text-white'
              }`}
            >
              {useMockData ? (
                <>
                  <Database className="w-4 h-4" />
                  <span>Switch to Live Data</span>
                </>
              ) : (
                <>
                  <TestTube className="w-4 h-4" />
                  <span>Switch to Mock Data</span>
                </>
              )}
            </button>
          </div>
          {error && (
            <div className="mt-3 p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
              <p className="text-red-400 text-sm">{error}</p>
            </div>
          )}
        </div>

        {/* Filter Section */}
        <div className="bg-gradient-to-br from-gray-900 to-gray-900/80 border border-gray-800/50 rounded-xl p-5 mb-6 backdrop-blur-sm shadow-xl animate-slide-up">
          <div className="flex items-center space-x-4 flex-wrap gap-2">
            <div className="flex items-center gap-2 text-gray-400">
              <Filter className="w-5 h-5" />
              <span className="font-semibold">Filter:</span>
            </div>
            <div className="flex space-x-2 flex-wrap gap-2">
              {['all', 'scheduled', 'completed', 'cancelled'].map((status) => (
                <button
                  key={status}
                  onClick={() => setFilterStatus(status)}
                  className={`px-5 py-2 rounded-lg text-sm font-semibold transition-all duration-300 transform hover:scale-105 ${
                    filterStatus === status
                      ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg'
                      : 'bg-gray-800/50 text-gray-400 hover:text-white hover:bg-gray-700/50 border border-gray-700'
                  }`}
                >
                  {status.charAt(0).toUpperCase() + status.slice(1)}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* New Appointment Form */}
        {showNewAppointmentForm && canCreateAppointment && (
          <div className="bg-gradient-to-br from-gray-900 to-gray-900/80 border border-gray-800/50 rounded-2xl p-8 mb-6 backdrop-blur-sm shadow-2xl animate-slide-up">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center gap-2">
              <Plus className="w-6 h-6 text-blue-400" />
              Create New Appointment
            </h2>
            <div className="grid grid-cols-2 gap-5">
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Patient Name
                </label>
                <input
                  type="text"
                  value={newAppointment.patientName}
                  onChange={(e) => setNewAppointment({ ...newAppointment, patientName: e.target.value })}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                  placeholder="Enter patient name"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Doctor Name
                </label>
                <input
                  type="text"
                  value={newAppointment.doctorName}
                  onChange={(e) => setNewAppointment({ ...newAppointment, doctorName: e.target.value })}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                  placeholder="Enter doctor name"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Date
                </label>
                <input
                  type="date"
                  value={newAppointment.date}
                  onChange={(e) => setNewAppointment({ ...newAppointment, date: e.target.value })}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Time
                </label>
                <input
                  type="time"
                  value={newAppointment.time}
                  onChange={(e) => setNewAppointment({ ...newAppointment, time: e.target.value })}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                />
              </div>

              <div className="col-span-2">
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Reason for Visit
                </label>
                <textarea
                  value={newAppointment.reason}
                  onChange={(e) => setNewAppointment({ ...newAppointment, reason: e.target.value })}
                  rows={3}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                  placeholder="Enter reason for visit..."
                />
              </div>
            </div>

            <div className="flex space-x-3 mt-6">
              <button
                onClick={handleCreateAppointment}
                className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white px-8 py-3 rounded-xl font-semibold transition-all duration-300 transform hover:scale-105 shadow-lg"
              >
                Create Appointment
              </button>
              <button
                onClick={() => setShowNewAppointmentForm(false)}
                className="bg-gray-800/50 hover:bg-gray-700/50 text-white px-8 py-3 rounded-xl font-semibold transition-all duration-300 border border-gray-700"
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Appointments List */}
        <div className="space-y-5">
          {loading ? (
            <div className="bg-gradient-to-br from-gray-900 to-gray-900/80 border border-gray-800/50 rounded-2xl p-16 text-center backdrop-blur-sm shadow-2xl animate-slide-up">
              <div className="w-16 h-16 border-4 border-blue-500/30 border-t-blue-500 rounded-full animate-spin mx-auto mb-4"></div>
              <p className="text-gray-400 text-xl font-semibold">Loading appointments...</p>
            </div>
          ) : filteredAppointments.length > 0 ? (
            filteredAppointments.map((appointment, index) => (
              <div key={appointment.id} style={{ animationDelay: `${index * 0.1}s` }}>
                <AppointmentCard
                  appointment={appointment}
                  onAddComment={handleAddComment}
                  onDelete={canCreateAppointment ? handleDeleteAppointment : undefined}
                  onEdit={canCreateAppointment ? (id) => console.log('Edit', id) : undefined}
                />
              </div>
            ))
          ) : (
            <div className="bg-gradient-to-br from-gray-900 to-gray-900/80 border border-gray-800/50 rounded-2xl p-16 text-center backdrop-blur-sm shadow-2xl animate-slide-up">
              <CalendarIcon className="w-16 h-16 text-gray-700 mx-auto mb-4" />
              <p className="text-gray-400 text-xl font-semibold">No appointments found</p>
              {canCreateAppointment && (
                <p className="text-gray-600 text-sm mt-2">
                  Click "New Appointment" to create one
                </p>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
