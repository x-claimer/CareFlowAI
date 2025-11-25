# CareFlowAI Frontend

A production-ready React + TypeScript + Tailwind CSS single-page application for CareFlowAI – an AI nurse and health tutor platform.

## Tech Stack

- **React 18** – UI library
- **TypeScript** – Type safety
- **Vite** – Lightning-fast bundler
- **Tailwind CSS** – Utility-first styling
- **React Query (@tanstack/react-query)** – Server state management with mock API

## Features

- **Responsive Design** – Mobile-first layout that adapts to all screen sizes
- **Component-based Architecture** – Modular, reusable components
- **Mock API** – Simulated data fetching with React Query
- **Accessible** – Semantic HTML, ARIA labels, and keyboard navigation
- **Clean UI** – Tailwind CSS for consistent, professional styling

## Project Structure

```
src/
├── components/
│   ├── NavBar.tsx           # Top navigation bar
│   ├── Hero.tsx             # Hero section with CTA buttons
│   ├── SearchBar.tsx        # Health search input
│   ├── FeatureCards.tsx     # Feature highlight cards
│   ├── LearnSection.tsx     # Articles section with React Query
│   └── Footer.tsx           # Footer with disclaimer & links
├── api/
│   └── mockArticles.ts      # Mock API data & query function
├── styles/
│   └── globals.css          # Tailwind directives & global styles
├── App.tsx                  # Main app layout
└── main.tsx                 # React entry point

Configuration files:
├── vite.config.ts           # Vite configuration
├── tsconfig.json            # TypeScript configuration
├── tailwind.config.cjs       # Tailwind CSS configuration
└── postcss.config.cjs        # PostCSS configuration
```

## How to Run Locally

### Prerequisites
- Node.js 16+ installed
- npm or yarn package manager

### Setup & Run

```bash
# 1. Navigate to the project directory
cd careflowai-frontend

# 2. Install dependencies
npm install

# 3. Start the development server
npm run dev
```

Open your browser and navigate to the URL shown in the terminal (typically `http://localhost:5173`).

### Build for Production

```bash
npm run build
```

Output files will be in the `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

## Features Overview

### Navigation Bar
- Logo "CareFlowAI" on the left
- Nav links: Home, AI Nurse, Tutor, About

### Hero Section
- Large title and subtitle
- Two call-to-action buttons: "Start Symptom Check" & "Ask a Health Question"
- Responsive design with gradient background

### Search Bar
- Full-width search input with leading icon
- Placeholder text guides user input
- Console logs search queries on submit

### Feature Cards
- 4 quick-access cards (responsive grid: 2 cols on mobile, 4 cols on desktop)
- Hover effects with border transitions
- Card clicks logged to console

### Learn Section
- Fetches mock articles using React Query
- Displays loading/error states
- 3 sample articles about health topics
- Responsive grid layout

### Footer
- Disclaimer about CareFlowAI not being a medical substitute
- Links for About, Privacy, and Terms

## Development Tips

- **Add new components**: Create a `.tsx` file in `src/components/`, export a function component
- **Add styles**: Use Tailwind utility classes directly in JSX; avoid custom CSS when possible
- **Mock API data**: Update `src/api/mockArticles.ts` and query with `useQuery` in components
- **Type safety**: Always define component props and API response types

## Browser Support

Works in all modern browsers supporting ES2020+ (Chrome, Firefox, Safari, Edge).

---

Built with ❤️ for healthcare professionals and patients alike.
CareFlow AI is an intelligent healthcare operations platform that unifies scheduling, microservices, machine learning, and scalable EKS-based infrastructure. It streamlines patient flow—from triage to forecasting—while dynamically adapting to clinical demand, ensuring smooth, efficient, and cloud-ready care delivery.
