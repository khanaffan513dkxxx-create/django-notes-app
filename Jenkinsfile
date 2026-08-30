@Library("shared") _

pipeline{
    
    agent { 
        label "vinod"
    }
    
    stages{
        
        stage("hello") {
            steps {
                script {
                    hello()
                }
            }
        }
        stage("code"){
            steps{
                script{
                 clone("https://github.com/LondheShubham153/django-notes-app.git", "main")
                }
            }
        }
        stage("build"){
            steps{
                script{
                docker_build("notes-app","latest","khanaffan513")    
                }
            }
        }
        stage("push to DockerHub"){
            steps{
               script{
                   docker_push("notes-app","latest","khanaffan513")
                }
            }
        }
        stage("deploy"){
            steps{
                echo "this is deploying the code"
                sh "docker compose up -d"
            }
        }
    }
}
