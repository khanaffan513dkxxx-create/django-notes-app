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
                  code()
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
                sh "docker compose down && docker compose up -d"
            }
        }
    }
}
