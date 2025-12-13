# CareFlowAI Frontend

Modern, intelligent healthcare management platform frontend built with React, TypeScript, and Tailwind CSS.

---

## 🚀 Tech Stack

- **React 19** - Modern UI library with latest features
- **TypeScript** - Type-safe development
- **Tailwind CSS 4** - Utility-first styling with latest features
- **React Router v7** - Advanced routing capabilities
- **Lucide React** - Beautiful, consistent icons
- **Vite** - Lightning-fast build tool

---

## ✨ Features

### User Interface
- **Responsive Design** - Mobile-first layout that adapts to all screen sizes
- **Component-based Architecture** - Modular, reusable components
- **Accessible** - Semantic HTML, ARIA labels, and keyboard navigation
- **Modern UI** - Clean, professional styling with Tailwind CSS

### Core Components
- **Authentication** - Login system with role-based access
- **Dashboard** - Role-specific home views for patients, doctors, and receptionists
- **AI Nurse** - Health report upload and analysis interface
- **AI Tutor** - Medical terminology search and education
- **Schedule Manager** - Appointment scheduling and management
- **Comments System** - Collaborative appointment notes

---

## 📁 Project Structure

```
frontend/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── NavBar.tsx      # Top navigation bar
│   │   ├── Hero.tsx        # Hero section with CTA buttons
│   │   ├── SearchBar.tsx   # Health search input
│   │   ├── FeatureCards.tsx # Feature highlight cards
│   │   ├── LearnSection.tsx # Articles section
│   │   └── Footer.tsx      # Footer with links
│   ├── contexts/            # React context providers
│   │   └── AuthContext.tsx # Authentication state
│   ├── pages/              # Page components
│   │   ├── Login.tsx       # Login page
│   │   ├── Home.tsx        # Dashboard
│   │   ├── AINurse.tsx     # AI Nurse interface
│   │   ├── AITutor.tsx     # AI Tutor interface
│   │   └── Schedule.tsx    # Appointment scheduler
│   ├── styles/
│   │   └── globals.css     # Tailwind directives & global styles
│   ├── App.tsx             # Main app layout with routing
│   └── main.tsx            # React entry point
│
├── public/                  # Static assets
├── package.json            # Dependencies and scripts
├── vite.config.ts          # Vite configuration
├── tsconfig.json           # TypeScript configuration
├── tailwind.config.cjs     # Tailwind CSS configuration
└── postcss.config.cjs      # PostCSS configuration
```

---

## 🛠️ Getting Started

### Prerequisites
- **Node.js 18+** - [Download Node.js](https://nodejs.org/)
- **npm** or **yarn** - Comes with Node.js

### Installation

```bash
# Navigate to the frontend directory
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

The frontend will be available at: **http://localhost:5173**

### Build for Production

```bash
# Create optimized production build
npm run build

# Preview production build locally
npm run preview
```

Output files will be in the `dist/` directory.

---

## 🎨 Component Overview

### Navigation Bar
- Logo "CareFlowAI" on the left
- Navigation links: Home, AI Nurse, Tutor, Schedule
- User menu with logout option
- Role indicator badge

### Hero Section
- Large title and subtitle
- Call-to-action buttons
- Responsive design with gradient background

### Search Bar
- Full-width search input with icon
- Real-time search functionality
- Mobile-optimized

### Feature Cards
- 4 quick-access cards in responsive grid
- Hover effects with border transitions
- Click handlers for navigation

### AI Nurse Interface
- File upload for health reports (PDF, JPG, PNG)
- Chat interface for AI analysis
- Report history view

### AI Tutor Interface
- Medical term search
- Popular topics section
- Detailed explanations with examples

### Schedule Manager
- Calendar view of appointments
- Create/edit/delete functionality (role-based)
- Status tracking (scheduled, completed, cancelled)
- Comments section per appointment

---

## 🔐 User Roles

The frontend adapts based on user role:

### Patient
- View personal appointments
- Upload and chat with AI Nurse
- Use AI Health Tutor
- Add comments to appointments

### Doctor
- All patient permissions
- Create/update/delete appointments
- View all appointments
- Manage patient schedules

### Receptionist
- Create/update/delete appointments
- Manage facility-wide scheduling
- Administrative oversight

---

## 🎯 Development Tips

### Adding New Components
1. Create a `.tsx` file in `src/components/`
2. Export a function component
3. Use TypeScript for props
4. Import and use in pages

### Styling
- Use Tailwind utility classes directly in JSX
- Avoid custom CSS when possible
- Follow existing component patterns
- Maintain responsive design principles

### Type Safety
- Define component props interfaces
- Type API response data
- Use TypeScript strict mode
- Leverage IDE autocomplete

### API Integration
- API base URL configured in environment
- Authentication tokens handled via AuthContext
- Error handling with user-friendly messages
- Loading states for async operations

---

## 🌐 Environment Variables

Create a `.env` file in the frontend directory:

```env
VITE_API_URL=http://localhost:8000
```

For production:
```env
VITE_API_URL=https://your-api-domain.com
```

---

## 📱 Browser Support

Works in all modern browsers supporting ES2020+:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

---

## 🧪 Testing

```bash
# Run tests (when configured)
npm run test

# Run linter
npm run lint
```

---

## 📦 Dependencies

### Core
- `react` - UI library
- `react-dom` - React DOM renderer
- `react-router-dom` - Routing

### UI & Styling
- `tailwindcss` - Utility-first CSS
- `lucide-react` - Icon library
- `postcss` - CSS processing
- `autoprefixer` - CSS vendor prefixing

### Development
- `vite` - Build tool
- `typescript` - Type checking
- `@types/react` - React type definitions
- `@vitejs/plugin-react` - React plugin for Vite

---

## 🔄 Available Scripts

```bash
npm run dev       # Start development server
npm run build     # Build for production
npm run preview   # Preview production build
npm run lint      # Run ESLint
```

---

## 🚀 Deployment

### Build
```bash
npm run build
```

### Deploy to AWS S3 + CloudFront
See the [AWS deployment guide](../aws/README.md) for full instructions.

### Deploy to Vercel/Netlify
```bash
# Build command
npm run build

# Output directory
dist
```

---

## 🤝 Contributing

1. Follow the existing code structure
2. Use TypeScript for all new code
3. Maintain responsive design
4. Test on multiple browsers
5. Follow component composition patterns

---

## 📚 Additional Resources

- [React Documentation](https://react.dev)
- [TypeScript Documentation](https://www.typescriptlang.org/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [Vite Documentation](https://vitejs.dev)
- [React Router Documentation](https://reactrouter.com)

---

Built with care for better healthcare.
