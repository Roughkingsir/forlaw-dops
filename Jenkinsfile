pipeline {
  agent { label 'build' }

  environment {
    registry = "saadkhan0/yourapp"
    registryCredential = 'dockerhub'
    DJANGO_SETTINGS_MODULE = 'settings'
    PATH = "$PATH:/opt/sonar-scanner/bin"
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'master', credentialsId: 'gitcreds', url: 'https://github.com/Roughkingsir/forlaw-dops.git'
      }
    }

    stage('Install Dependencies') {
      steps {
        echo "Installing system dependencies..."
        sh '''
          set -e

          which python3 || sudo apt install -y python3
          which pip3 || sudo apt install -y python3-pip
          which node || sudo apt install -y nodejs npm
          sudo npm install -g npm-check-updates && ncu -u && npm install
          which docker || sudo apt install -y docker.io
          which wget || sudo apt install -y wget unzip curl

          # Install sonar-scanner if not installed
          if ! [ -x /opt/sonar-scanner/bin/sonar-scanner ]; then
            wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-4.6.2.2472-linux.zip
            unzip sonar-scanner-4.6.2.2472-linux.zip
            sudo mv sonar-scanner-4.6.2.2472-linux /opt/sonar-scanner
          fi

          which bandit || sudo pip3 install bandit
          which coverage || sudo pip3 install coverage
          which safety || sudo pip3 install safety

          if ! command -v trivy &> /dev/null; then
            curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.26.0/trivy_0.26.0_Linux-64bit.deb -o trivy.deb
            sudo dpkg -i trivy.deb || sudo apt-get install -f -y
          fi

          pip3 install -r backend/requirements.txt
          sudo npm install -g npm@10.8.2
          cd frontend
          npm install --legacy-peer-deps
        '''
      }
    }

    stage('Run Tests & Coverage (Backend)') {
      steps {
        echo "Running Django Tests with Coverage"
        sh '''
          export PYTHONPATH=$(pwd)/backend
          cd backend
          python3 -m coverage run manage.py test
          python3 -m coverage report
          python3 -m coverage xml
        '''
      }
    }

    stage('Run Tests (Frontend)') {
      steps {
        echo "Running React Tests"
        sh "cd frontend && npm test -- --watchAll=false"
      }
    }

    stage('SCA & SAST') {
      steps {
        echo "Running Security Scans with Bandit and Safety"
        sh '''
          bandit -r backend
          safety check --file=backend/requirements.txt
        '''
      }
    }

    stage('SonarQube Analysis') {
      steps {
        echo "Running SonarQube for Python and JS"
        withSonarQubeEnv('mysonar1') {
          sh '''
            sonar-scanner \
              -Dsonar.projectKey=forlaw-dops \
              -Dsonar.sources=backend,frontend \
              -Dsonar.python.coverage.reportPaths=backend/coverage.xml
          '''
        }
      }
    }

    stage('Quality Gates') {
      steps {
        echo "Checking Quality Gate"
        script {
          timeout(time: 1, unit: 'MINUTES') {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
              error "Pipeline failed due to quality gate: ${qg.status}"
            }
          }
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        echo "Building Docker Image"
        script {
          docker.withRegistry('', registryCredential) {
            def myImage = docker.build(registry)
            myImage.push()
          }
        }
      }
    }

    stage('Scan Docker Image') {
      steps {
        echo "Scanning Docker Image with Trivy"
        sh "trivy image --scanners vuln --offline-scan ${registry}:latest > trivyresults.txt"
      }
    }

    stage('Smoke Test Docker Image') {
      steps {
        echo "Running Smoke Test"
        sh '''
          docker run -d --name smokerun -p 8000:8000 ${registry}
          for i in {1..10}; do curl -f http://localhost:8000 && break || sleep 5; done
          docker rm --force smokerun
        '''
      }
    }
  } // This is the missing closing curly brace for the 'stages' block

  post {
    always {
      echo "Cleaning up workspace"
      cleanWs()
    }
  }
}
