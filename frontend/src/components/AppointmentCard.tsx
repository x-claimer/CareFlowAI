import { useState } from 'react'
import { Calendar, Clock, User, MessageSquare, Send, Edit, Trash2 } from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'
import type { UserRole } from '../contexts/AuthContext'

export interface Appointment {
  id: string
  patientId: string
  patientName: string
  doctorId: string
  doctorName: string
  date: string
  time: string
  status: 'scheduled' | 'completed' | 'cancelled'
  reason: string
  comments: Comment[]
}

export interface Comment {
  id: string
  userId: string
  userName: string
  userRole: UserRole
  content: string
  timestamp: Date
}

interface AppointmentCardProps {
  appointment: Appointment
  onAddComment: (appointmentId: string, comment: string) => void
  onDelete?: (appointmentId: string) => void
  onEdit?: (appointmentId: string) => void
}

export function AppointmentCard({ appointment, onAddComment, onDelete, onEdit }: AppointmentCardProps) {
  const { user } = useAuth()
  const [showComments, setShowComments] = useState(false)
  const [newComment, setNewComment] = useState('')

  const canEdit = user?.role === 'doctor' || user?.role === 'receptionist' || user?.role === 'admin'
  const canComment = true // All authenticated users can comment

  const handleAddComment = () => {
    if (!newComment.trim()) return
    onAddComment(appointment.id, newComment)
    setNewComment('')
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'scheduled':
        return 'bg-blue-500/20 text-blue-300 border-blue-500/50'
      case 'completed':
        return 'bg-green-500/20 text-green-300 border-green-500/50'
      case 'cancelled':
        return 'bg-red-500/20 text-red-300 border-red-500/50'
      default:
        return 'bg-gray-500/20 text-gray-300 border-gray-500/50'
    }
  }

  const getRoleColor = (role: string) => {
    if (!role) return 'bg-gray-500/20 text-gray-400 border-gray-500/30'

    switch (role.toLowerCase()) {
      case 'doctor':
        return 'bg-blue-500/20 text-blue-400 border-blue-500/30'
      case 'patient':
        return 'bg-green-500/20 text-green-400 border-green-500/30'
      case 'receptionist':
        return 'bg-purple-500/20 text-purple-400 border-purple-500/30'
      case 'admin':
        return 'bg-red-500/20 text-red-400 border-red-500/30'
      default:
        return 'bg-gray-500/20 text-gray-400 border-gray-500/30'
    }
  }

  const getInitials = (name: string) => {
    if (!name) return '??'
    return name
      .split(' ')
      .filter(word => word.length > 0)
      .map(word => word[0])
      .join('')
      .toUpperCase()
      .slice(0, 2) || '??'
  }

  return (
    <div className="group relative animate-slide-up">
      {/* Gradient glow effect */}
      <div className="absolute inset-0 bg-gradient-to-r from-blue-600/5 to-purple-600/5 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300"></div>

      <div className="relative bg-gradient-to-br from-gray-900 to-gray-900/90 border border-gray-800/50 rounded-2xl p-6 hover:border-gray-700/50 transition-all duration-300 shadow-xl backdrop-blur-sm">
        <div className="flex items-start justify-between mb-4">
          <div className="flex-1">
            {/* Main Title: Appointment Reason */}
            <div className="flex items-center space-x-3 mb-3">
              <h3 className="text-2xl font-bold text-white">{appointment.reason}</h3>
              <span className={`px-3 py-1 rounded-full text-xs font-semibold border backdrop-blur-sm ${getStatusColor(appointment.status)}`}>
                {appointment.status.toUpperCase()}
              </span>
            </div>

            {/* Secondary Info: Patient and Doctor */}
            <div className="grid grid-cols-2 gap-3 mb-4">
              <div className="flex items-center space-x-2 bg-gray-800/40 rounded-lg px-3 py-2 border border-gray-700/30">
                <User className="w-4 h-4 text-blue-400" />
                <div className="flex flex-col">
                  <span className="text-xs text-gray-500">Patient</span>
                  <span className="text-sm text-gray-300 font-medium">{appointment.patientName}</span>
                </div>
              </div>
              <div className="flex items-center space-x-2 bg-gray-800/40 rounded-lg px-3 py-2 border border-gray-700/30">
                <User className="w-4 h-4 text-purple-400" />
                <div className="flex flex-col">
                  <span className="text-xs text-gray-500">Doctor</span>
                  <span className="text-sm text-gray-300 font-medium">{appointment.doctorName}</span>
                </div>
              </div>
            </div>

            {/* Tertiary Info: Date, Time, Comments */}
            <div className="grid grid-cols-3 gap-3">
              <div className="flex items-center space-x-2 bg-gray-800/40 rounded-lg px-3 py-2 border border-gray-700/30">
                <Calendar className="w-4 h-4 text-green-400" />
                <span className="text-sm text-gray-300">{appointment.date}</span>
              </div>
              <div className="flex items-center space-x-2 bg-gray-800/40 rounded-lg px-3 py-2 border border-gray-700/30">
                <Clock className="w-4 h-4 text-yellow-400" />
                <span className="text-sm text-gray-300">{appointment.time}</span>
              </div>
              <div className="flex items-center space-x-2 bg-gray-800/40 rounded-lg px-3 py-2 border border-gray-700/30">
                <MessageSquare className="w-4 h-4 text-pink-400" />
                <span className="text-sm text-gray-300">{appointment.comments.length} comments</span>
              </div>
            </div>
          </div>

          {canEdit && (
            <div className="flex space-x-2 ml-4">
              {onEdit && (
                <button
                  onClick={() => onEdit(appointment.id)}
                  className="p-2 bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 rounded-lg border border-blue-500/30 hover:border-blue-500/50 transition-all duration-300 transform hover:scale-110"
                  title="Edit appointment"
                >
                  <Edit className="w-4 h-4" />
                </button>
              )}
              {onDelete && (
                <button
                  onClick={() => onDelete(appointment.id)}
                  className="p-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 rounded-lg border border-red-500/30 hover:border-red-500/50 transition-all duration-300 transform hover:scale-110"
                  title="Delete appointment"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              )}
            </div>
          )}
        </div>

        <div className="border-t border-gray-800/50 pt-4 mt-4">
          <button
            onClick={() => setShowComments(!showComments)}
            className="flex items-center space-x-2 text-blue-400 hover:text-blue-300 text-sm font-medium transition-all duration-300 group/btn"
          >
            <MessageSquare className="w-4 h-4 group-hover/btn:scale-110 transition-transform" />
            <span>{showComments ? 'Hide' : 'Show'} Comments</span>
          </button>

          {showComments && (
            <div className="mt-4 space-y-4 animate-slide-up">
              {appointment.comments.length > 0 ? (
                <div className="space-y-3 max-h-64 overflow-y-auto pr-2">
                  {appointment.comments.map((comment) => (
                    <div key={comment.id} className="bg-gray-800/60 rounded-lg p-4 border border-gray-700/50 hover:border-gray-600/50 transition-all duration-300 backdrop-blur-sm">
                      <div className="flex items-start gap-3">
                        {/* Avatar with initials */}
                        <div className="flex-shrink-0">
                          <div className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold text-xs ${getRoleColor(comment.userRole)}`}>
                            {getInitials(comment.userName)}
                          </div>
                        </div>

                        {/* Comment content */}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1 flex-wrap">
                            <span className="text-sm font-semibold text-white">{comment.userName || 'Unknown'}</span>
                            <span className={`px-2 py-0.5 rounded-full text-xs font-medium border ${getRoleColor(comment.userRole)}`}>
                              {comment.userRole ? comment.userRole.charAt(0).toUpperCase() + comment.userRole.slice(1) : 'User'}
                            </span>
                            <span className="text-xs text-gray-500">
                              {new Date(comment.timestamp).toLocaleString()}
                            </span>
                          </div>
                          <p className="text-sm text-gray-300 leading-relaxed break-words">{comment.content}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="bg-gray-800/30 border border-gray-700/30 rounded-lg p-6 text-center">
                  <MessageSquare className="w-8 h-8 text-gray-600 mx-auto mb-2" />
                  <p className="text-gray-500 text-sm italic">No comments yet. Be the first to comment!</p>
                </div>
              )}

              {canComment && (
                <div className="flex space-x-2 pt-2">
                  <input
                    type="text"
                    value={newComment}
                    onChange={(e) => setNewComment(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && handleAddComment()}
                    placeholder="Add a comment..."
                    className="flex-1 bg-gray-900/50 border border-gray-700 rounded-lg px-4 py-2 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm transition-all duration-300 hover:border-gray-600"
                  />
                  <button
                    onClick={handleAddComment}
                    disabled={!newComment.trim()}
                    className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 disabled:from-gray-700 disabled:to-gray-700 disabled:cursor-not-allowed text-white p-2 rounded-lg transition-all duration-300 transform hover:scale-105 active:scale-95 shadow-lg"
                  >
                    <Send className="w-4 h-4" />
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
