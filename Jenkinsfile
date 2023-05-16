def results_summary = ''

pipeline {
    agent {
        kubernetes {
        yaml '''
            apiVersion: v1
            kind: Pod
            metadata:
              labels:
                jenkin-job: jira-performance-tests
            spec:
              containers:
              - name: dcapt
                image: atlassian/dcapt:7.3.0
                command: ["/bin/sh", "-c", "sleep 3000"]
                tty: true
                resources:
                  requests:
                    memory: "2048Mi"
                    cpu: "1000m"
                  limits:
                    memory: "4096Mi"
                    cpu: "2000m"
                volumeMounts:
                - name: shared-data
                  mountPath: /data
              - name: yq
                image: mikefarah/yq:4.6.3
                command: ["/bin/sh", "-c", "sleep 3000"]
                tty: true
                volumeMounts:
                - name: shared-data
                  mountPath: /data
              volumes:
              - name: shared-data
                emptyDir: {}
            '''
        }
    }

    stages {
        stage('setup parameters') {
            steps {
                script { 
                    properties([
                        parameters([
                            text(
                                defaultValue: 'jiradc.qa.godemo.art',
                                name: 'APPLICATION_HOSTNAME'
                            ),
                            text(
                                defaultValue: 'https',
                                name: 'APPLICATION_PROTOCOL'
                            ),
                            text(
                                defaultValue: '443',
                                name: 'APPLICATION_PORT'
                            ),
                            text(
                                defaultValue: 'admin', 
                                name: 'ADMIN_LOGIN'
                            ),
                            text(
                                defaultValue: 'BzZs9%84cdlF2w*N', 
                                name: 'ADMIN_PASSWORD'
                            ),
                            text(
                                defaultValue: '200', 
                                name: 'CONCURRENCY'
                            ),
                            text(
                                defaultValue: '45m', 
                                name: 'TEST_DURATION', 
                            )
                        ])
                    ])
                }
            }
        }

        stage('test jira performance'){
            steps {
                script {
                    dir('app') {
                        def concurrency = params.CONCURRENCY.toInteger()
                        container('yq') {
                            sh "yq eval '(.settings.env.application_hostname = \"${params.APPLICATION_HOSTNAME}\") | (.settings.env.application_protocol = \"${params.APPLICATION_PROTOCOL}\") | (.settings.env.application_port = \"${params.APPLICATION_PORT}\") | (.settings.env.admin_login = \"${params.ADMIN_LOGIN}\") | (.settings.env.admin_password = \"${params.ADMIN_PASSWORD}\") | (.settings.env.concurrency = ${concurrency}) | (.settings.env.test_duration = \"${params.TEST_DURATION}\")' --inplace jira.yml"
                        }

                        container('dcapt') {
                            sh 'bzt jira.yml || true'
                        }

                        results_summary = sh returnStdout: true, script: 'cat results/jira/**/results_summary.log'
                    }
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'app/results/jira/**/*', onlyIfSuccessful: false

            publishHTML (target : [allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'app/results/jira',
            reportFiles: '**/*.err, **/*.csv, **/*.log',
            reportName: 'jira-performance-reports',
            reportTitles: '', 
            useWrapperFileDirectly: true])
            
            script {
                def blocks = [
                    [
                        "type": "header",
                        "text": [
                            "type": "plain_text",
                            "text": "FINISHED TEST",
                        ]
                    ],
                    [
                        "type": "divider"
                    ],
                    [
                        "type": "section",
                        "text": [
                            "type": "mrkdwn",
                            "text": ":tada: Job *${env.JOB_NAME}* has been finished.\n\nTest parameters:\n• Application hostname: ${params.APPLICATION_HOSTNAME}\n• Concurrency: ${params.CONCURRENCY} users\n• Time duration: ${params.TEST_DURATION} minutes"
                        ]
                    ],
                    [
                        "type": "section",
                        "text": [
                            "type": "mrkdwn",
                            "text": "```${results_summary}```"
                        ]
                    ],
                    [
                        "type": "divider"
                    ],
                    [
                        "type": "section",
                        "text": [
                            "type": "mrkdwn",
                            "text": "*:pushpin: More info at:*\n• *Build URL:* ${env.BUILD_URL}\n• *Full reports:* ${env.BUILD_URL}jira-performance-reports"
                        ]
                    ]
                ]
                
                slackSend channel: 'automation-test-notifications', blocks: blocks, teamDomain: 'agileops', tokenCredentialId: 'jenkins-slack', botUser: true
            }
        }
    }
}
