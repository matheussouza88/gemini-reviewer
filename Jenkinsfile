pipeline {
    agent any

    environment {
        DOCKER_REGISTRY_HOST = 'ghcr.io'
        DOCKER_REGISTRY_OWNER = "${env.GIT_URL ? env.GIT_URL.replace('git@github.com:', '').replace('https://github.com/', '').split('/')[0] : 'matheussouza88'}"
        DOCKER_REGISTRY = "${DOCKER_REGISTRY_HOST}/${DOCKER_REGISTRY_OWNER}"
        DOCKER_CREDENTIALS_ID = 'ghcr-auth'
        GITHUB_TOKEN_ID = 'ghcr-auth'
        
        IMAGE_NAME = "${DOCKER_REGISTRY}/gemini-reviewer"
        DOCKERFILE = 'Dockerfile'
    }

    stages {
        stage('Initialize GitHub Status') {
            when {
                expression { env.CHANGE_ID != null }
            }
            steps {
                script {
                    echo "Pull Request detected: #${env.CHANGE_ID}"
                    updateGithubStatus('pending', 'Build started', 'Jenkins Build')
                }
            }
        }

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

        stage('GitHub Approve & Merge') {
            when {
                expression { env.CHANGE_ID != null }
            }
            steps {
                script {
                    updateGithubStatus('success', 'Build successful', 'Jenkins Build')
                    approveGithubPullRequest(env.CHANGE_ID)
                    mergeGithubPullRequest(env.CHANGE_ID)
                }
            }
        }
    }

    post {
        success {
            echo "Build and push finished successfully!"
        }
        failure {
            script {
                if (env.CHANGE_ID) {
                    updateGithubStatus('failure', 'Build failed', 'Jenkins Build')
                }
            }
            echo "Build failed!"
        }
    }
}

def updateGithubStatus(state, description, context) {
    def gitUrl = env.GIT_URL ?: "git@github.com:matheussouza88/gemini-reviewer.git"
    def repoPath = gitUrl.replace('git@github.com:', '').replace('https://github.com/', '').replace('.git', '')
    def sha = env.GIT_COMMIT ?: sh(script: 'git rev-parse HEAD', returnStdout: true).trim()

    withCredentials([usernamePassword(credentialsId: env.GITHUB_TOKEN_ID, usernameVariable: 'GH_USER', passwordVariable: 'GH_PAT')]) {
        sh """
            curl -f -s -X POST \\
                -H "Authorization: Bearer \$GH_PAT" \\
                -H "Accept: application/vnd.github.v3+json" \\
                https://api.github.com/repos/${repoPath}/statuses/${sha} \\
                -d '{"state": "${state.toLowerCase()}", "target_url": "${env.BUILD_URL}", "description": "${description}", "context": "${context}"}'
        """
    }
}

def approveGithubPullRequest(prId) {
    def gitUrl = env.GIT_URL ?: "git@github.com:matheussouza88/gemini-reviewer.git"
    def repoPath = gitUrl.replace('git@github.com:', '').replace('https://github.com/', '').replace('.git', '')

    echo "Approving Pull Request #${prId} for ${repoPath}..."

    withCredentials([usernamePassword(credentialsId: env.GITHUB_TOKEN_ID, usernameVariable: 'GH_USER', passwordVariable: 'GH_PAT')]) {
        sh """
            curl -f -s -X POST \\
                -H "Authorization: Bearer \$GH_PAT" \\
                -H "Accept: application/vnd.github.v3+json" \\
                https://api.github.com/repos/${repoPath}/pulls/${prId}/reviews \\
                -d '{"event": "APPROVE", "body": "Jenkins Build Successful. Automatically approving PR."}' || true
        """
    }
}

def mergeGithubPullRequest(prId) {
    def gitUrl = env.GIT_URL ?: "git@github.com:matheussouza88/gemini-reviewer.git"
    def repoPath = gitUrl.replace('git@github.com:', '').replace('https://github.com/', '').replace('.git', '')
    def branchName = env.CHANGE_BRANCH

    echo "Merging Pull Request #${prId} (branch: ${branchName}) for ${repoPath}..."

    withCredentials([usernamePassword(credentialsId: env.GITHUB_TOKEN_ID, usernameVariable: 'GH_USER', passwordVariable: 'GH_PAT')]) {
        sh """
            curl -f -s -X PUT \\
                -H "Authorization: Bearer \$GH_PAT" \\
                -H "Accept: application/vnd.github.v3+json" \\
                https://api.github.com/repos/${repoPath}/pulls/${prId}/merge \\
                -d '{"merge_method": "squash", "commit_title": "Auto-merge PR #${prId} after successful Jenkins build"}'
        """

        echo "Deleting branch ${branchName}..."
        sh """
            curl -f -s -X DELETE \\
                -H "Authorization: Bearer \$GH_PAT" \\
                -H "Accept: application/vnd.github.v3+json" \\
                https://api.github.com/repos/${repoPath}/git/refs/heads/${branchName}
        """
    }
}
