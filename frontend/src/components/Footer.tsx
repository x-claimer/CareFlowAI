import { Mail, Phone, Shield, AlertTriangle } from 'lucide-react'

export function Footer() {
  return (
    <footer className="bg-gray-900/95 border-t border-gray-800/50 mt-20 backdrop-blur-lg">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div>
            <h3 className="text-white font-semibold mb-4 flex items-center space-x-2">
              <div className="p-2 bg-blue-500/10 rounded-lg">
                <Phone className="w-5 h-5 text-blue-400" />
              </div>
              <span>Contact</span>
            </h3>
            <div className="space-y-3 text-gray-400 text-sm">
              <p className="flex items-center gap-2 hover:text-white transition-colors">
                <span className="text-red-400">🚨</span>
                <span><strong>Emergency:</strong> 911</span>
              </p>
              <p className="flex items-center gap-2 hover:text-white transition-colors">
                <span className="text-blue-400">📞</span>
                <span><strong>Support:</strong> 1-800-CARE-FLOW</span>
              </p>
              <p className="flex items-center gap-2 hover:text-white transition-colors">
                <span className="text-green-400">📧</span>
                <span><strong>Email:</strong> support@careflowai.com</span>
              </p>
            </div>
          </div>

          <div>
            <h3 className="text-white font-semibold mb-4 flex items-center space-x-2">
              <div className="p-2 bg-purple-500/10 rounded-lg">
                <Mail className="w-5 h-5 text-purple-400" />
              </div>
              <span>Support</span>
            </h3>
            <div className="space-y-2 text-sm">
              <a href="#" className="block text-gray-400 hover:text-blue-400 transition-colors hover:translate-x-1 transform duration-200">
                → Help Center
              </a>
              <a href="#" className="block text-gray-400 hover:text-blue-400 transition-colors hover:translate-x-1 transform duration-200">
                → Privacy Policy
              </a>
              <a href="#" className="block text-gray-400 hover:text-blue-400 transition-colors hover:translate-x-1 transform duration-200">
                → Terms of Service
              </a>
              <a href="#" className="block text-gray-400 hover:text-blue-400 transition-colors hover:translate-x-1 transform duration-200">
                → FAQ
              </a>
            </div>
          </div>

          <div>
            <h3 className="text-white font-semibold mb-4 flex items-center space-x-2">
              <div className="p-2 bg-yellow-500/10 rounded-lg">
                <AlertTriangle className="w-5 h-5 text-yellow-400" />
              </div>
              <span>Important Notice</span>
            </h3>
            <div className="bg-gradient-to-br from-yellow-900/20 to-orange-900/20 border border-yellow-700/50 rounded-xl p-4 backdrop-blur-sm">
              <p className="text-xs text-yellow-200 flex items-start gap-2">
                <Shield className="w-4 h-4 flex-shrink-0 mt-0.5" />
                <span>
                  AI features are assistive tools only. Always consult healthcare professionals for medical decisions. Your health data is protected under HIPAA compliance.
                </span>
              </p>
            </div>
          </div>
        </div>

        <div className="border-t border-gray-800/50 mt-10 pt-8 text-center">
          <p className="text-gray-500 text-sm flex items-center justify-center gap-2">
            {/* <Heart className="w-4 h-4 text-red-400 animate-pulse" /> */}
            <span>© 2024 CareFlowAI. All rights reserved.</span>
            {/* <span className="mx-2">|</span>
            <span className="text-green-400 flex items-center gap-1">
              <Shield className="w-4 h-4" />
              HIPAA Compliant
            </span> */}
          </p>
        </div>
      </div>
    </footer>
  )
}
