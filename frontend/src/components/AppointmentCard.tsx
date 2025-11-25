import { useState } from 'react'
import { Calendar, Clock, User, MessageSquare, Send, Edit, Trash2 } from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'
import type { UserRole } from '../contexts/AuthContext'

export interface Appointment {
  id: string
  patientName: string
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

  const canEdit = user?.role === 'doctor' || user?.role === 'receptionist'
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

  return (
    <div className="group relative animate-slide-up">
      {/* Gradient glow effect */}
      <div className="absolute inset-0 bg-gradient-to-r from-blue-600/5 to-purple-600/5 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300"></div>

      <div className="relative bg-gradient-to-br from-gray-900 to-gray-900/90 border border-gray-800/50 rounded-2xl p-6 hover:border-gray-700/50 transition-all duration-300 shadow-xl backdrop-blur-sm">
        <div className="flex items-start justify-between mb-4">
          <div className="flex-1">
            <div className="flex items-center space-x-3 mb-3">
              <h3 className="text-2xl font-bold text-white">{appointment.patientName}</h3>
              <span className={`px-3 py-1 rounded-full text-xs font-semibold border backdrop-blur-sm ${getStatusColor(appointment.status)}`}>
                {appointment.status.toUpperCase()}
              </span>
            </div>
            <p className="text-gray-400 text-sm mb-4 italic">{appointment.reason}</p>

            <div className="grid grid-cols-2 gap-3">
              <div className="flex items-center space-x-2 bg-gray-800/40 rounded-lg px-3 py-2 border border-gray-700/30">
                <User className="w-4 h-4 text-blue-400" />
                <span className="text-sm text-gray-300">Dr. {appointment.doctorName}</span>
              </div>
              <div className="flex items-center space-x-2 bg-gray-800/40 rounded-lg px-3 py-2 border border-gray-700/30">
                <Calendar className="w-4 h-4 text-purple-400" />
                <span className="text-sm text-gray-300">{appointment.date}</span>
              </div>
              <div className="flex items-center space-x-2 bg-gray-800/40 rounded-lg px-3 py-2 border border-gray-700/30">
                <Clock className="w-4 h-4 text-green-400" />
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
                <div className="space-y-3 max-h-48 overflow-y-auto pr-2">
                  {appointment.comments.map((comment) => (
                    <div key={comment.id} className="bg-gray-800/60 rounded-lg p-4 border border-gray-700/50 hover:border-gray-600/50 transition-all duration-300 backdrop-blur-sm">
                      <div className="flex items-center justify-between mb-2">
                        <div className="flex items-center gap-2">
                          <span className="text-sm font-semibold text-white">{comment.userName}</span>
                          <span className="px-2 py-0.5 bg-purple-500/20 text-purple-400 rounded-full text-xs font-medium border border-purple-500/30">
                            {comment.userRole}
                          </span>
                        </div>
                        <span className="text-xs text-gray-500">
                          {new Date(comment.timestamp).toLocaleString()}
                        </span>
                      </div>
                      <p className="text-sm text-gray-300 leading-relaxed">{comment.content}</p>
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
