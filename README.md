## oauth-mattermost-gitlab

Mattermost doesn't support google SSO in CE version so we have to use GitLab SSO instead. Slack users were imported to mattermost with slack emails, but most of them are not existing in GitLab. This script updates mattermost users with gitlab id if that is present to properly use oauth login.
