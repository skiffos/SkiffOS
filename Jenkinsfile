node {
  stage ("scm") {
    checkout scm
    sh 'git submodule update --init --recursive'
  }

  wrap([$class: 'AnsiColorBuildWrapper', 'colorMapName': 'XTerm']) {
    stage ("cache-download") {
      sh '''
        #!/bin/bash
        source ./scripts/jenkins_env.bash
        CACHE_CONTEXT=skiff-ccache CACHE_PATH=~/.buildroot-ccache/ ./scripts/init_cache.bash
        CACHE_CONTEXT=skiff-dl CACHE_PATH=./workspaces/default/dl/ ./scripts/init_cache.bash
      '''
    }

    stage ("build") {
      sh '''
        #!/bin/bash
        source ./scripts/jenkins_env.bash
        SKIFF_CONFIG="docker/standard" make compile
      '''
    }

    stage ("cache-upload") {
      sh '''
        #!/bin/bash
        source ./scripts/jenkins_env.bash
        CACHE_CONTEXT=skiff-ccache CACHE_PATH=~/.buildroot-ccache/ ./scripts/finalize_cache.bash
        CACHE_CONTEXT=skiff-dl CACHE_PATH=./workspaces/default/dl/ ./scripts/finalize_cache.bash
      '''
    }
  }
}
