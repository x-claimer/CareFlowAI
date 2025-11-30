import { useState, useEffect } from 'react'
import { AppointmentCard } from '../components/AppointmentCard'
import type { Appointment, Comment } from '../components/AppointmentCard'
import { useAuth } from '../contexts/AuthContext'
import { Plus, Filter, Calendar as CalendarIcon, Sparkles, Database, TestTube, Users, UserPlus } from 'lucide-react'
import { api } from '../lib/api'
import type { User } from '../lib/api'

export function Schedule() {
  const { user } = useAuth()
  const [useMockData, setUseMockData] = useState(false)
  const [appointments, setAppointments] = useState<Appointment[]>([])
  const [users, setUsers] = useState<User[]>([])
  const [patients, setPatients] = useState<User[]>([])
  const [doctors, setDoctors] = useState<User[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [showNewAppointmentForm, setShowNewAppointmentForm] = useState(false)
  const [showNewUserForm, setShowNewUserForm] = useState(false)
  const [filterStatus, setFilterStatus] = useState<string>('all')
  const [filterPatient, setFilterPatient] = useState<string>('')
  const [filterDoctor, setFilterDoctor] = useState<string>('')

  // Transform API response to match component format
  const transformAppointment = (apiAppointment: any): Appointment => ({
    id: apiAppointment.id,
    patientId: apiAppointment.patient_id,
    patientName: apiAppointment.patient_name,
    doctorId: apiAppointment.doctor_id,
    doctorName: apiAppointment.doctor_name,
    date: apiAppointment.date,
    time: apiAppointment.time,
    reason: apiAppointment.reason,
    status: apiAppointment.status as 'scheduled' | 'completed' | 'cancelled',
    comments: (apiAppointment.comments || []).map((comment: any) => ({
      id: comment.id,
      userId: comment.user_id,
      userName: comment.user_name,
      userRole: comment.user_role,
      content: comment.content,
      timestamp: new Date(comment.timestamp)
    }))
  })

  // Fetch users for dropdowns
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const allUsers = await api.getUsers()
        setUsers(allUsers)
        setPatients(allUsers.filter(u => u.role === 'patient'))
        setDoctors(allUsers.filter(u => u.role === 'doctor'))
      } catch (err) {
        console.error('Failed to fetch users:', err)
      }
    }

    if (!useMockData) {
      fetchUsers()
    }
  }, [useMockData])

  // Fetch appointments from API
  useEffect(() => {
    const fetchAppointments = async () => {
      if (useMockData) {
        setAppointments([])
        setError(null)
        return
      }

      try {
        setLoading(true)
        setError(null)

        const statusFilter = filterStatus === 'all' ? undefined : filterStatus
        const patientFilter = filterPatient || undefined
        const doctorFilter = filterDoctor || undefined

        const data = await api.getAppointments(statusFilter, patientFilter, doctorFilter)
        const transformedData = data.map(transformAppointment)
        setAppointments(transformedData)
      } catch (err: any) {
        console.error('Failed to fetch appointments:', err)
        setError(err.message || 'Failed to load appointments from server.')
        setAppointments([])
      } finally {
        setLoading(false)
      }
    }

    fetchAppointments()
  }, [useMockData, filterStatus, filterPatient, filterDoctor])

  const [newAppointment, setNewAppointment] = useState({
    patientId: '',
    patientName: '',
    doctorId: '',
    doctorName: '',
    date: '',
    time: '',
    reason: ''
  })

  const [newUser, setNewUser] = useState({
    name: '',
    email: '',
    password: '',
    role: 'patient' as 'patient' | 'doctor' | 'receptionist' | 'admin'
  })

  const canCreateAppointment = user?.role === 'doctor' || user?.role === 'receptionist' || user?.role === 'admin'
  const canManageUsers = user?.role === 'admin'
  const canFilterByPatient = user?.role === 'doctor' || user?.role === 'receptionist' || user?.role === 'admin'
  const canFilterByDoctor = user?.role === 'receptionist' || user?.role === 'admin'

  const handleAddComment = async (appointmentId: string, commentContent: string) => {
    if (!user) return

    try {
      await api.addComment(appointmentId, commentContent)

      // Refresh appointments
      const statusFilter = filterStatus === 'all' ? undefined : filterStatus
      const patientFilter = filterPatient || undefined
      const doctorFilter = filterDoctor || undefined
      const data = await api.getAppointments(statusFilter, patientFilter, doctorFilter)
      const transformedData = data.map(transformAppointment)
      setAppointments(transformedData)
    } catch (err) {
      console.error('Failed to add comment:', err)
      alert('Failed to add comment')
    }
  }

  const handleDeleteAppointment = async (appointmentId: string) => {
    if (!confirm('Are you sure you want to delete this appointment?')) return

    try {
      await api.deleteAppointment(appointmentId)
      setAppointments(appointments.filter(apt => apt.id !== appointmentId))
    } catch (err) {
      console.error('Failed to delete appointment:', err)
      alert('Failed to delete appointment')
    }
  }

  const handleCreateAppointment = async () => {
    if (!newAppointment.patientId || !newAppointment.doctorId || !newAppointment.date || !newAppointment.time) {
      alert('Please fill in all required fields')
      return
    }

    try {
      await api.createAppointment({
        patient_id: newAppointment.patientId,
        patient_name: newAppointment.patientName,
        doctor_id: newAppointment.doctorId,
        doctor_name: newAppointment.doctorName,
        date: newAppointment.date,
        time: newAppointment.time,
        reason: newAppointment.reason
      })

      // Refresh appointments
      const statusFilter = filterStatus === 'all' ? undefined : filterStatus
      const patientFilter = filterPatient || undefined
      const doctorFilter = filterDoctor || undefined
      const data = await api.getAppointments(statusFilter, patientFilter, doctorFilter)
      const transformedData = data.map(transformAppointment)
      setAppointments(transformedData)

      setNewAppointment({
        patientId: '',
        patientName: '',
        doctorId: '',
        doctorName: '',
        date: '',
        time: '',
        reason: ''
      })
      setShowNewAppointmentForm(false)
    } catch (err) {
      console.error('Failed to create appointment:', err)
      alert('Failed to create appointment')
    }
  }

  const handleCreateUser = async () => {
    if (!newUser.name || !newUser.email || !newUser.password || !newUser.role) {
      alert('Please fill in all required fields')
      return
    }

    try {
      await api.createUser(newUser)

      // Refresh users
      const allUsers = await api.getUsers()
      setUsers(allUsers)
      setPatients(allUsers.filter(u => u.role === 'patient'))
      setDoctors(allUsers.filter(u => u.role === 'doctor'))

      setNewUser({
        name: '',
        email: '',
        password: '',
        role: 'patient'
      })
      setShowNewUserForm(false)
      alert('User created successfully!')
    } catch (err) {
      console.error('Failed to create user:', err)
      alert('Failed to create user')
    }
  }

  const handlePatientSelect = (patientId: string) => {
    const patient = patients.find(p => p.id === patientId)
    if (patient) {
      setNewAppointment({
        ...newAppointment,
        patientId: patient.id,
        patientName: patient.name
      })
    }
  }

  const handleDoctorSelect = (doctorId: string) => {
    const doctor = doctors.find(d => d.id === doctorId)
    if (doctor) {
      setNewAppointment({
        ...newAppointment,
        doctorId: doctor.id,
        doctorName: doctor.name
      })
    }
  }

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
              {user?.role === 'patient' && 'View your appointments and communicate with your healthcare team'}
              {user?.role === 'doctor' && 'View appointments for your patients across all doctors'}
              {user?.role === 'receptionist' && 'Manage all patient appointments and schedules'}
              {user?.role === 'admin' && 'Full access to manage appointments and user roles'}
            </p>
          </div>

          <div className="flex items-center gap-3">
            {canManageUsers && (
              <button
                onClick={() => setShowNewUserForm(!showNewUserForm)}
                className="flex items-center space-x-2 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white px-6 py-3 rounded-xl font-semibold transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-green-500/50"
              >
                <UserPlus className="w-5 h-5" />
                <span>New User</span>
              </button>
            )}
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
          <div className="space-y-4">
            {/* Status Filter */}
            <div className="flex items-center space-x-4 flex-wrap gap-2">
              <div className="flex items-center gap-2 text-gray-400">
                <Filter className="w-5 h-5" />
                <span className="font-semibold">Status:</span>
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

            {/* Patient Filter (for Doctor, Receptionist, Admin) */}
            {canFilterByPatient && (
              <div className="flex items-center space-x-4 flex-wrap gap-2">
                <div className="flex items-center gap-2 text-gray-400">
                  <Users className="w-5 h-5" />
                  <span className="font-semibold">Patient:</span>
                </div>
                <select
                  value={filterPatient}
                  onChange={(e) => setFilterPatient(e.target.value)}
                  className="bg-gray-900/50 border border-gray-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                >
                  <option value="">All Patients</option>
                  {patients.map(patient => (
                    <option key={patient.id} value={patient.id}>{patient.name}</option>
                  ))}
                </select>
              </div>
            )}

            {/* Doctor Filter (for Receptionist, Admin) */}
            {canFilterByDoctor && (
              <div className="flex items-center space-x-4 flex-wrap gap-2">
                <div className="flex items-center gap-2 text-gray-400">
                  <Users className="w-5 h-5" />
                  <span className="font-semibold">Doctor:</span>
                </div>
                <select
                  value={filterDoctor}
                  onChange={(e) => setFilterDoctor(e.target.value)}
                  className="bg-gray-900/50 border border-gray-700 rounded-lg px-4 py-2 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                >
                  <option value="">All Doctors</option>
                  {doctors.map(doctor => (
                    <option key={doctor.id} value={doctor.id}>{doctor.name}</option>
                  ))}
                </select>
              </div>
            )}
          </div>
        </div>

        {/* New User Form (Admin only) */}
        {showNewUserForm && canManageUsers && (
          <div className="bg-gradient-to-br from-gray-900 to-gray-900/80 border border-gray-800/50 rounded-2xl p-8 mb-6 backdrop-blur-sm shadow-2xl animate-slide-up">
            <h2 className="text-2xl font-bold text-white mb-6 flex items-center gap-2">
              <UserPlus className="w-6 h-6 text-green-400" />
              Create New User
            </h2>
            <div className="grid grid-cols-2 gap-5">
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Name
                </label>
                <input
                  type="text"
                  value={newUser.name}
                  onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-green-500 transition-all duration-300 hover:border-gray-600"
                  placeholder="Enter name"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Email
                </label>
                <input
                  type="email"
                  value={newUser.email}
                  onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-green-500 transition-all duration-300 hover:border-gray-600"
                  placeholder="Enter email"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Password
                </label>
                <input
                  type="password"
                  value={newUser.password}
                  onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-green-500 transition-all duration-300 hover:border-gray-600"
                  placeholder="Enter password"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Role
                </label>
                <select
                  value={newUser.role}
                  onChange={(e) => setNewUser({ ...newUser, role: e.target.value as any })}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-green-500 transition-all duration-300 hover:border-gray-600"
                >
                  <option value="patient">Patient</option>
                  <option value="doctor">Doctor</option>
                  <option value="receptionist">Receptionist</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
            </div>

            <div className="flex space-x-3 mt-6">
              <button
                onClick={handleCreateUser}
                className="bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white px-8 py-3 rounded-xl font-semibold transition-all duration-300 transform hover:scale-105 shadow-lg"
              >
                Create User
              </button>
              <button
                onClick={() => setShowNewUserForm(false)}
                className="bg-gray-800/50 hover:bg-gray-700/50 text-white px-8 py-3 rounded-xl font-semibold transition-all duration-300 border border-gray-700"
              >
                Cancel
              </button>
            </div>
          </div>
        )}

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
                  Patient
                </label>
                <select
                  value={newAppointment.patientId}
                  onChange={(e) => handlePatientSelect(e.target.value)}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                >
                  <option value="">Select patient</option>
                  {patients.map(patient => (
                    <option key={patient.id} value={patient.id}>{patient.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Doctor
                </label>
                <select
                  value={newAppointment.doctorId}
                  onChange={(e) => handleDoctorSelect(e.target.value)}
                  className="w-full bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all duration-300 hover:border-gray-600"
                >
                  <option value="">Select doctor</option>
                  {doctors.map(doctor => (
                    <option key={doctor.id} value={doctor.id}>{doctor.name}</option>
                  ))}
                </select>
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
          ) : appointments.length > 0 ? (
            appointments.map((appointment, index) => (
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
