node('mac') {
  properties([
    parameters([
      string(name: 'GIT_REF', defaultValue: '', description: 'H5 Git ref；留空则使用 h5/v{hybird-meumall/package.json version}'),
      string(name: 'REMOTE_HOST', defaultValue: '8.163.107.208', description: '测试服务器 IP'),
      string(name: 'REMOTE_USER', defaultValue: 'root', description: 'SSH 用户'),
      string(name: 'REMOTE_PORT', defaultValue: '22', description: 'SSH 端口'),
      string(name: 'REMOTE_PATH', defaultValue: '/opt/mail4j/meu-mall', description: '远端部署目录'),
      string(name: 'DOMAIN', defaultValue: 'hybird.aigcpop.com', description: 'H5 测试域名'),
      string(name: 'H5_HOST_PORT', defaultValue: '', description: '宿主机端口；留空则自动选择 3200-3299'),
      string(name: 'NEXT_PUBLIC_H5_ASSET_BASE_URL', defaultValue: '', description: 'CDN 资源根地址；当前可留空'),
      password(name: 'SERVER_PASSWORD', description: '测试服务器 SSH 密码'),
      booleanParam(name: 'REGISTER_RELEASE', defaultValue: true, description: '是否注册 candidate release'),
      booleanParam(name: 'PROMOTE_RELEASE', defaultValue: false, description: '是否注册后立即提升为 active'),
      booleanParam(name: 'INSTALL_NGINX', defaultValue: true, description: '是否写入版本 nginx location 并 reload'),
      booleanParam(name: 'RUN_REMOTE_SMOKE', defaultValue: true, description: '是否执行版本 URL smoke check'),
      booleanParam(name: 'SEND_FEISHU_REVIEW', defaultValue: true, description: '发版完成后是否发送飞书待审核通报到审核群'),
      booleanParam(name: 'FEISHU_REVIEW_DRY_RUN', defaultValue: false, description: '飞书待审核通报是否只 dry-run 不真实发送')
    ])
  ])

  stage('Deploy H5 Version Container') {
    sh '''
      set -eux
      cd /Users/mac/person_code/meu-mall
      REMOTE_HOST="$REMOTE_HOST" \
      REMOTE_USER="$REMOTE_USER" \
      REMOTE_PORT="$REMOTE_PORT" \
      REMOTE_PATH="$REMOTE_PATH" \
      DOMAIN="$DOMAIN" \
      GIT_REF="$GIT_REF" \
      H5_HOST_PORT="${H5_HOST_PORT:-}" \
      NEXT_PUBLIC_H5_ASSET_BASE_URL="${NEXT_PUBLIC_H5_ASSET_BASE_URL:-}" \
      REGISTER_RELEASE="$REGISTER_RELEASE" \
      PROMOTE_RELEASE="$PROMOTE_RELEASE" \
      INSTALL_NGINX="$INSTALL_NGINX" \
      RUN_REMOTE_SMOKE="$RUN_REMOTE_SMOKE" \
      SEND_FEISHU_REVIEW="$SEND_FEISHU_REVIEW" \
      FEISHU_REVIEW_DRY_RUN="$FEISHU_REVIEW_DRY_RUN" \
      SERVER_PASSWORD="$SERVER_PASSWORD" \
        bash scripts/deploy/h5-version-deploy.sh
    '''
  }
}
