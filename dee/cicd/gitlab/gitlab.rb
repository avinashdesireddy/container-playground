external_url 'http://gitlab.apps.avinash.dockerps.io/'
gitlab_rails['initial_root_password'] = File.read('/run/secrets/gitlab_root_password')
