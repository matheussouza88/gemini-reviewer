pipeline {
    agent any

    environment {
        DOCKER_REGISTRY_HOST = 'ghcr.io'
        DOCKER_REGISTRY_OWNER = 'matheussouza88'
        DOCKER_REGISTRY = "${DOCKER_REGISTRY_HOST}/${DOCKER_REGISTRY_OWNER}"
        DOCKER_CREDENTIALS_ID = 'ghcr-auth'
        
        IMAGE_NAME = "${DOCKER_REGISTRY}/gemini-reviewer"
        DOCKERFILE = 'Dockerfile'
    }

    triggers {
        pollSCM('H * * * *')
    }

    stages {
        stage('Prepare Image Tag') {
            steps {
                script {
                    def imageTag = env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'main' ? "v${env.BUILD_NUMBER}" : (env.CHANGE_ID ? "pr-${env.CHANGE_ID}-${env.BUILD_NUMBER}" : env.BRANCH_NAME)
                    env.IMAGE_TAG = imageTag
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    echo "Building Docker image for ${IMAGE_NAME}:${env.IMAGE_TAG}..."
                    sh "docker build -t ${IMAGE_NAME}:${env.IMAGE_TAG} -f ${DOCKERFILE} ."
                }
            }
        }

        stage('Docker Login') {
            when {
                anyOf {
                    branch 'master'
                    branch 'main'
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login $DOCKER_REGISTRY_HOST -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Docker Push Tag') {
            when {
                anyOf {
                    branch 'master'
                    branch 'main'
                }
            }
            steps {
                sh "docker push ${IMAGE_NAME}:${env.IMAGE_TAG}"
            }
        }

        stage('Docker Tag Latest') {
            when {
                anyOf {
                    branch 'master'
                    branch 'main'
                }
            }
            steps {
                sh "docker tag ${IMAGE_NAME}:${env.IMAGE_TAG} ${IMAGE_NAME}:latest"
            }
        }

        stage('Docker Push Latest') {
            when {
                anyOf {
                    branch 'master'
                    branch 'main'
                }
            }
            steps {
                sh "docker push ${IMAGE_NAME}:latest"
            }
        }
    }

    post {
        success {
            echo "Build and push finished successfully!"
        }
        failure {
            echo "Build failed!"
        }
    }
}
