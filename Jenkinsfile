pipeline {
    agent { label "vinod" }

    stages {
        stage('code') {
            steps {
                echo 'Cloning code'
                git url: 'https://github.com/khanaffan513dkxxx-create/django-notes-app.git',
                    branch: 'main'
                echo 'Code clone successful'
            }
        }

        stage('build') {
            steps {
                echo 'Building Docker image'
                sh 'docker build -t notes-app:latest .'
            }
        }

        stage('push to DockerHub') {
            steps {
                echo 'Pushing image to Docker Hub'
                withCredentials([usernamePassword(
                    credentialsId: 'DockerHubCred',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASS'
                )]) {
                    sh '''
                        set +x
                        echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
                        docker tag notes-app:latest "$DOCKERHUB_USER/notes-app:latest"
                        docker push "$DOCKERHUB_USER/notes-app:latest"
                        docker logout
                    '''
                }
            }
        }

        stage('deploy') {
            steps {
                echo 'Deploying application'
                sh '''
                    docker compose down --remove-orphans || true
                    docker compose pull django_app
                    docker compose up -d --build
                    docker compose ps
                '''
            }
        }
    }
}
