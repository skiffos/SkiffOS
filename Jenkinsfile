node {
  stage ("scm") {
    checkout scm
  }

  env.CACHE_CONTEXT='skiff'
  wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
    stage ("cache-download") {
      sh '''
        #!/bin/bash
        source ./scripts/jenkins_env.bash
        ./scripts/init_cache.bash
      '''
    }

    stage ("build") {
      sh '''
        #!/bin/bash
        SKIFF_CONFIG="docker/standard" make compile
      '''
    }

    stage ("cache-upload") {
      sh '''
        #!/bin/bash
        source ./scripts/jenkins_env.bash
        ./scripts/finalize_cache.bash
      '''
    }
  }
}
