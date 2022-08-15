pipeline {
  agent any
    stages {
      stage('Building Requeriments') {
        steps {
          sh '''#!/bin/bash
          echo "st> =================="
          echo "st> Installing Kubesec"
          echo "st> =================="
          echo "st> "
          if [ ! -e ./bin/kubesec ] ; then
	          mkdir ./tmp ./bin ./kubesec-report
            wget https://github.com/controlplaneio/kubesec/releases/download/v2.9.0/kubesec_linux_amd64.tar.gz -O ./tmp/kubesec_linux_amd64.tar.gz
            tar -zxf ./tmp/kubesec_linux_amd64.tar.gz 
            mv kubesec ./bin
	          rm -rf ./tmp
            echo "st> Kubesec Installed!"
          else
            echo "st> Kubesec already installed"
          fi
          echo "st> ================="
          '''
        }
      }
      stage('YAML Security Check') {
        steps {
          sh '''#!/bin/bash
          echo "st> ==================="
          echo "st> Checking YAML files"
          echo "st> ==================="
          echo "st> "
          cd ${WORKSPACE}/sock-shop-demo-app/deployments
          for deployment in *.yaml; do
              ${WORKSPACE}/bin/kubesec scan "$deployment" > ${WORKSPACE}/kubesec-report/"$deployment".txt
              if [ "`cat ${WORKSPACE}/kubesec-report/"$deployment".txt |grep 'Failed with a score' 2>/dev/null`" ] ; then
                echo "st> ABORTING! $deployment Not met the security requirements"
                exit 1
              else 
                echo "st> $deployment pass the security check!"
              fi
          done
          echo "st> ================="
          '''
        }
      }
      stage('Application Deployment') {
        steps {
          sh '''#!/bin/bash
          echo "st> ======================"
          echo "st> Application Deployment"
          echo "st> ======================"
          echo "st> "
          cd ${WORKSPACE}/sock-shop-demo-app
          aws eks --region us-east-1 update-kubeconfig --name KubeSec-Demo
	        /usr/local/bin/kubectl apply -f .
          /usr/local/bin/kubectl apply -f deployments/.
          echo "st> ================="
          '''
        }
      }
    }
  }
