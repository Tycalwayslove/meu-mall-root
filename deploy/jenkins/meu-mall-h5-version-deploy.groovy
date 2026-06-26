node('mac') {
  stage('Release H5 Test Version') {
    sh '''
      set -eux
      cd /Users/mac/person_code/meu-mall
      H5_GIT_BRANCH="$H5_GIT_BRANCH" \
        bash scripts/deploy/h5-jenkins-release.sh
    '''
  }
}
