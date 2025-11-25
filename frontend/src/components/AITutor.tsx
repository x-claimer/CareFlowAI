import { useState } from 'react'
import { Search, BookOpen, Lightbulb, Sparkles, TrendingUp } from 'lucide-react'

interface SearchResult {
  term: string
  definition: string
  examples: string[]
}

export function AITutor() {
  const [searchQuery, setSearchQuery] = useState('')
  const [searching, setSearching] = useState(false)
  const [result, setResult] = useState<SearchResult | null>(null)

  const handleSearch = async () => {
    if (!searchQuery.trim()) return

    setSearching(true)

    // Simulate AI search
    await new Promise(resolve => setTimeout(resolve, 1500))

    // Mock result based on query
    setResult({
      term: searchQuery,
      definition: `${searchQuery} refers to a medical condition or health-related concept. This AI-powered explanation helps you understand complex medical terminology in simple terms.`,
      examples: [
        `Common usage: "The patient was diagnosed with ${searchQuery}"`,
        `Related terms: cardiovascular health, preventive care`,
        `When to seek help: If you experience symptoms related to ${searchQuery}`
      ]
    })

    setSearching(false)
  }

  const popularTerms = [
    'Hypertension',
    'Diabetes',
    'Cholesterol',
    'BMI',
    'Cardiovascular',
    'Inflammation'
  ]

  return (
    <div className="relative group">
      {/* Gradient background effect */}
      <div className="absolute inset-0 bg-gradient-to-r from-green-600/10 to-emerald-600/10 rounded-2xl blur-xl group-hover:blur-2xl transition-all duration-300"></div>

      <div className="relative bg-gradient-to-br from-gray-900 to-gray-900/80 rounded-2xl p-8 border border-gray-800/50 backdrop-blur-sm shadow-2xl hover:border-green-700/50 transition-all duration-300">
        <div className="flex items-center space-x-3 mb-6">
          <div className="relative">
            <div className="absolute inset-0 bg-green-500/20 rounded-xl blur-md"></div>
            <div className="relative bg-gradient-to-br from-green-600 to-emerald-700 p-3 rounded-xl shadow-lg">
              <BookOpen className="w-6 h-6 text-white" />
            </div>
          </div>
          <div>
            <h2 className="text-2xl font-bold text-white flex items-center gap-2">
              AI Health Tutor
              <Sparkles className="w-5 h-5 text-yellow-400" />
            </h2>
            <p className="text-gray-400">Learn about medical terms and health concepts</p>
          </div>
        </div>

        <div className="space-y-5">
          <div className="flex space-x-3">
            <div className="flex-1 relative group/search">
              <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-500 group-focus-within/search:text-green-400 transition-colors" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                placeholder="Search for medical terms, conditions, procedures..."
                className="w-full pl-12 pr-4 py-4 bg-gray-900/50 border border-gray-700 rounded-xl text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent transition-all duration-300 hover:border-gray-600"
              />
            </div>
            <button
              onClick={handleSearch}
              disabled={searching || !searchQuery.trim()}
              className="bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 disabled:from-gray-700 disabled:to-gray-700 disabled:cursor-not-allowed text-white px-8 py-4 rounded-xl font-semibold transition-all duration-300 transform hover:scale-105 active:scale-95 shadow-lg hover:shadow-green-500/50"
            >
              {searching ? (
                <div className="flex items-center gap-2">
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                  <span>Searching...</span>
                </div>
              ) : (
                'Search'
              )}
            </button>
          </div>

          <div className="flex flex-wrap gap-2 items-center">
            <div className="flex items-center gap-2 text-sm text-gray-400">
              <TrendingUp className="w-4 h-4" />
              <span className="font-medium">Popular:</span>
            </div>
            {popularTerms.map((term) => (
              <button
                key={term}
                onClick={() => {
                  setSearchQuery(term)
                  setResult(null)
                }}
                className="text-sm bg-gradient-to-r from-gray-800 to-gray-800/50 hover:from-green-900/30 hover:to-emerald-900/30 text-gray-300 hover:text-green-300 px-4 py-2 rounded-full border border-gray-700 hover:border-green-700/50 transition-all duration-300 transform hover:scale-105"
              >
                {term}
              </button>
            ))}
          </div>

          {result && (
            <div className="bg-gradient-to-br from-gray-800/80 to-gray-900/80 rounded-xl p-6 border border-gray-700/50 backdrop-blur-sm shadow-xl space-y-5 animate-slide-up">
              <div>
                <div className="flex items-start gap-3 mb-3">
                  <div className="p-2 bg-yellow-500/10 rounded-lg">
                    <Lightbulb className="w-6 h-6 text-yellow-400" />
                  </div>
                  <div>
                    <h3 className="text-2xl font-bold text-white mb-1">
                      {result.term}
                    </h3>
                    <div className="h-1 w-20 bg-gradient-to-r from-green-500 to-emerald-500 rounded-full"></div>
                  </div>
                </div>
                <p className="text-gray-300 leading-relaxed text-lg">{result.definition}</p>
              </div>

              <div className="border-t border-gray-700/50 pt-5">
                <h4 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                  <span className="w-1.5 h-6 bg-gradient-to-b from-green-500 to-emerald-500 rounded-full"></span>
                  Examples & Usage
                </h4>
                <ul className="space-y-3">
                  {result.examples.map((example, index) => (
                    <li key={index} className="flex items-start space-x-3 group/item">
                      <span className="text-green-400 mt-1 text-xl group-hover/item:scale-125 transition-transform">•</span>
                      <span className="text-gray-300 leading-relaxed">{example}</span>
                    </li>
                  ))}
                </ul>
              </div>

              <div className="bg-gradient-to-r from-yellow-900/30 to-orange-900/30 border border-yellow-700/50 rounded-xl p-4 backdrop-blur-sm">
                <p className="text-sm text-yellow-200 flex items-start gap-2">
                  <span className="text-yellow-400 text-lg">⚠️</span>
                  <span>
                    <strong className="font-semibold">Disclaimer:</strong> This information is for educational purposes only. Always consult with a healthcare professional for medical advice.
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
