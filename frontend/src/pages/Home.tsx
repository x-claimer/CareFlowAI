import { AINurse } from '../components/AINurse'
import { AITutor } from '../components/AITutor'
import { Footer } from '../components/Footer'
import { ArrowRight, Sparkles, Calendar, Bot, GraduationCap } from 'lucide-react'
import { useAuth } from '../contexts/AuthContext'
import { Link } from 'react-router-dom'

export function Home() {
  const { isAuthenticated } = useAuth()

  return (
    <div className="min-h-screen bg-gray-950 relative overflow-hidden">
      {/* Animated background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-blue-500/5 rounded-full blur-3xl animate-pulse-slow"></div>
        <div className="absolute top-1/3 right-1/4 w-80 h-80 bg-purple-500/5 rounded-full blur-3xl animate-pulse-slow" style={{ animationDelay: '1s' }}></div>
        <div className="absolute bottom-1/4 left-1/3 w-72 h-72 bg-pink-500/5 rounded-full blur-3xl animate-pulse-slow" style={{ animationDelay: '2s' }}></div>
      </div>

      {/* Hero Section */}
      <div className="relative bg-gradient-to-br from-blue-900/30 via-purple-900/20 to-gray-900/40 border-b border-gray-800/50 backdrop-blur-sm">
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxwYXRoIGQ9Ik0zNiAxOGMwLTkuOTQtOC4wNi0xOC0xOC0xOCIgc3Ryb2tlPSJyZ2JhKDU5LDEzMCwyNDYsMC4xKSIgc3Ryb2tlLXdpZHRoPSIxIi8+PC9nPjwvc3ZnPg==')] opacity-40"></div>
        <div className="container mx-auto px-4 py-20 relative z-10">
          <div className="max-w-4xl mx-auto text-center animate-fade-in">
            <div className="inline-flex items-center gap-2 bg-blue-500/10 border border-blue-500/20 rounded-full px-4 py-2 mb-6 backdrop-blur-sm">
              <Sparkles className="w-4 h-4 text-blue-400 animate-pulse" />
              <span className="text-blue-300 text-sm font-medium">AI-Powered Healthcare Platform</span>
            </div>

            <h1 className="text-6xl font-bold text-white mb-6 leading-tight">
              Your{' '}
              <span className="bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent animate-pulse-slow">
                AI-Powered
              </span>
              <br />
              Healthcare Companion
            </h1>

            <p className="text-xl text-gray-300 mb-10 leading-relaxed">
              Intelligent appointment scheduling, health report analysis, and medical knowledge at your fingertips.
              Experience the future of healthcare management.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              {!isAuthenticated ? (
                <>
                  <Link
                    to="/login"
                    className="group inline-flex items-center justify-center space-x-2 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-blue-500/50"
                  >
                    <span>Get Started</span>
                    <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                  </Link>
                  <button className="inline-flex items-center justify-center space-x-2 bg-gray-800/50 hover:bg-gray-700/50 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 backdrop-blur-sm border border-gray-700">
                    <span>Learn More</span>
                  </button>
                </>
              ) : (
                <Link
                  to="/schedule"
                  className="group inline-flex items-center justify-center space-x-2 bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white px-8 py-4 rounded-xl font-semibold text-lg transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-blue-500/50"
                >
                  <Calendar className="w-5 h-5" />
                  <span>View Schedule</span>
                  <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                </Link>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-16 relative z-10">
        <div className="space-y-16">
          {/* AI Nurse Section */}
          <div className="animate-slide-up">
            <AINurse />
          </div>

          {/* AI Tutor Section */}
          <div className="animate-slide-up" style={{ animationDelay: '0.2s' }}>
            <AITutor />
          </div>

          {/* Features Grid */}
          <div className="animate-slide-up" style={{ animationDelay: '0.4s' }}>
            <h2 className="text-3xl font-bold text-center text-white mb-12">
              Why Choose{' '}
              <span className="bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                CareFlowAI
              </span>
            </h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="group bg-gradient-to-br from-blue-900/20 to-blue-800/10 border border-blue-700/30 rounded-2xl p-8 hover:border-blue-500/50 transition-all duration-300 hover:transform hover:scale-105 hover:shadow-xl hover:shadow-blue-500/20 backdrop-blur-sm">
                <div className="bg-gradient-to-br from-blue-600 to-blue-700 w-14 h-14 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg">
                  <Calendar className="w-7 h-7 text-white" />
                </div>
                <h3 className="text-2xl font-bold text-white mb-3">Smart Scheduling</h3>
                <p className="text-gray-400 leading-relaxed">
                  Intelligent appointment management with role-based access for doctors, receptionists, and patients. Stay organized effortlessly.
                </p>
              </div>

              <div className="group bg-gradient-to-br from-green-900/20 to-green-800/10 border border-green-700/30 rounded-2xl p-8 hover:border-green-500/50 transition-all duration-300 hover:transform hover:scale-105 hover:shadow-xl hover:shadow-green-500/20 backdrop-blur-sm">
                <div className="bg-gradient-to-br from-green-600 to-green-700 w-14 h-14 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg">
                  <Bot className="w-7 h-7 text-white" />
                </div>
                <h3 className="text-2xl font-bold text-white mb-3">AI Analysis</h3>
                <p className="text-gray-400 leading-relaxed">
                  Upload health reports and get instant AI-powered insights and explanations. Understand your health better.
                </p>
              </div>

              <div className="group bg-gradient-to-br from-purple-900/20 to-purple-800/10 border border-purple-700/30 rounded-2xl p-8 hover:border-purple-500/50 transition-all duration-300 hover:transform hover:scale-105 hover:shadow-xl hover:shadow-purple-500/20 backdrop-blur-sm">
                <div className="bg-gradient-to-br from-purple-600 to-purple-700 w-14 h-14 rounded-xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform shadow-lg">
                  <GraduationCap className="w-7 h-7 text-white" />
                </div>
                <h3 className="text-2xl font-bold text-white mb-3">Health Education</h3>
                <p className="text-gray-400 leading-relaxed">
                  Learn about medical terminology and health concepts with our AI tutor. Knowledge is power.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <Footer />
    </div>
  )
}
