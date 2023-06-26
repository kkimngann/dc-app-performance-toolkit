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
              imagePullSecrets:
                - name: ecr-puller
              containers:
              - name: dcapt
                image: 899159155532.dkr.ecr.ap-southeast-1.amazonaws.com/atlassian-dcapt:latest
                command: ["/bin/sh", "-c", "sleep infinity"]
                tty: true
                resources:
                  requests:
                    memory: "8192Mi"
                    cpu: "2000m"
                volumeMounts:
                - name: shared-data
                  mountPath: /data
              - name: yq
                image: mikefarah/yq:4.6.3
                command: ["/bin/sh", "-c", "sleep infinity"]
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
                    // Set default values for parameters
                    properties([
                        parameters([
                            text(
                                defaultValue: 'jira-9.aandd.io',
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
                                defaultValue: '/jira',
                                name: 'APPLICATION_POSTFIX'
                            ),
                            text(
                                defaultValue: 'admin', 
                                name: 'ADMIN_LOGIN'
                            ),
                            text(
                                defaultValue: '12345678', 
                                name: 'ADMIN_PASSWORD'
                            ),
                            text(
                                defaultValue: '200',
                                name: 'CONCURRENCY'
                            ),
                            text(
                                defaultValue: '45m', 
                                name: 'TEST_DURATION',
                            ),
                            text(
                                defaultValue: '3m',
                                name: 'RAMP_UP'
                            ),
                            text(
                                defaultValue: '54500',
                                name: 'TOTAL_ACTIONS_PER_HOUR'
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
                        // convert concurrency to integer
                        def concurrency = params.CONCURRENCY.toInteger()
                        container('yq') {
                            // Update test parameters with values from input
                            sh """
                            yq eval '(.settings.env.application_hostname = \"${params.APPLICATION_HOSTNAME}\") | 
                                (.settings.env.application_protocol = \"${params.APPLICATION_PROTOCOL}\") | 
                                (.settings.env.application_port = \"${params.APPLICATION_PORT}\") | 
                                (.settings.env.application_postfix = \"${params.APPLICATION_POSTFIX}\") |
                                (.settings.env.admin_login = \"${params.ADMIN_LOGIN}\") | 
                                (.settings.env.admin_password = \"${params.ADMIN_PASSWORD}\") | 
                                (.settings.env.concurrency = ${concurrency}) | 
                                (.settings.env.test_duration = \"${params.TEST_DURATION}\") | 
                                (.settings.env.ramp-up = \"${params.RAMP_UP}\") | 
                                (.settings.env.total_actions_per_hour = \"${params.TOTAL_ACTIONS_PER_HOUR}\")' 
                                --inplace jira.yml
                            """
                        }
                        

                        container('dcapt') {
                            sh 'bzt -o modules.console.disable=true jira.yml || true'
                        }

                        // Get results summary
                        results_summary = sh returnStdout: true, script: "sed -n -e '/Summary run status/,/Has app-specific actions/ p' results/jira/**/results_summary.log | sed 's/ \\{2,\\}/\\t/g' | awk -F'\\t' 'BEGIN{OFS=\"\\t\"} {printf \"%-41s %-30s\\n\", \$1, \$2}'"
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
            reportFiles: '**/results_summary.log',
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
                            "text": ":tada: Job *${env.JOB_NAME}* has been finished.\n\nTest parameters:\n• Application hostname: ${params.APPLICATION_HOSTNAME}\n• Concurrency: ${params.CONCURRENCY} users\n• Time duration: ${params.TEST_DURATION}"
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

                slackSend channel: 'automation-test-notifications', color: "#14910c", blocks: blocks, teamDomain: 'agileops', tokenCredentialId: 'jenkins-slack', botUser: true
            }
        }
    }
}
