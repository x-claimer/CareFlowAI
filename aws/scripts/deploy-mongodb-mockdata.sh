#!/bin/bash

###############################################################################
# CareFlowAI MongoDB Atlas Data Deployment Script
# This script seeds MongoDB Atlas with test users and appointments data
###############################################################################

set -euo pipefail

# Color output functions
info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }

# Move to repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

info "=========================================="
info "CareFlowAI MongoDB Atlas Seeding Script"
info "=========================================="
echo

# Check if .env file exists
if [[ ! -f "backend/.env" ]]; then
    error ".env file not found in backend directory!"
    error "Please create backend/.env with your MongoDB Atlas connection string."
    exit 1
fi

# Load environment variables
info "Loading environment variables from backend/.env..."
export $(grep -v '^#' backend/.env | grep -E '^(MONGODB_URL|DATABASE_NAME)=' | xargs)

# Verify MongoDB URL is set
if [[ -z "${MONGODB_URL:-}" ]]; then
    error "MONGODB_URL not found in .env file!"
    exit 1
fi

# Mask password in MongoDB URL for display
DISPLAY_URL=$(echo "$MONGODB_URL" | sed -E 's/:([^:@]+)@/:****@/')
info "MongoDB URL: $DISPLAY_URL"
info "Database Name: ${DATABASE_NAME:-careflowai}"
echo

# Confirm before proceeding
warn "⚠️  WARNING: This will DELETE all existing data in the database!"
warn "⚠️  This includes all users, appointments, and comments."
echo
read -r -p "Do you want to continue? (yes/no): " RESPONSE

if [[ ! "$RESPONSE" =~ ^[Yy][Ee][Ss]$ ]]; then
    info "Operation cancelled."
    exit 0
fi

echo
info "Starting MongoDB Atlas seeding process..."
echo

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    error "Python 3 is not installed or not in PATH!"
    exit 1
fi

# Check if virtual environment exists
if [[ ! -d "backend/venv" ]] && [[ ! -d "backend/.venv" ]]; then
    warn "Virtual environment not found. Creating one..."
    python3 -m venv backend/venv
    info "Virtual environment created at backend/venv"
fi

# Activate virtual environment
if [[ -d "backend/venv" ]]; then
    VENV_PATH="backend/venv"
elif [[ -d "backend/.venv" ]]; then
    VENV_PATH="backend/.venv"
fi

info "Activating virtual environment: $VENV_PATH"
source "$VENV_PATH/bin/activate" 2>/dev/null || source "$VENV_PATH/Scripts/activate" 2>/dev/null

# Install/upgrade dependencies
info "Installing dependencies..."
python -m pip install -q --upgrade pip
python -m pip install -q -r backend/requirements.txt

echo
info "Running seed script..."
echo

# Run the seeding script
python backend/scripts/seed_appointments.py --yes

echo
if [[ $? -eq 0 ]]; then
    success "=========================================="
    success "MongoDB Atlas seeded successfully!"
    success "=========================================="
    echo
    info "You can now log in with these test accounts:"
    echo
    echo "📋 PATIENTS:"
    echo "   • john.doe@example.com / password123"
    echo "   • jane.smith@example.com / password123"
    echo "   • bob.wilson@example.com / password123"
    echo
    echo "👨‍⚕️  DOCTORS:"
    echo "   • sarah.johnson@hospital.com / password123"
    echo "   • michael.chen@hospital.com / password123"
    echo
    echo "📞 RECEPTIONIST:"
    echo "   • emily.davis@hospital.com / password123"
    echo
    echo "🔧 ADMIN:"
    echo "   • admin@hospital.com / admin123"
    echo
    success "Your MongoDB Atlas database is ready to use!"
else
    error "Failed to seed MongoDB Atlas database!"
    exit 1
fi
