import { useState, useRef } from 'react'
import { Upload, Send, FileText, MessageSquare, X, Sparkles, CheckCircle } from 'lucide-react'

interface Message {
  id: string
  type: 'user' | 'ai'
  content: string
  timestamp: Date
}

export function AINurse() {
  const [file, setFile] = useState<File | null>(null)
  const [analyzing, setAnalyzing] = useState(false)
  const [messages, setMessages] = useState<Message[]>([])
  const [inputMessage, setInputMessage] = useState('')
  const [showChat, setShowChat] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0]
    if (selectedFile) {
      setFile(selectedFile)
      analyzeReport(selectedFile)
    }
  }

  const analyzeReport = async (file: File) => {
    setAnalyzing(true)
    setShowChat(true)

    // Simulate AI analysis
    await new Promise(resolve => setTimeout(resolve, 2000))

    const aiMessage: Message = {
      id: Date.now().toString(),
      type: 'ai',
      content: `I've analyzed your health report "${file.name}". Here's a summary:\n\n✓ Overall health indicators appear normal\n✓ Blood pressure: Within healthy range\n✓ Cholesterol levels: Slightly elevated - consider dietary changes\n\nWould you like me to explain any specific values or provide recommendations?`,
      timestamp: new Date()
    }

    setMessages([aiMessage])
    setAnalyzing(false)
  }

  const handleSendMessage = () => {
    if (!inputMessage.trim()) return

    const userMessage: Message = {
      id: Date.now().toString(),
      type: 'user',
      content: inputMessage,
      timestamp: new Date()
    }

    setMessages([...messages, userMessage])
    setInputMessage('')

    // Simulate AI response
    setTimeout(() => {
      const aiMessage: Message = {
        id: (Date.now() + 1).toString(),
        type: 'ai',
        content: `I understand your question about "${inputMessage}". Based on your health report, I recommend consulting with your healthcare provider for personalized advice. In the meantime, maintaining a balanced diet and regular exercise can help improve overall health markers.`,
        timestamp: new Date()
      }
      setMessages(prev => [...prev, aiMessage])
    }, 1000)
  }

  return (
    <div className="relative group">
      {/* Gradient background effect */}
      <div className="absolute inset-0 bg-gradient-to-r from-blue-600/10 to-purple-600/10 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300"></div>

      <div className="relative bg-gradient-to-br from-gray-900 to-gray-900/80 rounded-2xl p-8 border border-gray-800/50 backdrop-blur-sm shadow-2xl hover:border-blue-700/50 transition-all duration-300">
        <div className="flex items-center space-x-3 mb-6">
          <div className="relative">
            <div className="absolute inset-0 bg-blue-500/20 rounded-xl blur-md"></div>
            <div className="relative bg-gradient-to-br from-blue-600 to-blue-700 p-3 rounded-xl shadow-lg">
              <FileText className="w-6 h-6 text-white" />
            </div>
          </div>
          <div>
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              AI Nurse Assistant
              <Sparkles className="w-5 h-5 text-yellow-400" />
            </h2>
            <p className="text-gray-400">Upload your health report for instant analysis</p>
          </div>
        </div>

        <div className="space-y-4">
          <div
            onClick={() => fileInputRef.current?.click()}
            className="relative border-2 border-dashed border-gray-700 rounded-xl p-10 text-center hover:border-blue-500 hover:bg-blue-500/5 transition-all duration-300 cursor-pointer group/upload overflow-hidden"
          >
            {/* Animated gradient border on hover */}
            <div className="absolute inset-0 bg-gradient-to-r from-blue-500/0 via-blue-500/10 to-purple-500/0 opacity-0 group-hover/upload:opacity-100 transition-opacity duration-300"></div>

            <div className="relative z-10">
              <div className="inline-block p-4 bg-blue-500/10 rounded-full mb-4 group-hover/upload:scale-110 transition-transform duration-300">
                <Upload className="w-10 h-10 text-blue-500 group-hover/upload:text-blue-400 transition-colors" />
              </div>

              {file ? (
                <div className="space-y-2">
                  <div className="flex items-center justify-center gap-2 text-green-400">
                    <CheckCircle className="w-5 h-5" />
                    <p className="font-semibold">{file.name}</p>
                  </div>
                  <p className="text-sm text-gray-500">Click to upload a different file</p>
                </div>
              ) : (
                <>
                  <p className="text-gray-300 mb-2 font-medium text-lg">Click to upload health report</p>
                  <p className="text-sm text-gray-500">
                    Supports PDF, JPG, PNG (Max 10MB)
                  </p>
                </>
              )}
            </div>

            <input
              ref={fileInputRef}
              type="file"
              onChange={handleFileUpload}
              accept=".pdf,.jpg,.jpeg,.png"
              className="hidden"
            />
          </div>

          {analyzing && (
            <div className="bg-gradient-to-r from-blue-900/30 to-purple-900/30 border border-blue-700/50 rounded-xl p-4 backdrop-blur-sm animate-slide-up">
              <div className="flex items-center space-x-3">
                <div className="relative">
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-t-2 border-blue-500"></div>
                  <div className="absolute inset-0 rounded-full bg-blue-500/20 blur-sm"></div>
                </div>
                <span className="text-blue-300 font-medium">Analyzing your health report...</span>
              </div>
            </div>
          )}

          {showChat && messages.length > 0 && (
            <div className="bg-gradient-to-br from-gray-800/80 to-gray-900/80 rounded-xl p-5 border border-gray-700/50 backdrop-blur-sm shadow-xl animate-slide-up">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center space-x-2">
                  <div className="p-2 bg-blue-500/10 rounded-lg">
                    <MessageSquare className="w-5 h-5 text-blue-400" />
                  </div>
                  <h3 className="text-lg font-semibold text-white">Chat with AI Nurse</h3>
                </div>
                <button
                  onClick={() => setShowChat(false)}
                  className="text-gray-400 hover:text-white hover:bg-gray-700/50 p-1 rounded-lg transition-all duration-200"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="space-y-3 max-h-64 overflow-y-auto mb-4 pr-2">
                {messages.map((message) => (
                  <div
                    key={message.id}
                    className={`flex ${message.type === 'user' ? 'justify-end' : 'justify-start'} animate-slide-up`}
                  >
                    <div
                      className={`max-w-[80%] rounded-xl p-4 shadow-lg ${
                        message.type === 'user'
                          ? 'bg-gradient-to-r from-blue-600 to-blue-700 text-white'
                          : 'bg-gradient-to-br from-gray-700 to-gray-800 text-gray-100 border border-gray-600/50'
                      }`}
                    >
                      <p className="text-sm whitespace-pre-wrap leading-relaxed">{message.content}</p>
                      <p className="text-xs mt-2 opacity-60">
                        {new Date(message.timestamp).toLocaleTimeString()}
                      </p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="flex space-x-2">
                <input
                  type="text"
                  value={inputMessage}
                  onChange={(e) => setInputMessage(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
                  placeholder="Ask a question about your report..."
                  className="flex-1 bg-gray-900/50 border border-gray-700 rounded-xl px-4 py-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-300 hover:border-gray-600"
                />
                <button
                  onClick={handleSendMessage}
                  disabled={!inputMessage.trim()}
                  className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 disabled:from-gray-700 disabled:to-gray-700 disabled:cursor-not-allowed text-white p-3 rounded-xl transition-all duration-300 transform hover:scale-105 active:scale-95 shadow-lg"
                >
                  <Send className="w-5 h-5" />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
