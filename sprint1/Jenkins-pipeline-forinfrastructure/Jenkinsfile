pipeline {
    agent any
    tools {
  terraform 'terraform'
}
environment {
  AWS_ACCESS_KEY_ID = credentials('AWS_credential')
  
}
stages {
    stage('git checkout') {
    steps {
     git branch: 'main', url: 'https://github.com/desmasud/Jenkins-terraform-Iac.git'  
   } 
}
stage ('terraform-int') {
    steps {
    sh 'terraform init'
    }
}
stage ('terraform-plan') {
    steps {
    sh 'terraform plan'
    }
}
stage ('terraform-apply') {
    steps {
    sh 'terraform apply -auto-approve'
    }
}

}
}