#!/usr/bin/env bash
#===============================================================================
#   DESCRIPTION: This script updates mattermost users with gitlab id if that is
#                present to properly use oauth login.
#        AUTHOR: Aleksandr Kukhar (kyxap), kyxap@kyxap.pro
#       CREATED: 11/12/18 9:01 +0000 UTC
#===============================================================================
set -o pipefail
set -eu

PSQL_BIN=/opt/gitlab/embedded/bin/psql
PSQL_MM_USER=mattermost
PSQL_GITLAB_USER=gitlab
PSQL_MM_ARGS="user=mattermost host=/var/opt/gitlab/postgresql port=5432 dbname=mattermost"
PSQL_GITLAB_ARGS="user=gitlab host=/var/opt/gitlab/postgresql port=5432 dbname=gitlab"
CMD_PATTERN='%s \\"%s\\" -tAF, -c \\"%s\\"'

read_users() {
  local cmd="SELECT email FROM users WHERE authdata IS NULL AND NOT authservice='gitlab'"
  printf -v m_cmd "${CMD_PATTERN}" "${PSQL_BIN}" "${PSQL_MM_ARGS}" "${cmd}"
  printf -v full_cmd 'su - %s -c "%s"' "${PSQL_MM_USER}" "${m_cmd}"
  printf "%s\n" "${full_cmd}"
}

resolve_user() {
  local email=${1:?}
  local cmd="SELECT id FROM users WHERE email='${email}' AND id IS NOT NULL"
  printf -v m_cmd "${CMD_PATTERN}" "${PSQL_BIN}" "${PSQL_GITLAB_ARGS}" "${cmd}"
  printf -v full_cmd 'su - %s -c "%s"' "${PSQL_GITLAB_USER}" "${m_cmd}"
  printf "%s\n" "${full_cmd}"
}

update_user() {
  local id="${1:?}"; shift
  local email="${1:?}"
  local cmd="UPDATE users SET authservice='gitlab',authdata=${id} WHERE email='${email}'"
  printf -v m_cmd "${CMD_PATTERN}" "${PSQL_BIN}" "${PSQL_MM_ARGS}" "${cmd}"
  printf -v full_cmd 'su - %s -c "%s"' "${PSQL_MM_USER}" "${m_cmd}"
  printf "%s\n" "${full_cmd}"
}

# read users from mattermost
read_users | bash | while read email
do
  # find users in gitlab by email
  resolve_user "${email}" | bash | while read id
  do
    [[ ${id} ]] && update_user "${id}" "${email}" || continue
  done
done
