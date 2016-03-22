# Copyright (c) 2002-2016 "Neo Technology,"
# Network Engine for Objects in Lund AB [http://neotechnology.com]
#
# This file is part of Neo4j.
#
# Neo4j is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

declare -r PROGRAM="$(basename "$0")"

# Sets up the standard environment for running Neo4j shell scripts.
#
# Provides these environment variables:
#   NEO4J_HOME
#   NEO4J_CONF
#   NEO4J_DATA
#   NEO4J_LIB
#   NEO4J_LOGS
#   NEO4J_PIDFILE
#   NEO4J_PLUGINS
#   one per config setting, with dots converted to underscores
#
# Changes directory into NEO4J_HOME.
setup_environment() {
  _setup_calculated_paths
  cd "${NEO4J_HOME}"
  _read_config
  _setup_configurable_paths
}

_setup_calculated_paths() {
  if [[ -z "${NEO4J_HOME:-}" ]]; then
    NEO4J_HOME="$(cd "$(dirname "$0")"/.. && pwd)"
  fi
  : "${NEO4J_CONF:=conf}"
  readonly NEO4J_ROOT NEO4J_CONF
}

_read_config() {
  # - plain key-value pairs become environment variables
  # - keys have '.' chars changed to '_'
  # - keys of the form KEY.# (where # is a number) are concatenated into a single environment variable named KEY
  parse_line() {
    line="$1"
    if [[ "${line}" =~ ^([^#\s][^=]+)=(.+)$ ]]; then
      key="${BASH_REMATCH[1]//./_}"
      value="${BASH_REMATCH[2]}"
      if [[ "${key}" =~ ^(.*)_([0-9]+)$ ]]; then
        key="${BASH_REMATCH[1]}"
      fi
      if [[ "${!key:-}" ]]; then
        export ${key}="${!key} ${value}"
      else
        export ${key}="${value}"
      fi
    fi
  }

  for file in "neo4j-wrapper.conf" "neo4j.conf"; do
    path="${NEO4J_CONF}/${file}"
    if [ -e "${path}" ]; then
      while read line; do
        parse_line "${line}"
      done <"${path}"
    fi
  done
}

_setup_configurable_paths() {
  NEO4J_DATA="${dbms_directories_data:-data}"
  NEO4J_LIB="${dbms_directories_lib:-lib}"
  NEO4J_LOGS="${dbms_directories_logs:-logs}"
  NEO4J_PLUGINS="${dbms_directories_plugins:-plugins}"
  NEO4J_RUN="${dbms_directories_run:-run}"
  readonly NEO4J_DATA NEO4J_LIB NEO4J_LOGS NEO4J_PLUGINS NEO4J_RUN
}
