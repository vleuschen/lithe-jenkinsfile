node {
  def target = params.TARGET ?: 'test'
  stage('Checkout') {
    checkout scm
  }
  stage('Test') {
    try {
      sh "./gradlew test --tests ${target}"
    } finally {
      junit 'build/test-results/**/*.xml'
    }
  }
}
