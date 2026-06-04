node('mac') {
  properties([
    parameters([
      string(name: 'REMOTE_HOST', defaultValue: '8.163.107.208', description: '测试服务器 IP'),
      string(name: 'REMOTE_USER', defaultValue: 'root', description: 'SSH 用户'),
      string(name: 'REMOTE_PORT', defaultValue: '22', description: 'SSH 端口'),
      string(name: 'REMOTE_PATH', defaultValue: '/opt/mail4j/meu-mall', description: '远端部署目录'),
      string(name: 'DOMAIN', defaultValue: 'hybird.aigcpop.com', description: 'H5 测试域名'),
      password(name: 'SERVER_PASSWORD', description: '测试服务器 SSH 密码'),
      booleanParam(name: 'INSTALL_NGINX', defaultValue: true, description: '是否安装并 reload Nginx 站点配置'),
      booleanParam(name: 'RUN_REMOTE_SMOKE', defaultValue: true, description: '是否执行远端 smoke check')
    ])
  ])

  stage('Deploy Meu Mall Test Server') {
    sh '''
      set -eux
      cd /Users/mac/person_code/meu-mall
      REMOTE_HOST="$REMOTE_HOST" \
      REMOTE_USER="$REMOTE_USER" \
      REMOTE_PORT="$REMOTE_PORT" \
      REMOTE_PATH="$REMOTE_PATH" \
      DOMAIN="$DOMAIN" \
      INSTALL_NGINX="$INSTALL_NGINX" \
      RUN_REMOTE_SMOKE="$RUN_REMOTE_SMOKE" \
      SERVER_PASSWORD="$SERVER_PASSWORD" \
        bash scripts/deploy/test-server-deploy.sh
    '''
  }
}
