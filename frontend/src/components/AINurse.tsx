import { useState, useRef } from 'react'
import {
  Upload,
  FileText,
  Sparkles,
  CheckCircle,
  Activity,
  Heart,
  TrendingUp,
  AlertCircle,
  Info,
  Droplet,
  Weight,
  Zap
} from 'lucide-react'
import { api } from '../lib/api'

interface HealthMetric {
  name: string
  value: string
  unit: string
  status: 'normal' | 'warning' | 'critical'
  reference_range: string
  interpretation: string
}

interface AnalysisResult {
  analysis: string
  summary: string
  file_name: string
  metrics: HealthMetric[]
  recommendations: string[]
}

export function AINurse() {
  const [file, setFile] = useState<File | null>(null)
  const [analyzing, setAnalyzing] = useState(false)
  const [result, setResult] = useState<AnalysisResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [filePreview, setFilePreview] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0]
    if (selectedFile) {
      setFile(selectedFile)

      // Create preview for images
      if (selectedFile.type.startsWith('image/')) {
        const reader = new FileReader()
        reader.onloadend = () => {
          setFilePreview(reader.result as string)
        }
        reader.readAsDataURL(selectedFile)
      } else {
        setFilePreview(null)
      }

      analyzeReport(selectedFile)
    }
  }

  const analyzeReport = async (file: File) => {
    setAnalyzing(true)
    setError(null)
    setResult(null)

    try {
      const response = await api.analyzeReport(file)
      setResult(response as AnalysisResult)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to analyze report. Please try again.')
      setResult(null)
    } finally {
      setAnalyzing(false)
    }
  }

  const getMetricIcon = (metricName: string) => {
    const name = metricName.toLowerCase()
    if (name.includes('pressure') || name.includes('bp')) return Heart
    if (name.includes('bmi') || name.includes('weight')) return Weight
    if (name.includes('heart') || name.includes('pulse') || name.includes('rate')) return Activity
    if (name.includes('sugar') || name.includes('glucose') || name.includes('cholesterol')) return Droplet
    return Zap
  }

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'normal':
        return {
          bg: 'from-green-900/30 to-green-800/20',
          border: 'border-green-700/50',
          text: 'text-green-400',
          badge: 'bg-green-500/20 text-green-300 border-green-500/30'
        }
      case 'warning':
        return {
          bg: 'from-yellow-900/30 to-yellow-800/20',
          border: 'border-yellow-700/50',
          text: 'text-yellow-400',
          badge: 'bg-yellow-500/20 text-yellow-300 border-yellow-500/30'
        }
      case 'critical':
        return {
          bg: 'from-red-900/30 to-red-800/20',
          border: 'border-red-700/50',
          text: 'text-red-400',
          badge: 'bg-red-500/20 text-red-300 border-red-500/30'
        }
      default:
        return {
          bg: 'from-gray-900/30 to-gray-800/20',
          border: 'border-gray-700/50',
          text: 'text-gray-400',
          badge: 'bg-gray-500/20 text-gray-300 border-gray-500/30'
        }
    }
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
              AI Health Report Analyzer
              <Sparkles className="w-5 h-5 text-yellow-400" />
            </h2>
            <p className="text-gray-400">Upload your health report for AI-powered analysis</p>
          </div>
        </div>

        <div className="space-y-6">
          {/* File Upload Area */}
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

          {/* Image Preview */}
          {filePreview && (
            <div className="rounded-xl overflow-hidden border border-gray-700/50 animate-slide-up">
              <img
                src={filePreview}
                alt="Report preview"
                className="w-full h-64 object-contain bg-gray-900/50"
              />
            </div>
          )}

          {/* Analyzing State */}
          {analyzing && (
            <div className="bg-gradient-to-r from-blue-900/30 to-purple-900/30 border border-blue-700/50 rounded-xl p-4 backdrop-blur-sm animate-slide-up">
              <div className="flex items-center space-x-3">
                <div className="relative">
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-t-2 border-blue-500"></div>
                  <div className="absolute inset-0 rounded-full bg-blue-500/20 blur-sm"></div>
                </div>
                <span className="text-blue-300 font-medium">Analyzing your health report with AI...</span>
              </div>
            </div>
          )}

          {/* Error State */}
          {error && (
            <div className="bg-gradient-to-r from-red-900/30 to-red-800/30 border border-red-700/50 rounded-xl p-4 backdrop-blur-sm animate-slide-up">
              <div className="flex items-start gap-3">
                <AlertCircle className="w-5 h-5 text-red-400 flex-shrink-0 mt-0.5" />
                <div>
                  <h4 className="text-red-300 font-semibold mb-1">Analysis Error</h4>
                  <p className="text-red-200 text-sm">{error}</p>
                </div>
              </div>
            </div>
          )}

          {/* Analysis Results */}
          {result && (
            <div className="space-y-6 animate-slide-up">
              {/* Summary Card */}
              <div className="bg-gradient-to-br from-blue-900/30 to-blue-800/20 border border-blue-700/50 rounded-xl p-6 backdrop-blur-sm">
                <div className="flex items-start gap-3 mb-3">
                  <div className="p-2 bg-blue-500/10 rounded-lg">
                    <Info className="w-6 h-6 text-blue-400" />
                  </div>
                  <div className="flex-1">
                    <h3 className="text-xl font-bold text-white mb-2">Summary</h3>
                    <p className="text-gray-300 leading-relaxed">{result.summary}</p>
                  </div>
                </div>
              </div>

              {/* Health Metrics Cards */}
              {result.metrics && result.metrics.length > 0 && (
                <div>
                  <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                    <TrendingUp className="w-6 h-6 text-purple-400" />
                    Key Health Metrics
                  </h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {result.metrics.map((metric, index) => {
                      const Icon = getMetricIcon(metric.name)
                      const colors = getStatusColor(metric.status)

                      return (
                        <div
                          key={index}
                          className={`bg-gradient-to-br ${colors.bg} border ${colors.border} rounded-xl p-5 backdrop-blur-sm hover:scale-105 transition-all duration-300 shadow-lg`}
                        >
                          <div className="flex items-start justify-between mb-3">
                            <div className={`p-2 ${colors.badge} rounded-lg border`}>
                              <Icon className={`w-5 h-5 ${colors.text}`} />
                            </div>
                            <span className={`text-xs font-semibold px-2 py-1 rounded-full ${colors.badge} border uppercase`}>
                              {metric.status}
                            </span>
                          </div>

                          <h4 className="text-white font-semibold mb-2">{metric.name}</h4>

                          <div className="space-y-2">
                            <div>
                              <p className={`text-2xl font-bold ${colors.text}`}>
                                {metric.value} <span className="text-sm font-normal">{metric.unit}</span>
                              </p>
                              <p className="text-xs text-gray-400">
                                Normal Range: {metric.reference_range}
                              </p>
                            </div>

                            <p className="text-sm text-gray-300 leading-relaxed border-t border-gray-700/50 pt-2">
                              {metric.interpretation}
                            </p>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </div>
              )}

              {/* Detailed Analysis */}
              <div className="bg-gradient-to-br from-gray-800/80 to-gray-900/80 border border-gray-700/50 rounded-xl p-6 backdrop-blur-sm">
                <h3 className="text-xl font-bold text-white mb-4">Detailed Analysis</h3>
                <p className="text-gray-300 leading-relaxed whitespace-pre-wrap">{result.analysis}</p>
              </div>

              {/* Recommendations */}
              {result.recommendations && result.recommendations.length > 0 && (
                <div className="bg-gradient-to-br from-purple-900/30 to-purple-800/20 border border-purple-700/50 rounded-xl p-6 backdrop-blur-sm">
                  <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                    <Sparkles className="w-6 h-6 text-purple-400" />
                    AI Recommendations
                  </h3>
                  <ul className="space-y-3">
                    {result.recommendations.map((recommendation, index) => (
                      <li key={index} className="flex items-start gap-3 group/item">
                        <span className="text-purple-400 mt-1 text-xl group-hover/item:scale-125 transition-transform">•</span>
                        <span className="text-gray-300 leading-relaxed">{recommendation}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Disclaimer */}
              <div className="bg-gradient-to-r from-yellow-900/30 to-orange-900/30 border border-yellow-700/50 rounded-xl p-4 backdrop-blur-sm">
                <p className="text-sm text-yellow-200 flex items-start gap-2">
                  <span className="text-yellow-400 text-lg">⚠️</span>
                  <span>
                    <strong className="font-semibold">Medical Disclaimer:</strong> This AI analysis is for informational purposes only and should not replace professional medical advice. Always consult with a qualified healthcare provider for medical decisions.
                  </span>
                </p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
