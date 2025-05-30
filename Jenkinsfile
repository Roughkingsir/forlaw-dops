pipeline {
  agent { label 'build' }

  environment {
    registry = "saadkhan0/yourapp"
    registryCredential = 'dockerhub'
    DJANGO_SETTINGS_MODULE = 'backend.settings'
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
        sh '''
          set -e

          which python3 || sudo apt install -y python3
          which pip3 || sudo apt install -y python3-pip
          which node || sudo apt install -y nodejs npm
          sudo npm install -g npm-check-updates && ncu -u && npm install
          which docker || sudo apt install -y docker.io
          which wget || sudo apt install -y wget unzip curl

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

    stage('Run Backend Tests & Coverage') {
      steps {
        sh '''
          export PYTHONPATH=$(pwd)
          python3 -m coverage run backend/manage.py test
          python3 -m coverage report
          python3 -m coverage xml
        '''
      }
    }

    stage('Run Frontend Tests') {
      steps {
        sh '''
          cd frontend 
          dos2unix node_modules/.bin/vitest || true
          chmod +x node_modules/.bin/vitest
          npx vitest run --coverage
        '''
      }
    }

    stage('SCA & SAST') {
      steps {
        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
          sh '''
            bandit -r backend -f json -o bandit-report.json || true
            safety check --file=backend/requirements.txt --full-report > safety-report.txt || true
          '''
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('mysonar') {
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
        timeout(time: 1, unit: 'MINUTES') {
          def qg = waitForQualityGate()
          if (qg.status != 'OK') {
            error "Pipeline failed due to quality gate: ${qg.status}"
          }
        }
      }
    }

    stage('Build & Push Docker Image') {
      steps {
        withCredentials([
          usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')
        ]) {
          sh '''
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker build -t ${registry}:latest .
            docker push ${registry}:latest
            docker logout
          '''
        }
      }
    }

    stage('Scan Docker Image') {
      steps {
        sh "trivy image --scanners vuln --offline-scan ${registry}:latest > trivyresults.txt"
      }
    }

    stage('Smoke Test') {
      steps {
        withCredentials([
          string(credentialsId: 'DJANGO_SECRET_KEY', variable: 'DJANGO_SECRET_KEY')
        ]) {
          sh '''
            docker run -d --name smokerun -p 8000:8000 -e DJANGO_SECRET_KEY="$DJANGO_SECRET_KEY" ${registry}:latest
            for i in {1..10}; do curl -f http://localhost:8000 && break || sleep 5; done
            docker rm --force smokerun
          '''
        }
      }
    }
  }

  post {
    always {
      cleanWs()
    }
  }
}
